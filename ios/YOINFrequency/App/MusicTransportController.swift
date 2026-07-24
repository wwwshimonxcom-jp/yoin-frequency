import Combine
import Foundation
import MediaPlayer

@MainActor
final class MusicTransportController: ObservableObject {
    @Published private(set) var playbackState: MPMusicPlaybackState = .stopped
    @Published private(set) var title: String?
    @Published private(set) var artist: String?
    @Published private(set) var isRequestingAccess = false

    private let player = MPMusicPlayerController.systemMusicPlayer
    private var authorizationStatus = MPMediaLibrary.authorizationStatus()
    private var cancellables = Set<AnyCancellable>()

    var isPlaying: Bool {
        playbackState == .playing
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    var canRequestAccess: Bool {
        authorizationStatus == .notDetermined
    }

    init() {
        player.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.publisher(
            for: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.refresh()
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.refresh()
        }
        .store(in: &cancellables)

        refresh()
    }

    func refresh() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        playbackState = player.playbackState

        guard isAuthorized else {
            title = nil
            artist = nil
            return
        }

        title = player.nowPlayingItem?.title
        artist = player.nowPlayingItem?.artist
    }

    func requestAccess() {
        guard canRequestAccess, !isRequestingAccess else {
            refresh()
            return
        }

        isRequestingAccess = true
        MPMediaLibrary.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.authorizationStatus = status
                self.isRequestingAccess = false
                self.refresh()
            }
        }
    }

    func togglePlayPause() {
        guard isAuthorized else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }

    func skipToPrevious() {
        guard isAuthorized else { return }
        player.skipToPreviousItem()
    }

    func skipToNext() {
        guard isAuthorized else { return }
        player.skipToNextItem()
    }
}
