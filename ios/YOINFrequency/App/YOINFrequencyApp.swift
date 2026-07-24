import SwiftUI

@main
@MainActor
struct YOINFrequencyApp: App {
    @StateObject private var store = PlayerStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
