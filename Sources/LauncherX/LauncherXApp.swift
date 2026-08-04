import SwiftUI

@main
struct LauncherXApp: App {
    @StateObject private var model = LauncherModel()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
                .frame(minWidth: 760, minHeight: 540)
        }
        .windowStyle(.hiddenTitleBar)
        .commandsRemoved()
    }
}
