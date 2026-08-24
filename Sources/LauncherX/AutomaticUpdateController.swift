@preconcurrency import Sparkle
import AppKit

@MainActor
final class AutomaticUpdateController: NSObject, @MainActor SPUStandardUserDriverDelegate {
    private lazy var standardUpdaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: self
    )

    var supportsGentleScheduledUpdateReminders: Bool { true }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCheckForUpdatesRequest),
            name: .launcherCheckForUpdates,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func checkAtLaunch() {
        let updater = standardUpdaterController.updater
        guard updater.automaticallyChecksForUpdates else { return }
        updater.checkForUpdatesInBackground()
    }

    func checkForUpdates() {
        standardUpdaterController.updater.checkForUpdates()
    }

    @objc private func handleCheckForUpdatesRequest() {
        checkForUpdates()
    }

    func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        true
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        guard handleShowingUpdate, !state.userInitiated else { return }
        NSApp.activate(ignoringOtherApps: true)
    }
}
