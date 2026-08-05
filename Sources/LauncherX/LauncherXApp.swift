import SwiftUI
import AppKit

@main
struct LauncherXApp: App {
    @NSApplicationDelegateAdaptor(LauncherAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commandsRemoved()
    }
}

@MainActor
final class LauncherAppDelegate: NSObject, NSApplicationDelegate {
    private let model = LauncherModel()
    private var launcherWindow: LauncherWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.setActivationPolicy(.accessory)
        presentLauncher()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        presentLauncher()
        return true
    }

    private func presentLauncher() {
        if let launcherWindow {
            NSApp.unhide(nil)
            launcherWindow.makeKeyAndOrderFront(nil)
            launcherWindow.orderFrontRegardless()
            NSApp.activate()
            model.maximizeLauncherWindow()
            return
        }

        let initialFrame = NSScreen.main?.frame
            ?? NSRect(x: 0, y: 0, width: 1_440, height: 900)
        let window = LauncherWindow(
            contentRect: initialFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 540)
        )
        launcherWindow = window
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate()
        model.maximizeLauncherWindow()
    }
}
