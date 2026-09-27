import SwiftUI
import UIKit

@MainActor
final class YOINFrequencyAppDelegate: NSObject, UIApplicationDelegate {
    // Keep playback state alive for the lifetime of the process, even when the
    // last Mac Catalyst window is closed with the red button.
    let playerStore = PlayerStore()
}

@main
@MainActor
struct YOINFrequencyApp: App {
    @UIApplicationDelegateAdaptor(YOINFrequencyAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(store: appDelegate.playerStore)
                .preferredColorScheme(.dark)
        }
    }
}
