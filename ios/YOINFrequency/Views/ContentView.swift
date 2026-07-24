import SwiftUI
import UIKit

@MainActor
struct ContentView: View {
    @ObservedObject var store: PlayerStore
    @StateObject private var musicController = MusicTransportController()
    @State private var isMusicPanelPresented = false

    private let gold = Color(red: 0.88, green: 0.75, blue: 0.43)
    private let warmWhite = Color(red: 0.96, green: 0.94, blue: 0.89)

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 18) {
                    header
                    nowPlayingCard
                    listeningSection
                    presetSection
                    volumeSection
                    noiseSection
                    timerSection
                    safetyNote
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            playerBar
        }
        .sheet(isPresented: $isMusicPanelPresented) {
            MusicControlPanel(
                controller: musicController,
                accent: gold,
                warmWhite: warmWhite
            )
            .presentationDetents([.height(310), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        .alert(
            "再生できませんでした",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "オーディオの設定を確認してください。")
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.065)
            RadialGradient(
                colors: [gold.opacity(0.14), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 470
            )
            RadialGradient(
                colors: [Color.indigo.opacity(0.18), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("YOIN")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(gold)
                Text("Frequency")
                    .font(.system(size: 30, weight: .light, design: .rounded))
                    .foregroundStyle(warmWhite)
            }

            Spacer()

            Button {
                isMusicPanelPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                    Text("Apple Music")
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(warmWhite.opacity(0.74))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(.white.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Apple Musicコントロールを開く")
            .accessibilityHint("再生、一時停止、前後送りのパネルを下から開きます")
        }
    }

    private var nowPlayingCard: some View {
        VStack(spacing: 18) {
            ZStack {
                BreathingOrb(
                    isPlaying: store.isPlaying,
                    hasTone: store.selectedPreset.hasTone,
                    accent: gold
                )
            }

            VStack(spacing: 5) {
                Text(store.selectedPreset.name)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(warmWhite)
                Text(store.selectedPreset.description)
                    .font(.subheadline)
                    .foregroundStyle(warmWhite.opacity(0.58))
            }

            HStack(spacing: 0) {
                ForEach(Array(store.frequencySummary.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 5) {
                        Text(item.label.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .tracking(1.3)
                            .foregroundStyle(warmWhite.opacity(0.42))
                        Text(item.value)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundStyle(warmWhite.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                    .frame(maxWidth: .infinity)

                    if index < store.frequencySummary.count - 1 {
                        Divider()
                            .overlay(.white.opacity(0.12))
                            .frame(height: 34)
                    }
                }
            }
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 18)
        .cardStyle()
        .accessibilityElement(children: .contain)
    }

    private var presetSection: some View {
        controlCard(title: "MODE", systemImage: "circle.grid.2x2") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(store.presets) { preset in
                    SelectionButton(
                        title: preset.name,
                        subtitle: preset.description,
                        isSelected: store.selectedPreset.id == preset.id,
                        accent: gold
                    ) {
                        store.selectPreset(preset)
                    }
                }
            }
        }
    }

    private var listeningSection: some View {
        controlCard(title: "SOUND METHOD", systemImage: "waveform") {
            VStack(spacing: 13) {
                HStack(spacing: 10) {
                    ForEach(ListeningMode.allCases) { mode in
                        ListeningModeButton(
                            mode: mode,
                            isSelected: store.listeningMode == mode,
                            accent: gold
                        ) {
                            store.selectListeningMode(mode)
                        }
                    }
                }

                Label("どちらもヘッドホン／スピーカーで再生できます", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(warmWhite.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)

            }
        }
    }

    private var volumeSection: some View {
        controlCard(title: "VOLUME", systemImage: "slider.horizontal.3") {
            VStack(spacing: 19) {
                VolumeSlider(
                    title: "Master",
                    value: Binding(
                        get: { store.masterVolume },
                        set: { store.setMasterVolume($0) }
                    ),
                    accent: gold
                )

                VolumeSlider(
                    title: "Tone",
                    value: Binding(
                        get: { store.toneVolume },
                        set: { store.setToneVolume($0) }
                    ),
                    accent: gold,
                    isEnabled: store.selectedPreset.hasTone
                )

                VolumeSlider(
                    title: "Noise",
                    value: Binding(
                        get: { store.noiseVolume },
                        set: { store.setNoiseVolume($0) }
                    ),
                    accent: gold
                )
            }
        }
    }

    private var noiseSection: some View {
        controlCard(title: "NOISE", systemImage: "waveform") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(NoiseType.allCases) { type in
                    CompactSelectionButton(
                        title: type.displayName,
                        isSelected: store.noiseType == type,
                        accent: gold
                    ) {
                        store.selectNoiseType(type)
                    }
                }
            }
        }
    }

    private var timerSection: some View {
        controlCard(title: "TIMER", systemImage: "moon.stars") {
            VStack(spacing: 15) {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 8),
                        count: 4
                    ),
                    spacing: 8
                ) {
                    ForEach(TimerChoice.allCases) { choice in
                        CompactSelectionButton(
                            title: choice.displayName,
                            isSelected: store.timerChoice == choice,
                            accent: gold
                        ) {
                            store.selectTimer(choice)
                        }
                    }
                }

                HStack {
                    Text(store.isPlaying ? "残り時間" : "設定時間")
                    Spacer()
                    Text(timerText)
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundStyle(gold)
                }
                .font(.caption)
                .foregroundStyle(warmWhite.opacity(0.58))
            }
        }
    }

    private var safetyNote: some View {
        Label {
            Text("最初は小さめの音量で。出力先が変わると、そのまま新しい出力先で続きます。")
        } icon: {
            Image(systemName: "ear")
        }
        .font(.caption)
        .foregroundStyle(warmWhite.opacity(0.48))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var playerBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(.white.opacity(0.08))

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(playerStatusLabel) · \(store.listeningMode.displayName.uppercased())")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(gold.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                    Text(store.selectedPreset.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(warmWhite)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button {
                    isMusicPanelPresented = true
                } label: {
                    Image(systemName: "music.note")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(warmWhite.opacity(0.9))
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.08), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Apple Musicコントロールを開く")
                .accessibilityHint("下から操作パネルを開きます")

                Button {
                    store.isPlaybackRequested ? store.stop() : store.play()
                } label: {
                    HStack(spacing: 9) {
                        if store.isStopping {
                            ProgressView()
                                .tint(Color.black.opacity(0.75))
                        } else {
                            Image(systemName: store.isPlaybackRequested ? "stop.fill" : "play.fill")
                        }
                        Text(store.isStopping ? "停止中" : (store.isPlaybackRequested ? "Stop" : "Play"))
                    }
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.8))
                    .frame(minWidth: 112)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(gold, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(store.isStopping)
                .opacity(store.isStopping ? 0.72 : 1)
                .accessibilityLabel(
                    store.isPlaybackRequested
                        ? "YOIN Frequencyを停止"
                        : "YOIN Frequencyを再生"
                )
                .accessibilityHint(store.isPlaybackRequested ? "音を停止します" : "音を再生します")
            }
            .frame(maxWidth: 680)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
        }
    }

    private var timerText: String {
        guard let remaining = store.remainingSeconds else { return "∞" }
        let totalSeconds = max(0, Int(remaining.rounded(.up)))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private var playerStatusLabel: String {
        if store.isStopping {
            return "STOPPING"
        }
        if store.isPlaybackRequested, !store.isPlaying {
            return "INTERRUPTED"
        }
        return store.isPlaying ? "NOW PLAYING" : "READY"
    }

    private func controlCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(warmWhite.opacity(0.58))

            content()
        }
        .padding(17)
        .cardStyle()
    }
}

private struct SelectionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(subtitle)
                    .font(.caption2)
                    .opacity(0.62)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? Color.black.opacity(0.8) : Color.white.opacity(0.78))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 78)
            .padding(.vertical, 13)
            .background(isSelected ? accent : Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(isSelected ? accent : Color.white.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ListeningModeButton: View {
    let mode: ListeningMode
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(mode.channelLabel)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(mode.displayName.uppercased())
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(mode.localizedName)
                    .font(.subheadline.weight(.semibold))

                Text(mode.summary)
                    .font(.caption2)
                    .opacity(0.64)
                    .lineLimit(2)
            }
            .foregroundStyle(isSelected ? Color.black.opacity(0.8) : Color.white.opacity(0.78))
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .padding(14)
            .background(
                isSelected ? accent : Color.white.opacity(0.055),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? accent : Color.white.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.localizedName)、\(mode.summary)")
        .accessibilityValue(isSelected ? "選択中" : "")
        .accessibilityHint("ヘッドホンとスピーカーのどちらでも再生できます")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MusicControlPanel: View {
    @ObservedObject var controller: MusicTransportController
    let accent: Color
    let warmWhite: Color
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .frame(width: 44, height: 44)
                        .background(accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Music")
                            .font(.headline)
                            .foregroundStyle(warmWhite)
                            .accessibilityAddTraits(.isHeader)
                        Text("Musicアプリの再生を操作")
                            .font(.caption)
                            .foregroundStyle(warmWhite.opacity(0.54))
                    }

                    Spacer()
                }

                if controller.isAuthorized {
                    authorizedControls
                } else {
                    authorizationPrompt
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 7)
            .padding(.bottom, 24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.035, green: 0.045, blue: 0.065).opacity(0.76))
        .onAppear {
            controller.refresh()
        }
    }

    private var authorizedControls: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(controller.title ?? fallbackTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(warmWhite)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(controller.artist ?? "Musicアプリの現在のキューを操作します")
                    .font(.caption)
                    .foregroundStyle(warmWhite.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 30) {
                transportButton(
                    systemImage: "backward.fill",
                    size: 52,
                    accessibilityLabel: "Apple Musicの前の曲"
                ) {
                    controller.skipToPrevious()
                }

                transportButton(
                    systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                    size: 66,
                    isPrimary: true,
                    accessibilityLabel: controller.isPlaying
                        ? "Apple Musicを一時停止"
                        : "Apple Musicを再生"
                ) {
                    controller.togglePlayPause()
                }

                transportButton(
                    systemImage: "forward.fill",
                    size: 52,
                    accessibilityLabel: "Apple Musicの次の曲"
                ) {
                    controller.skipToNext()
                }
            }
        }
    }

    private var authorizationPrompt: some View {
        VStack(spacing: 13) {
            Text(
                controller.canRequestAccess
                    ? "再生中のApple Musicをここから操作するには、最初の1回だけアクセスを許可してください。"
                    : "Apple Musicへのアクセスが許可されていません。iPhoneの設定から変更できます。"
            )
            .font(.subheadline)
            .foregroundStyle(warmWhite.opacity(0.7))
            .multilineTextAlignment(.center)

            Button {
                if controller.canRequestAccess {
                    controller.requestAccess()
                } else if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            } label: {
                HStack(spacing: 8) {
                    if controller.isRequestingAccess {
                        ProgressView()
                            .tint(Color.black.opacity(0.75))
                    } else {
                        Image(systemName: controller.canRequestAccess ? "music.note" : "gearshape.fill")
                    }
                    Text(controller.canRequestAccess ? "Apple Musicを操作する" : "設定を開く")
                }
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.8))
                .padding(.horizontal, 20)
                .frame(minHeight: 48)
                .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(controller.isRequestingAccess)
        }
    }

    private var fallbackTitle: String {
        controller.isPlaying
            ? "Apple Musicを再生中"
            : "Musicアプリで曲を選んでください"
    }

    private func transportButton(
        systemImage: String,
        size: CGFloat,
        isPrimary: Bool = false,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: isPrimary ? 23 : 17, weight: .semibold))
                .foregroundStyle(isPrimary ? Color.black.opacity(0.8) : warmWhite.opacity(0.9))
                .frame(width: size, height: size)
                .background(isPrimary ? accent : Color.white.opacity(0.08), in: Circle())
                .overlay {
                    Circle()
                        .stroke(isPrimary ? accent : Color.white.opacity(0.1), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct BreathingOrb: View {
    let isPlaying: Bool
    let hasTone: Bool
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isPlaying || reduceMotion)) { timeline in
            let seconds = timeline.date.timeIntervalSinceReferenceDate
            let wave = (sin((seconds / 6.4) * .pi * 2) + 1) / 2
            let scale = isPlaying && !reduceMotion ? 0.92 + (wave * 0.13) : 0.92

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.48), Color.blue.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 72
                        )
                    )
                    .frame(width: 144, height: 144)
                    .scaleEffect(scale)
                    .opacity(isPlaying ? 1 : 0.58)

                Circle()
                    .stroke(accent.opacity(0.46), lineWidth: 1)
                    .frame(width: 94, height: 94)

                Image(systemName: hasTone ? "waveform.path" : "wind")
                    .font(.system(size: 35, weight: .ultraLight))
                    .foregroundStyle(accent)
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying && !reduceMotion)
            }
            .animation(.easeOut(duration: 0.35), value: isPlaying)
        }
    }
}

private struct CompactSelectionButton: View {
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black.opacity(0.8) : Color.white.opacity(0.72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? accent : Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 11))
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(isSelected ? accent : Color.white.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct VolumeSlider: View {
    let title: String
    @Binding var value: Double
    let accent: Color
    var isEnabled = true

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value.rounded()))%")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(accent)
            }

            Slider(value: $value, in: 0...100, step: 1)
            .tint(accent)
        }
        .foregroundStyle(Color.white.opacity(isEnabled ? 0.76 : 0.3))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.48)
    }
}

private extension View {
    func cardStyle() -> some View {
        background(.white.opacity(0.052), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.075), lineWidth: 1)
            }
    }
}

#if DEBUG
private struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: PlayerStore(
                defaults: UserDefaults(suiteName: "YOINFrequencyPreview")!
            )
        )
    }
}
#endif
