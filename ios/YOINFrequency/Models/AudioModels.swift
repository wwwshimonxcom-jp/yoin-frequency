import Foundation

enum NoiseType: String, Codable, CaseIterable, Identifiable {
    case white
    case pink
    case brown
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .white: "White"
        case .pink: "Pink"
        case .brown: "Brown"
        case .mixed: "Mix"
        }
    }
}

enum ListeningMode: String, CaseIterable, Identifiable {
    case headphones
    case speaker

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .headphones: "Binaural"
        case .speaker: "Monaural"
        }
    }

    var localizedName: String {
        switch self {
        case .headphones: "バイノーラル"
        case .speaker: "モノラル"
        }
    }

    var summary: String {
        switch self {
        case .headphones: "左右で異なる音・ヘッドホン推奨"
        case .speaker: "左右で同じ音・パルス"
        }
    }

    var channelLabel: String {
        switch self {
        case .headphones: "L ≠ R"
        case .speaker: "L = R"
        }
    }
}

enum TimerChoice: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 900
    case twentyMinutes = 1_200
    case businessDuration = 1_790
    case thirtyMinutes = 1_800
    case sixtyMinutes = 3_600
    case ninetyMinutes = 5_400
    case unlimited = 0

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fifteenMinutes: "15分"
        case .twentyMinutes: "20分"
        case .businessDuration: "29:50"
        case .thirtyMinutes: "30分"
        case .sixtyMinutes: "60分"
        case .ninetyMinutes: "90分"
        case .unlimited: "無制限"
        }
    }

    var duration: TimeInterval? {
        self == .unlimited ? nil : TimeInterval(rawValue)
    }

    static func fromStoredValue(_ value: Int?) -> TimerChoice {
        guard let value else { return .thirtyMinutes }
        if let currentValue = TimerChoice(rawValue: value) {
            return currentValue
        }

        // Phase 1の初期版は分単位で保存していたため、旧値も引き継ぐ。
        switch value {
        case 15: return .fifteenMinutes
        case 30: return .thirtyMinutes
        case 60: return .sixtyMinutes
        default: return .thirtyMinutes
        }
    }

    static func matching(durationSeconds: Double?) -> TimerChoice? {
        guard let durationSeconds, durationSeconds.isFinite else { return nil }
        return TimerChoice(rawValue: Int(durationSeconds.rounded()))
    }
}

struct TimelinePoint: Codable, Equatable {
    let time: Double
    let value: Double
}

struct AudioPresetDefinition: Codable, Identifiable, Equatable {
    let id: String
    let analysisVersion: Int
    let name: String
    let description: String
    let leftFrequency: Double?
    let rightFrequency: Double?
    let differenceFrequency: Double?
    let defaultNoise: NoiseType
    let defaultToneVolume: Double
    let defaultNoiseVolume: Double
    let durationSeconds: Double?
    let loop: Bool
    let pulseTimeline: [TimelinePoint]
    let pitchTimeline: [TimelinePoint]

    var hasTone: Bool {
        leftFrequency != nil && rightFrequency != nil
    }

    var hasDynamicPulse: Bool {
        !pulseTimeline.isEmpty
    }

    var hasDynamicPitch: Bool {
        !pitchTimeline.isEmpty
    }

    var recommendedTimerChoice: TimerChoice? {
        TimerChoice.matching(durationSeconds: durationSeconds)
    }

    static let fallbackFocus = AudioPresetDefinition(
        id: "focus",
        analysisVersion: 1,
        name: "Focus",
        description: "作業・読書・デザイン作業向け",
        leftFrequency: 200,
        rightFrequency: 214,
        differenceFrequency: 14,
        defaultNoise: .pink,
        defaultToneVolume: 24,
        defaultNoiseVolume: 18,
        durationSeconds: nil,
        loop: true,
        pulseTimeline: [],
        pitchTimeline: []
    )

    static let fallbackNoiseOnly = AudioPresetDefinition(
        id: "noiseOnly",
        analysisVersion: 1,
        name: "Noise Only",
        description: "周波数なしでノイズだけ流すモード",
        leftFrequency: nil,
        rightFrequency: nil,
        differenceFrequency: nil,
        defaultNoise: .pink,
        defaultToneVolume: 0,
        defaultNoiseVolume: 34,
        durationSeconds: nil,
        loop: true,
        pulseTimeline: [],
        pitchTimeline: []
    )
}

enum PresetLibrary {
    static func load() -> [AudioPresetDefinition] {
        guard
            let url = Bundle.main.url(forResource: "presets", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let presets = try? JSONDecoder().decode([AudioPresetDefinition].self, from: data),
            !presets.isEmpty
        else {
            return [.fallbackFocus, .fallbackNoiseOnly]
        }

        return presets
    }
}
