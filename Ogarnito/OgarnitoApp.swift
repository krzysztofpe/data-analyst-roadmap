import SwiftUI

@main
struct OgarnitoApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            // Po powrocie do apki zabieramy to, co Siri/Skróty złapały w tle.
            if phase == .active { store.drainInbox() }
        }
    }
}
