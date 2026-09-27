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

enum TimerChoice: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 900
    case twentyMinutes = 1_200
    case thirtyMinutes = 1_800
    case sixtyMinutes = 3_600
    case ninetyMinutes = 5_400
    case unlimited = 0

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fifteenMinutes: "15分"
        case .twentyMinutes: "20分"
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
        guard let value else { return .unlimited }
        // 旧Business専用タイマーは、最新Web版と同じ「無制限」へ移行する。
        if value == 1_790 { return .unlimited }
        if let currentValue = TimerChoice(rawValue: value) {
            return currentValue
        }

        // Phase 1の初期版は分単位で保存していたため、旧値も引き継ぐ。
        switch value {
        case 15: return .fifteenMinutes
        case 30: return .thirtyMinutes
        case 60: return .sixtyMinutes
        default: return .unlimited
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

struct PulseLayerDefinition: Codable, Equatable {
    let name: String
    let rateTimeline: [TimelinePoint]
    let gainTimeline: [TimelinePoint]

    private enum CodingKeys: String, CodingKey {
        case name
        case rateTimeline
        case gainTimeline
    }

    init(name: String, rateTimeline: [TimelinePoint], gainTimeline: [TimelinePoint]) {
        self.name = name
        self.rateTimeline = rateTimeline
        self.gainTimeline = gainTimeline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Layer"
        rateTimeline = try container.decodeIfPresent([TimelinePoint].self, forKey: .rateTimeline) ?? []
        gainTimeline = try container.decodeIfPresent([TimelinePoint].self, forKey: .gainTimeline) ?? []
    }
}

struct AudioPresetDefinition: Codable, Identifiable, Equatable {
    let id: String
    let analysisVersion: Int
    let sourceAnalysisVersion: String?
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
    let pulseLayers: [PulseLayerDefinition]

    private enum CodingKeys: String, CodingKey {
        case id
        case analysisVersion
        case sourceAnalysisVersion
        case name
        case description
        case leftFrequency
        case rightFrequency
        case differenceFrequency
        case defaultNoise
        case defaultToneVolume
        case defaultNoiseVolume
        case durationSeconds
        case loop
        case pulseTimeline
        case pitchTimeline
        case pulseLayers
    }

    init(
        id: String,
        analysisVersion: Int,
        sourceAnalysisVersion: String? = nil,
        name: String,
        description: String,
        leftFrequency: Double?,
        rightFrequency: Double?,
        differenceFrequency: Double?,
        defaultNoise: NoiseType,
        defaultToneVolume: Double,
        defaultNoiseVolume: Double,
        durationSeconds: Double?,
        loop: Bool,
        pulseTimeline: [TimelinePoint],
        pitchTimeline: [TimelinePoint],
        pulseLayers: [PulseLayerDefinition] = []
    ) {
        self.id = id
        self.analysisVersion = analysisVersion
        self.sourceAnalysisVersion = sourceAnalysisVersion
        self.name = name
        self.description = description
        self.leftFrequency = leftFrequency
        self.rightFrequency = rightFrequency
        self.differenceFrequency = differenceFrequency
        self.defaultNoise = defaultNoise
        self.defaultToneVolume = defaultToneVolume
        self.defaultNoiseVolume = defaultNoiseVolume
        self.durationSeconds = durationSeconds
        self.loop = loop
        self.pulseTimeline = pulseTimeline
        self.pitchTimeline = pitchTimeline
        self.pulseLayers = pulseLayers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        analysisVersion = try container.decodeIfPresent(Int.self, forKey: .analysisVersion) ?? 1
        sourceAnalysisVersion = try container.decodeIfPresent(String.self, forKey: .sourceAnalysisVersion)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        leftFrequency = try container.decodeIfPresent(Double.self, forKey: .leftFrequency)
        rightFrequency = try container.decodeIfPresent(Double.self, forKey: .rightFrequency)
        differenceFrequency = try container.decodeIfPresent(Double.self, forKey: .differenceFrequency)
        defaultNoise = try container.decodeIfPresent(NoiseType.self, forKey: .defaultNoise) ?? .pink
        defaultToneVolume = try container.decodeIfPresent(Double.self, forKey: .defaultToneVolume) ?? 50
        defaultNoiseVolume = try container.decodeIfPresent(Double.self, forKey: .defaultNoiseVolume) ?? 0
        durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds)
        loop = try container.decodeIfPresent(Bool.self, forKey: .loop) ?? true
        pulseTimeline = try container.decodeIfPresent([TimelinePoint].self, forKey: .pulseTimeline) ?? []
        pitchTimeline = try container.decodeIfPresent([TimelinePoint].self, forKey: .pitchTimeline) ?? []
        pulseLayers = try container.decodeIfPresent([PulseLayerDefinition].self, forKey: .pulseLayers) ?? []
    }

    var hasTone: Bool {
        leftFrequency != nil && rightFrequency != nil
    }

    var hasDynamicPulse: Bool {
        !pulseLayers.isEmpty || !pulseTimeline.isEmpty
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
        sourceAnalysisVersion: nil,
        name: "Focus",
        description: "作業・読書・デザイン作業向け",
        leftFrequency: 200,
        rightFrequency: 214,
        differenceFrequency: 14,
        defaultNoise: .pink,
        defaultToneVolume: 50,
        defaultNoiseVolume: 0,
        durationSeconds: nil,
        loop: true,
        pulseTimeline: [],
        pitchTimeline: [],
        pulseLayers: []
    )

    static let fallbackNoiseOnly = AudioPresetDefinition(
        id: "noiseOnly",
        analysisVersion: 1,
        sourceAnalysisVersion: nil,
        name: "Noise Only",
        description: "周波数なしでノイズだけ流すモード",
        leftFrequency: nil,
        rightFrequency: nil,
        differenceFrequency: nil,
        defaultNoise: .pink,
        defaultToneVolume: 0,
        defaultNoiseVolume: 0,
        durationSeconds: nil,
        loop: true,
        pulseTimeline: [],
        pitchTimeline: [],
        pulseLayers: []
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
