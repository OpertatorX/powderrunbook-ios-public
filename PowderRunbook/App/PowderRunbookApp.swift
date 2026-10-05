import SwiftUI

@main
struct PowderRunbookApp: App {
    @StateObject private var store = WorkspaceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(PRTheme.accent)
        }
    }
}
