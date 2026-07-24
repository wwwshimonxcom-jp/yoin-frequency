import AVFAudio
import Foundation

struct AudioEngineConfiguration: Equatable {
    let preset: AudioPresetDefinition
    let noiseType: NoiseType
    let listeningMode: ListeningMode
    let masterVolume: Double
    let toneVolume: Double
    let noiseVolume: Double
    let startOffsetSeconds: TimeInterval
}

@MainActor
final class FrequencyAudioEngine {
    enum AudioEngineError: LocalizedError {
        case unsupportedAudioFormat
        case missingChannelData

        var errorDescription: String? {
            switch self {
            case .unsupportedAudioFormat:
                "この端末のオーディオ形式を準備できませんでした。"
            case .missingChannelData:
                "オーディオバッファーを準備できませんでした。"
            }
        }
    }

    private let session = AVAudioSession.sharedInstance()
    private var engine: AVAudioEngine?
    private var toneSource: AVAudioSourceNode?
    private var toneMixer: AVAudioMixerNode?
    private var noisePlayer: AVAudioPlayerNode?
    private var toneRenderState: ToneRenderState?
    private var noiseBuffer: AVAudioPCMBuffer?
    private var fadeTask: Task<Void, Never>?
    private var generation = 0
    private var desiredMasterGain: Float = 0
    private var isFadingOut = false

    private(set) var isRunning = false

    var isGraphRunning: Bool {
        engine?.isRunning == true
    }

    func start(configuration: AudioEngineConfiguration) throws {
        generation += 1
        let currentGeneration = generation
        fadeTask?.cancel()
        isFadingOut = false
        shutdown(deactivateSession: true)

        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true)

            let sampleRate = session.sampleRate > 0 ? session.sampleRate : 48_000
            guard let format = AVAudioFormat(
                standardFormatWithSampleRate: sampleRate,
                channels: 2
            ) else {
                throw AudioEngineError.unsupportedAudioFormat
            }

            let newEngine = AVAudioEngine()
            let newNoisePlayer = AVAudioPlayerNode()

            newEngine.attach(newNoisePlayer)
            newEngine.connect(newNoisePlayer, to: newEngine.mainMixerNode, format: format)

            let preparedTone = Self.makeToneSource(
                preset: configuration.preset,
                listeningMode: configuration.listeningMode,
                startOffsetSeconds: configuration.startOffsetSeconds,
                format: format
            )
            let preparedNoiseBuffer = try Self.makeNoiseBuffer(
                type: configuration.noiseType,
                format: format
            )

            if let preparedTone {
                newEngine.attach(preparedTone.source)
                newEngine.attach(preparedTone.mixer)
                newEngine.connect(preparedTone.source, to: preparedTone.mixer, format: format)
                newEngine.connect(preparedTone.mixer, to: newEngine.mainMixerNode, format: format)
                preparedTone.mixer.outputVolume = Self.branchGain(
                    percent: configuration.toneVolume,
                    maximum: 0.08
                )
            }
            newNoisePlayer.scheduleBuffer(preparedNoiseBuffer, at: nil, options: [.loops])

            newNoisePlayer.volume = Self.branchGain(
                percent: configuration.noiseVolume,
                maximum: 0.13
            )

            desiredMasterGain = Self.masterGain(percent: configuration.masterVolume)
            newEngine.mainMixerNode.outputVolume = 0
            newEngine.prepare()
            try newEngine.start()

            newNoisePlayer.play()

            engine = newEngine
            toneSource = preparedTone?.source
            toneMixer = preparedTone?.mixer
            toneRenderState = preparedTone?.state
            noisePlayer = newNoisePlayer
            noiseBuffer = preparedNoiseBuffer
            isRunning = true

            fadeTask = Task { [weak self] in
                guard let self else { return }
                await self.rampMaster(
                    from: 0,
                    to: self.desiredMasterGain,
                    duration: 1.4,
                    generation: currentGeneration
                )
                if self.generation == currentGeneration {
                    self.fadeTask = nil
                }
            }
        } catch {
            shutdown(deactivateSession: true)
            throw error
        }
    }

    func updateVolumes(master: Double, tone: Double, noise: Double) {
        desiredMasterGain = Self.masterGain(percent: master)
        toneMixer?.outputVolume = Self.branchGain(percent: tone, maximum: 0.08)
        noisePlayer?.volume = Self.branchGain(percent: noise, maximum: 0.13)

        if isRunning, !isFadingOut {
            fadeTask?.cancel()
            fadeTask = nil
            engine?.mainMixerNode.outputVolume = desiredMasterGain
        }
    }

    func stop(fadeDuration: TimeInterval, deactivateSession: Bool = true) async {
        guard isRunning || engine != nil else {
            shutdown(deactivateSession: deactivateSession)
            return
        }

        generation += 1
        let currentGeneration = generation
        fadeTask?.cancel()
        fadeTask = nil
        isFadingOut = true
        let currentGain = engine?.mainMixerNode.outputVolume ?? 0

        await rampMaster(
            from: currentGain,
            to: 0,
            duration: fadeDuration,
            generation: currentGeneration
        )

        guard generation == currentGeneration else { return }
        shutdown(deactivateSession: deactivateSession)
    }

    func stopImmediately(deactivateSession: Bool = true) {
        generation += 1
        fadeTask?.cancel()
        fadeTask = nil
        isFadingOut = false
        shutdown(deactivateSession: deactivateSession)
    }

    private func rampMaster(
        from start: Float,
        to end: Float,
        duration: TimeInterval,
        generation expectedGeneration: Int
    ) async {
        guard let mixer = engine?.mainMixerNode else { return }
        let safeDuration = max(0, duration)

        guard safeDuration > 0 else {
            mixer.outputVolume = end
            return
        }

        let frameRate = 30.0
        let stepCount = max(1, Int((safeDuration * frameRate).rounded()))
        let clock = ContinuousClock()

        for step in 1...stepCount {
            guard !Task.isCancelled, generation == expectedGeneration else { return }
            let progress = Float(step) / Float(stepCount)
            mixer.outputVolume = start + ((end - start) * progress)
            try? await clock.sleep(for: .seconds(safeDuration / Double(stepCount)))
        }
    }

    private func shutdown(deactivateSession: Bool) {
        noisePlayer?.stop()
        engine?.stop()
        engine?.reset()

        toneSource = nil
        toneMixer = nil
        toneRenderState = nil
        noisePlayer = nil
        noiseBuffer = nil
        engine = nil
        isRunning = false
        isFadingOut = false

        if deactivateSession {
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    private static func masterGain(percent: Double) -> Float {
        let normalized = min(100, max(0, percent)) / 100
        return Float(pow(normalized, 1.15))
    }

    private static func branchGain(percent: Double, maximum: Double) -> Float {
        let normalized = min(100, max(0, percent)) / 100
        return Float(pow(normalized, 1.35) * maximum)
    }

    // AVAudioSourceNode invokes this render block on its real-time audio thread.
    // Keep the factory nonisolated so the closure does not inherit MainActor
    // isolation from FrequencyAudioEngine and trap when audio rendering begins.
    nonisolated private static func makeToneSource(
        preset: AudioPresetDefinition,
        listeningMode: ListeningMode,
        startOffsetSeconds: TimeInterval,
        format: AVAudioFormat
    ) -> (source: AVAudioSourceNode, mixer: AVAudioMixerNode, state: ToneRenderState)? {
        guard
            let leftFrequency = preset.leftFrequency,
            let rightFrequency = preset.rightFrequency
        else {
            return nil
        }

        let state = ToneRenderState(
            sampleRate: format.sampleRate,
            listeningMode: listeningMode,
            leftFrequency: leftFrequency,
            rightFrequency: rightFrequency,
            differenceFrequency: preset.differenceFrequency ?? 0,
            startOffsetSeconds: startOffsetSeconds,
            durationSeconds: preset.durationSeconds,
            loops: preset.loop,
            pulseTimeline: preset.pulseTimeline,
            pitchTimeline: preset.pitchTimeline
        )
        let source = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            state.render(frameCount: frameCount, audioBufferList: audioBufferList)
        }

        return (source, AVAudioMixerNode(), state)
    }

    private static func makeNoiseBuffer(
        type: NoiseType,
        format: AVAudioFormat
    ) throws -> AVAudioPCMBuffer {
        let durationSeconds = 10.0
        let frameCount = AVAudioFrameCount((format.sampleRate * durationSeconds).rounded())
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channels = buffer.floatChannelData
        else {
            throw AudioEngineError.missingChannelData
        }

        buffer.frameLength = frameCount
        let totalFrames = Int(frameCount)

        for channel in 0..<2 {
            var generator = NoiseGenerator(
                seed: UInt32(0xA341_316C &+ UInt32(channel * 0x1021))
            )
            let samples = channels[channel]

            for frame in 0..<totalFrames {
                samples[frame] = generator.nextSample(type: type)
            }

            normalizeNoise(samples, count: totalFrames, targetRMS: 0.25)
            applyEdgeFade(samples, count: totalFrames, sampleRate: format.sampleRate)
        }

        return buffer
    }

    private static func normalizeNoise(
        _ samples: UnsafeMutablePointer<Float>,
        count: Int,
        targetRMS: Float
    ) {
        guard count > 0 else { return }
        var sumOfSquares = 0.0

        for index in 0..<count {
            let value = Double(samples[index])
            sumOfSquares += value * value
        }

        let rms = sqrt(sumOfSquares / Double(count))
        guard rms > 0 else { return }
        let scale = min(4, Double(targetRMS) / rms)

        for index in 0..<count {
            samples[index] = max(-1, min(1, Float(Double(samples[index]) * scale)))
        }
    }

    private static func applyEdgeFade(
        _ samples: UnsafeMutablePointer<Float>,
        count: Int,
        sampleRate: Double
    ) {
        let fadeFrames = min(count / 2, max(1, Int(sampleRate * 0.005)))

        for index in 0..<fadeFrames {
            let gain = Float(index) / Float(fadeFrames)
            samples[index] *= gain
            samples[count - 1 - index] *= gain
        }
    }
}

private final class ToneRenderState: @unchecked Sendable {
    private static let twoPi = Double.pi * 2
    private static let pulseGateBase = 0.5
    private static let pulseGateDepth = 0.45
    private static let pulseSmoothingFrequency = 32.0

    private let sampleRate: Double
    private let listeningMode: ListeningMode
    private let leftFrequency: Double
    private let rightFrequency: Double
    private let differenceFrequency: Double
    private let durationSeconds: Double
    private let loops: Bool
    private let pulseSmoothingCoefficient: Double

    private var pulseTimeline: TimelineCursor
    private var pitchTimeline: TimelineCursor
    private var elapsedSeconds = 0.0
    private var leftPhase = 0.0
    private var rightPhase = 0.0
    private var speakerModulationPhase = 0.0
    private var pulsePhase = 0.0
    private var smoothedPulseGain = pulseGateBase

    init(
        sampleRate: Double,
        listeningMode: ListeningMode,
        leftFrequency: Double,
        rightFrequency: Double,
        differenceFrequency: Double,
        startOffsetSeconds: TimeInterval,
        durationSeconds: Double?,
        loops: Bool,
        pulseTimeline: [TimelinePoint],
        pitchTimeline: [TimelinePoint]
    ) {
        self.sampleRate = max(1, sampleRate)
        self.listeningMode = listeningMode
        self.leftFrequency = max(0, leftFrequency)
        self.rightFrequency = max(0, rightFrequency)
        self.differenceFrequency = max(0, differenceFrequency)
        elapsedSeconds = max(0, startOffsetSeconds)
        self.loops = loops
        self.pulseTimeline = TimelineCursor(points: pulseTimeline)
        self.pitchTimeline = TimelineCursor(points: pitchTimeline)

        let lastTimelineTime = max(
            pulseTimeline.last?.time ?? 0,
            pitchTimeline.last?.time ?? 0
        )
        self.durationSeconds = max(0, durationSeconds ?? lastTimelineTime)
        pulseSmoothingCoefficient = 1 - exp(
            (-Self.twoPi * Self.pulseSmoothingFrequency) / self.sampleRate
        )
    }

    func render(
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard !buffers.isEmpty else { return noErr }

        for frame in 0..<Int(frameCount) {
            let timelineTime = currentTimelineTime
            let hasPitchTimeline = !pitchTimeline.isEmpty
            let hasPulseTimeline = !pulseTimeline.isEmpty
            let pitch = pitchTimeline.value(at: timelineTime, fallback: leftFrequency)
            let pulseGain = hasPulseTimeline ? nextPulseGain(at: timelineTime) : 1

            let leftSample: Float
            let rightSample: Float

            switch listeningMode {
            case .headphones:
                let currentLeftFrequency = hasPitchTimeline ? pitch : leftFrequency
                let currentRightFrequency = hasPitchTimeline ? pitch : rightFrequency
                leftSample = Float(sin(leftPhase) * pulseGain)
                rightSample = Float(sin(rightPhase) * pulseGain)
                advancePhase(&leftPhase, frequency: currentLeftFrequency)
                advancePhase(&rightPhase, frequency: currentRightFrequency)

            case .speaker:
                let currentFrequency = hasPitchTimeline ? pitch : leftFrequency
                let modulation: Double

                if hasPulseTimeline {
                    modulation = pulseGain
                } else if differenceFrequency > 0 {
                    modulation = 0.56 + (sin(speakerModulationPhase) * 0.18)
                    advancePhase(&speakerModulationPhase, frequency: differenceFrequency)
                } else {
                    modulation = 0.56
                }

                let sample = Float(sin(leftPhase) * modulation)
                leftSample = sample
                rightSample = sample
                advancePhase(&leftPhase, frequency: currentFrequency)
            }

            write(
                left: leftSample,
                right: rightSample,
                frame: frame,
                buffers: buffers
            )
            elapsedSeconds += 1 / sampleRate
        }

        return noErr
    }

    private var currentTimelineTime: Double {
        guard durationSeconds > 0 else { return elapsedSeconds }
        if loops {
            return elapsedSeconds.truncatingRemainder(dividingBy: durationSeconds)
        }
        return min(elapsedSeconds, durationSeconds)
    }

    private func nextPulseGain(at timelineTime: Double) -> Double {
        let rate = max(0, pulseTimeline.value(at: timelineTime, fallback: 0))
        guard rate > 0 else { return Self.pulseGateBase }

        advancePhase(&pulsePhase, frequency: rate)
        let square = pulsePhase < Double.pi ? 1.0 : -1.0
        let target = Self.pulseGateBase + (square * Self.pulseGateDepth)
        smoothedPulseGain += pulseSmoothingCoefficient * (target - smoothedPulseGain)
        return smoothedPulseGain
    }

    private func advancePhase(_ phase: inout Double, frequency: Double) {
        phase += Self.twoPi * max(0, frequency) / sampleRate
        if phase >= Self.twoPi {
            phase.formTruncatingRemainder(dividingBy: Self.twoPi)
        }
    }

    private func write(
        left: Float,
        right: Float,
        frame: Int,
        buffers: UnsafeMutableAudioBufferListPointer
    ) {
        if buffers.count >= 2 {
            if let leftData = buffers[0].mData?.assumingMemoryBound(to: Float.self) {
                leftData[frame] = left
            }
            if let rightData = buffers[1].mData?.assumingMemoryBound(to: Float.self) {
                rightData[frame] = right
            }
            return
        }

        guard
            let data = buffers[0].mData?.assumingMemoryBound(to: Float.self)
        else {
            return
        }

        let channelCount = max(1, Int(buffers[0].mNumberChannels))
        let baseIndex = frame * channelCount
        data[baseIndex] = left
        if channelCount > 1 {
            data[baseIndex + 1] = right
        }
    }
}

private struct TimelineCursor {
    private let points: [TimelinePoint]
    private var segmentIndex = 0
    private var previousTime = -Double.infinity

    init(points: [TimelinePoint]) {
        self.points = points.sorted { $0.time < $1.time }
    }

    var isEmpty: Bool {
        points.isEmpty
    }

    mutating func value(at time: Double, fallback: Double) -> Double {
        guard let first = points.first else { return fallback }
        guard points.count > 1 else { return first.value }

        if time < previousTime {
            segmentIndex = 0
        }
        previousTime = time

        if time <= first.time {
            return first.value
        }

        while
            segmentIndex + 1 < points.count,
            time > points[segmentIndex + 1].time
        {
            segmentIndex += 1
        }

        guard segmentIndex + 1 < points.count else {
            return points[points.count - 1].value
        }

        let start = points[segmentIndex]
        let end = points[segmentIndex + 1]
        let span = end.time - start.time
        guard span > 0 else { return end.value }
        let progress = min(1, max(0, (time - start.time) / span))
        return start.value + ((end.value - start.value) * progress)
    }
}

private struct NoiseGenerator {
    private var primaryRandom: XorShift32
    private var secondaryRandom: XorShift32
    private var pink = PinkNoiseState()
    private var brown = BrownNoiseState()

    init(seed: UInt32) {
        primaryRandom = XorShift32(seed: seed)
        secondaryRandom = XorShift32(seed: seed ^ 0x9E37_79B9)
    }

    mutating func nextSample(type: NoiseType) -> Float {
        switch type {
        case .white:
            return primaryRandom.nextFloat()
        case .pink:
            return pink.next(white: primaryRandom.nextFloat())
        case .brown:
            return brown.next(white: primaryRandom.nextFloat())
        case .mixed:
            let pinkSample = pink.next(white: primaryRandom.nextFloat())
            let brownSample = brown.next(white: secondaryRandom.nextFloat())
            return max(-1, min(1, (pinkSample + brownSample) * 0.58))
        }
    }
}

private struct XorShift32 {
    private var state: UInt32

    init(seed: UInt32) {
        state = seed == 0 ? 0x6D2B_79F5 : seed
    }

    mutating func nextFloat() -> Float {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return (Float(state) / Float(UInt32.max)) * 2 - 1
    }
}

private struct PinkNoiseState {
    private var b0: Float = 0
    private var b1: Float = 0
    private var b2: Float = 0
    private var b3: Float = 0
    private var b4: Float = 0
    private var b5: Float = 0
    private var b6: Float = 0

    mutating func next(white: Float) -> Float {
        b0 = (0.99886 * b0) + (white * 0.0555179)
        b1 = (0.99332 * b1) + (white * 0.0750759)
        b2 = (0.969 * b2) + (white * 0.153852)
        b3 = (0.8665 * b3) + (white * 0.3104856)
        b4 = (0.55 * b4) + (white * 0.5329522)
        b5 = (-0.7616 * b5) - (white * 0.016898)
        let output = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + (white * 0.5362)) * 0.08
        b6 = white * 0.115926
        return max(-1, min(1, output))
    }
}

private struct BrownNoiseState {
    private var lastOutput: Float = 0

    mutating func next(white: Float) -> Float {
        lastOutput = (lastOutput + (0.02 * white)) / 1.02
        return max(-1, min(1, lastOutput * 2.8))
    }
}
