import AVFAudio
import Combine
import Foundation
import UIKit

@MainActor
final class PlayerStore: ObservableObject {
    @Published private(set) var presets: [AudioPresetDefinition]
    @Published private(set) var selectedPreset: AudioPresetDefinition
    @Published private(set) var noiseType: NoiseType
    @Published private(set) var masterVolume: Double
    @Published private(set) var toneVolume: Double
    @Published private(set) var noiseVolume: Double
    @Published private(set) var timerChoice: TimerChoice
    @Published private(set) var remainingSeconds: TimeInterval?
    @Published private(set) var programElapsedSeconds: TimeInterval = 0
    @Published private(set) var programCycleIndex = 1
    @Published private(set) var isPlaying = false
    @Published private(set) var isStopping = false
    @Published var errorMessage: String?

    private enum DefaultsKey {
        static let presetID = "ios.presetID"
        static let noiseType = "ios.noiseType"
        static let masterVolume = "ios.masterVolume"
        static let toneVolume = "ios.toneVolume"
        static let noiseVolume = "ios.noiseVolume"
        static let timerMinutes = "ios.timerMinutes"
        static let defaultsVersion = "ios.defaultsVersion"
    }

    private static let currentDefaultsVersion = 2

    private let audioEngine = FrequencyAudioEngine()
    private let defaults: UserDefaults
    private var countdownTask: Task<Void, Never>?
    private var programProgressTask: Task<Void, Never>?
    private var configurationRestartTask: Task<Void, Never>?
    private var lastConfigurationRestartAt: Date?
    private var lastConfigurationRouteSignature: String?
    private var timerDeadline: Date?
    private var programStartedAt: Date?
    private var programAnchorElapsedSeconds: TimeInterval = 0
    private var cancellables = Set<AnyCancellable>()
    private var shouldResumeAfterInterruption = false
    private var wantsPlayback = false
    private var isInterrupted = false
    private var operationGeneration = 0
#if targetEnvironment(macCatalyst)
    private var playbackActivity: NSObjectProtocol?
#endif

    var isPlaybackRequested: Bool {
        wantsPlayback
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let loadedPresets = PresetLibrary.load()
        presets = loadedPresets

        let savedPresetID = Self.migratedPresetID(
            defaults.string(forKey: DefaultsKey.presetID)
        )
        let initialPreset = loadedPresets.first(where: { $0.id == savedPresetID })
            ?? loadedPresets.first(where: { $0.id == "focus" })
            ?? loadedPresets.first
            ?? .fallbackFocus
        selectedPreset = initialPreset

        let shouldApplyUpdatedDefaults = defaults.integer(forKey: DefaultsKey.defaultsVersion)
            < Self.currentDefaultsVersion

        noiseType = shouldApplyUpdatedDefaults
            ? initialPreset.defaultNoise
            : defaults.string(forKey: DefaultsKey.noiseType)
                .flatMap(NoiseType.init(rawValue:))
                ?? initialPreset.defaultNoise
        masterVolume = Self.savedVolume(
            defaults: defaults,
            key: DefaultsKey.masterVolume,
            fallback: 70
        )
        toneVolume = Self.savedVolume(
            defaults: defaults,
            key: DefaultsKey.toneVolume,
            fallback: initialPreset.defaultToneVolume,
            forceFallback: shouldApplyUpdatedDefaults
        )
        noiseVolume = Self.savedVolume(
            defaults: defaults,
            key: DefaultsKey.noiseVolume,
            fallback: initialPreset.defaultNoiseVolume,
            forceFallback: shouldApplyUpdatedDefaults
        )
        timerChoice = shouldApplyUpdatedDefaults
            ? .unlimited
            : TimerChoice.fromStoredValue(
                defaults.object(forKey: DefaultsKey.timerMinutes) as? Int
            )
        remainingSeconds = timerChoice.duration

        defaults.set(Self.currentDefaultsVersion, forKey: DefaultsKey.defaultsVersion)
        defaults.set(selectedPreset.id, forKey: DefaultsKey.presetID)
        defaults.set(noiseType.rawValue, forKey: DefaultsKey.noiseType)
        defaults.set(masterVolume, forKey: DefaultsKey.masterVolume)
        defaults.set(toneVolume, forKey: DefaultsKey.toneVolume)
        defaults.set(noiseVolume, forKey: DefaultsKey.noiseVolume)
        defaults.set(timerChoice.rawValue, forKey: DefaultsKey.timerMinutes)

        observeAudioSession()
    }

    var frequencySummary: [(label: String, value: String)] {
        guard selectedPreset.hasTone else {
            return [
                ("Tone", "--"),
                ("Pulse", "--")
            ]
        }

        if selectedPreset.hasDynamicPulse {
            let pulseTimeline = selectedPreset.pulseLayers.isEmpty
                ? selectedPreset.pulseTimeline
                : selectedPreset.pulseLayers.flatMap(\.rateTimeline)
            let pulseLabel = selectedPreset.pulseLayers.isEmpty
                ? "Pulse"
                : "Pulse x\(selectedPreset.pulseLayers.count)"

            return [
                (
                    selectedPreset.hasDynamicPitch ? "Pitch" : "Tone",
                    selectedPreset.hasDynamicPitch
                        ? Self.formatRange(selectedPreset.pitchTimeline)
                        : Self.formatHz(selectedPreset.leftFrequency)
                ),
                (pulseLabel, Self.formatRange(pulseTimeline))
            ]
        }

        return [
            ("Tone", Self.formatHz(selectedPreset.leftFrequency)),
            ("Pulse", Self.formatHz(selectedPreset.differenceFrequency))
        ]
    }

    var programDurationSeconds: TimeInterval? {
        guard
            let duration = selectedPreset.durationSeconds,
            duration.isFinite,
            duration > 0
        else {
            return nil
        }

        return duration
    }

    func play() {
        guard !isPlaying, !isStopping else { return }
        guard !isInterrupted else {
            errorMessage = "通話や音声入力が終わってから再生してください。"
            return
        }
        operationGeneration += 1
        let expectedGeneration = operationGeneration
        errorMessage = nil
        programStartedAt = Date()
        configurationRestartTask?.cancel()
        configurationRestartTask = nil

        do {
            try audioEngine.start(configuration: configuration)
            guard operationGeneration == expectedGeneration else { return }
            markAudioGraphStarted()
            wantsPlayback = true
            isPlaying = true
            shouldResumeAfterInterruption = false
            beginPlaybackActivityIfNeeded()
            startNewTimer()
            startProgramProgressUpdates()
        } catch {
            audioEngine.stopImmediately()
            wantsPlayback = false
            isPlaying = false
            isStopping = false
            programStartedAt = nil
            resetProgramProgress()
            endPlaybackActivity()
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        guard wantsPlayback || isPlaying || isStopping else { return }
        operationGeneration += 1
        let expectedGeneration = operationGeneration
        configurationRestartTask?.cancel()
        configurationRestartTask = nil
        wantsPlayback = false
        isPlaying = false
        isStopping = true
        shouldResumeAfterInterruption = false
        endPlaybackActivity()
        clearTimer(resetDisplay: true)
        resetProgramProgress()

        Task { [weak self] in
            guard let self else { return }
            await self.audioEngine.stop(fadeDuration: 1.2)
            guard self.operationGeneration == expectedGeneration else { return }
            self.isStopping = false
        }
    }

    func selectPreset(_ preset: AudioPresetDefinition) {
        guard preset.id != selectedPreset.id, !isStopping else { return }
        selectedPreset = preset
        noiseType = preset.defaultNoise
        toneVolume = preset.defaultToneVolume
        noiseVolume = preset.defaultNoiseVolume

        resetProgramProgress()

        markProgramForFreshStartIfInterrupted()
        persistSettings()
        restartIfNeeded(preserveDeadline: false)
    }

    func selectNoiseType(_ type: NoiseType) {
        guard type != noiseType, !isStopping else { return }
        let savedProgramElapsed = currentProgramElapsed
        noiseType = type
        defaults.set(type.rawValue, forKey: DefaultsKey.noiseType)
        markProgramForFreshStartIfInterrupted()
        restartIfNeeded(
            preserveDeadline: false,
            programOffset: savedProgramElapsed
        )
    }

    func setMasterVolume(_ value: Double) {
        masterVolume = Self.clampVolume(value)
        defaults.set(masterVolume, forKey: DefaultsKey.masterVolume)
        applyLiveVolumes()
    }

    func setToneVolume(_ value: Double) {
        toneVolume = selectedPreset.hasTone ? Self.clampVolume(value) : 0
        defaults.set(toneVolume, forKey: DefaultsKey.toneVolume)
        applyLiveVolumes()
    }

    func setNoiseVolume(_ value: Double) {
        noiseVolume = Self.clampVolume(value)
        defaults.set(noiseVolume, forKey: DefaultsKey.noiseVolume)
        applyLiveVolumes()
    }

    func selectTimer(_ choice: TimerChoice) {
        guard choice != timerChoice, !isStopping else { return }
        timerChoice = choice
        defaults.set(choice.rawValue, forKey: DefaultsKey.timerMinutes)

        if isPlaying {
            startNewTimer()
        } else if wantsPlayback {
            if let duration = choice.duration {
                timerDeadline = Date().addingTimeInterval(duration)
                remainingSeconds = duration
            } else {
                timerDeadline = nil
                remainingSeconds = nil
            }
        } else {
            remainingSeconds = choice.duration
        }
    }

    func seekProgram(to seconds: TimeInterval) {
        guard let duration = programDurationSeconds, !isStopping else { return }

        let target = min(duration, max(0, seconds.isFinite ? seconds : 0))
        programAnchorElapsedSeconds = target
        programStartedAt = isPlaying ? Date() : nil
        publishProgramProgress(elapsed: target)

        guard isPlaying else { return }
        restartIfNeeded(preserveDeadline: true, programOffset: target)
    }

    private var configuration: AudioEngineConfiguration {
        AudioEngineConfiguration(
            preset: selectedPreset,
            noiseType: noiseType,
            masterVolume: masterVolume,
            toneVolume: toneVolume,
            noiseVolume: noiseVolume,
            startOffsetSeconds: currentProgramOffset
        )
    }

    private var currentProgramOffset: TimeInterval {
        normalizedProgramOffset(currentProgramElapsed)
    }

    private var currentProgramElapsed: TimeInterval {
        let runningElapsed = programStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        return max(0, programAnchorElapsedSeconds + runningElapsed)
    }

    private func restartIfNeeded(
        preserveDeadline: Bool,
        programOffset explicitProgramOffset: TimeInterval? = nil
    ) {
        guard isPlaying else { return }
        configurationRestartTask?.cancel()
        configurationRestartTask = nil
        operationGeneration += 1
        let expectedGeneration = operationGeneration
        let savedDeadline = preserveDeadline ? timerDeadline : nil
        let savedProgramElapsed = explicitProgramOffset
            ?? (preserveDeadline ? currentProgramElapsed : 0)
        programProgressTask?.cancel()
        programProgressTask = nil
        programAnchorElapsedSeconds = savedProgramElapsed
        programStartedAt = nil
        publishProgramProgress(elapsed: savedProgramElapsed)
        if !preserveDeadline {
            timerDeadline = nil
            remainingSeconds = timerChoice.duration
        }
        countdownTask?.cancel()
        countdownTask = nil
        isPlaying = false
        isStopping = true

        Task { [weak self] in
            guard let self else { return }
            await self.audioEngine.stop(fadeDuration: 0.45)
            guard self.operationGeneration == expectedGeneration else { return }

            do {
                self.programAnchorElapsedSeconds = savedProgramElapsed
                self.programStartedAt = Date()
                try self.audioEngine.start(configuration: self.configuration)
                guard self.operationGeneration == expectedGeneration else { return }
                self.markAudioGraphStarted()
                self.wantsPlayback = true
                self.isPlaying = true
                self.isStopping = false
                self.beginPlaybackActivityIfNeeded()
                if preserveDeadline {
                    self.timerDeadline = savedDeadline
                    self.resumeTimerFromCurrentDeadline()
                } else {
                    self.startNewTimer()
                }
                self.startProgramProgressUpdates()
            } catch {
                self.audioEngine.stopImmediately()
                self.wantsPlayback = false
                self.isPlaying = false
                self.isStopping = false
                self.resetProgramProgress()
                self.clearTimer(resetDisplay: true)
                self.endPlaybackActivity()
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func markProgramForFreshStartIfInterrupted() {
        guard wantsPlayback, !isPlaying else { return }
        resetProgramProgress()
        timerDeadline = nil
        remainingSeconds = timerChoice.duration
    }

    private func startProgramProgressUpdates() {
        programProgressTask?.cancel()
        programProgressTask = nil
        publishProgramProgress(elapsed: currentProgramElapsed)

        guard programDurationSeconds != nil else { return }

        let clock = ContinuousClock()
        programProgressTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                self.publishProgramProgress(elapsed: self.currentProgramElapsed)
                try? await clock.sleep(for: .milliseconds(250))
            }
        }
    }

    private func resetProgramProgress() {
        programProgressTask?.cancel()
        programProgressTask = nil
        programStartedAt = nil
        programAnchorElapsedSeconds = 0
        programElapsedSeconds = 0
        programCycleIndex = 1
    }

    private func publishProgramProgress(elapsed: TimeInterval) {
        guard let duration = programDurationSeconds else {
            programElapsedSeconds = 0
            programCycleIndex = 1
            return
        }

        let safeElapsed = max(0, elapsed)
        if selectedPreset.loop {
            programCycleIndex = Int(safeElapsed / duration) + 1
            programElapsedSeconds = safeElapsed.truncatingRemainder(dividingBy: duration)
        } else {
            programCycleIndex = 1
            programElapsedSeconds = min(duration, safeElapsed)
        }
    }

    private func normalizedProgramOffset(_ elapsed: TimeInterval) -> TimeInterval {
        guard let duration = programDurationSeconds else { return max(0, elapsed) }
        let safeElapsed = max(0, elapsed)
        return selectedPreset.loop
            ? safeElapsed.truncatingRemainder(dividingBy: duration)
            : min(duration, safeElapsed)
    }

    private func applyLiveVolumes() {
        audioEngine.updateVolumes(
            master: masterVolume,
            tone: toneVolume,
            noise: noiseVolume
        )
    }

    private func startNewTimer() {
        countdownTask?.cancel()
        countdownTask = nil

        guard let duration = timerChoice.duration else {
            timerDeadline = nil
            remainingSeconds = nil
            return
        }

        timerDeadline = Date().addingTimeInterval(duration)
        remainingSeconds = duration
        resumeTimerFromCurrentDeadline()
    }

    private func resumeTimerFromCurrentDeadline() {
        countdownTask?.cancel()
        countdownTask = nil

        guard let deadline = timerDeadline else {
            remainingSeconds = nil
            return
        }

        let clock = ContinuousClock()
        countdownTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                let remaining = deadline.timeIntervalSinceNow

                if remaining <= 0 {
                    self.remainingSeconds = 0
                    await self.timerExpired()
                    return
                }

                self.remainingSeconds = remaining
                try? await clock.sleep(for: .seconds(1))
            }
        }
    }

    private func timerExpired() async {
        operationGeneration += 1
        let expectedGeneration = operationGeneration
        countdownTask = nil
        timerDeadline = nil
        shouldResumeAfterInterruption = false
        wantsPlayback = false
        isPlaying = false
        isStopping = true
        endPlaybackActivity()
        resetProgramProgress()
        await audioEngine.stop(fadeDuration: 5)

        guard operationGeneration == expectedGeneration else { return }
        isStopping = false
        remainingSeconds = timerChoice.duration
    }

    private func clearTimer(resetDisplay: Bool) {
        countdownTask?.cancel()
        countdownTask = nil
        timerDeadline = nil

        if resetDisplay {
            remainingSeconds = timerChoice.duration
        }
    }

    private func observeAudioSession() {
#if !targetEnvironment(macCatalyst)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleInterruption(notification)
            }
            .store(in: &cancellables)
#endif

        NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereLostNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleMediaServicesLost()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleMediaServicesReset()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .AVAudioEngineConfigurationChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleEngineConfigurationChange()
            }
            .store(in: &cancellables)
    }

    private func beginPlaybackActivityIfNeeded() {
#if targetEnvironment(macCatalyst)
        guard playbackActivity == nil else { return }
        playbackActivity = ProcessInfo.processInfo.beginActivity(
            options: [.automaticTerminationDisabled, .suddenTerminationDisabled],
            reason: "YOIN Frequency is playing audio"
        )
#endif
    }

    private func endPlaybackActivity() {
#if targetEnvironment(macCatalyst)
        guard let playbackActivity else { return }
        ProcessInfo.processInfo.endActivity(playbackActivity)
        self.playbackActivity = nil
#endif
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return
        }

        switch type {
        case .began:
            isInterrupted = true
            operationGeneration += 1
            configurationRestartTask?.cancel()
            configurationRestartTask = nil
            shouldResumeAfterInterruption = wantsPlayback
            isPlaying = false
            isStopping = false
            countdownTask?.cancel()
            countdownTask = nil
            programAnchorElapsedSeconds = currentProgramElapsed
            programStartedAt = nil
            programProgressTask?.cancel()
            programProgressTask = nil
            publishProgramProgress(elapsed: programAnchorElapsedSeconds)
            audioEngine.stopImmediately(deactivateSession: false)

        case .ended:
            isInterrupted = false
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            guard shouldResumeAfterInterruption, options.contains(.shouldResume) else {
                shouldResumeAfterInterruption = false
                wantsPlayback = false
                resetProgramProgress()
                clearTimer(resetDisplay: true)
                endPlaybackActivity()
                return
            }

            shouldResumeAfterInterruption = false
            guard timerDeadline.map({ $0 > Date() }) ?? true else {
                wantsPlayback = false
                resetProgramProgress()
                clearTimer(resetDisplay: true)
                endPlaybackActivity()
                return
            }

            let startsFreshTimer = timerDeadline == nil
            programStartedAt = Date()

            do {
                try audioEngine.start(configuration: configuration)
                markAudioGraphStarted()
                wantsPlayback = true
                isPlaying = true
                beginPlaybackActivityIfNeeded()
                if startsFreshTimer {
                    startNewTimer()
                } else {
                    resumeTimerFromCurrentDeadline()
                }
                startProgramProgressUpdates()
            } catch {
                audioEngine.stopImmediately()
                wantsPlayback = false
                resetProgramProgress()
                clearTimer(resetDisplay: true)
                endPlaybackActivity()
                errorMessage = error.localizedDescription
            }

        @unknown default:
            break
        }
    }

    private func handleMediaServicesLost() {
        guard wantsPlayback || isPlaying || isStopping else { return }
        operationGeneration += 1
        configurationRestartTask?.cancel()
        configurationRestartTask = nil
        isPlaying = false
        isStopping = false
        countdownTask?.cancel()
        countdownTask = nil
        programAnchorElapsedSeconds = currentProgramElapsed
        programStartedAt = nil
        programProgressTask?.cancel()
        programProgressTask = nil
        publishProgramProgress(elapsed: programAnchorElapsedSeconds)
        audioEngine.stopImmediately(deactivateSession: false)
    }

    private func handleMediaServicesReset() {
        guard wantsPlayback, !isInterrupted else { return }
        guard timerDeadline.map({ $0 > Date() }) ?? true else {
            wantsPlayback = false
            resetProgramProgress()
            clearTimer(resetDisplay: true)
            endPlaybackActivity()
            return
        }

        operationGeneration += 1
        let startsFreshTimer = timerDeadline == nil
        programStartedAt = Date()

        do {
            try audioEngine.start(configuration: configuration)
            markAudioGraphStarted()
            isPlaying = true
            isStopping = false
            if startsFreshTimer {
                startNewTimer()
            } else {
                resumeTimerFromCurrentDeadline()
            }
            startProgramProgressUpdates()
        } catch {
            audioEngine.stopImmediately()
            wantsPlayback = false
            isPlaying = false
            isStopping = false
            resetProgramProgress()
            clearTimer(resetDisplay: true)
            endPlaybackActivity()
            errorMessage = error.localizedDescription
        }
    }

    private func handleEngineConfigurationChange() {
        guard wantsPlayback, isPlaying, !isStopping else { return }

        // 1回の出力切替で構成変更通知が複数届くことがあるため、静まってから1度だけ再構築する。
        if isDuplicateConfigurationChange {
            return
        }

        configurationRestartTask?.cancel()
        configurationRestartTask = Task { [weak self] in
            let clock = ContinuousClock()
            try? await clock.sleep(for: .milliseconds(180))
            guard
                !Task.isCancelled,
                let self,
                self.wantsPlayback,
                self.isPlaying,
                !self.isStopping,
                !self.isInterrupted
            else {
                return
            }

            if self.isDuplicateConfigurationChange {
                self.configurationRestartTask = nil
                return
            }

            self.configurationRestartTask = nil
            self.restartIfNeeded(preserveDeadline: true)
        }
    }

    private var isDuplicateConfigurationChange: Bool {
        guard
            let lastConfigurationRestartAt,
            Date().timeIntervalSince(lastConfigurationRestartAt) < 2,
            lastConfigurationRouteSignature == currentOutputRouteSignature
        else {
            return false
        }

        return audioEngine.isGraphRunning
    }

    private var currentOutputRouteSignature: String {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard !outputs.isEmpty else { return "no-output" }

        return outputs
            .map { "\($0.portType.rawValue):\($0.uid)" }
            .sorted()
            .joined(separator: "|")
    }

    private func markAudioGraphStarted() {
        lastConfigurationRestartAt = Date()
        lastConfigurationRouteSignature = currentOutputRouteSignature
    }

    private func persistSettings() {
        defaults.set(selectedPreset.id, forKey: DefaultsKey.presetID)
        defaults.set(noiseType.rawValue, forKey: DefaultsKey.noiseType)
        defaults.set(masterVolume, forKey: DefaultsKey.masterVolume)
        defaults.set(toneVolume, forKey: DefaultsKey.toneVolume)
        defaults.set(noiseVolume, forKey: DefaultsKey.noiseVolume)
        defaults.set(timerChoice.rawValue, forKey: DefaultsKey.timerMinutes)
    }

    private static func savedVolume(
        defaults: UserDefaults,
        key: String,
        fallback: Double,
        forceFallback: Bool = false
    ) -> Double {
        guard !forceFallback, defaults.object(forKey: key) != nil else { return fallback }
        return clampVolume(defaults.double(forKey: key))
    }

    private static func migratedPresetID(_ id: String?) -> String? {
        switch id {
        case "hadou2950", "hadou2950Pitch", "businessRaw":
            return "business"
        case "creativePitch", "creativeRaw":
            return "creative"
        case "thoughtsMakeThingsRaw":
            return "thoughtsMakeThings"
        default:
            return id
        }
    }

    private static func clampVolume(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(100, max(0, value))
    }

    private static func formatHz(_ value: Double?) -> String {
        guard let value else { return "--" }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return "\(formatter.string(from: NSNumber(value: value)) ?? String(value))Hz"
    }

    private static func formatRange(_ timeline: [TimelinePoint]) -> String {
        guard
            let minimum = timeline.map(\.value).min(),
            let maximum = timeline.map(\.value).max()
        else {
            return "--"
        }

        let minimumLabel = formatHz(minimum)
        let maximumLabel = formatHz(maximum)
        return minimum == maximum ? minimumLabel : "\(minimumLabel)–\(maximumLabel)"
    }
}
