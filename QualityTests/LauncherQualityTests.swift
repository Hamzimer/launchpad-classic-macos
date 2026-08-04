import Foundation
import Darwin
import AppKit
import CoreGraphics

private struct QualityTestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
@MainActor
struct LauncherQualityTests {
    static func main() async {
        do {
            try invalidSavedPreferencesAreSanitized()
            try duplicateSavedGroupsAndPathsAreSanitized()
            try duplicateRuntimeOrderDoesNotCrashOrLoseEntries()
            try dropInputValidationRejectsUnknownIdentifiers()
            try folderLifecyclePersistsSafely()
            try await folderRenameControlsPersistExplicitly()
            try folderRemovalMatchesNativeLifecycle()
            try pageNavigationHandlesIntegerBoundaries()
            try modalUIBlocksBackgroundPageNavigation()
            try dismissMotionMatchesReferenceApplication()
            try referenceIconSizingMatchesAttachedApp()
            try rootGridUsesAvailableScreenSpace()
            try folderGridMetricsNeverOverflowTheirPanel()
            try pageWindowLimitsRenderedPages()
            try scannerGracefullyHandlesMissingRoots()
            try await imageLoadersHandleMissingFiles()
            try await fileOperatorRejectsUnsafeDeleteLocation()
            print("Launcher quality tests passed (17/17)")
        } catch {
            FileHandle.standardError.write(Data("Launcher quality tests failed: \(error)\n".utf8))
            Darwin.exit(EXIT_FAILURE)
        }
    }

    private static func invalidSavedPreferencesAreSanitized() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        context.defaults.set("unsupported", forKey: "language")
        context.defaults.set(Double.nan, forKey: "iconSize")
        context.defaults.set("file:/tmp/not-an-image.txt", forKey: "background")
        context.defaults.set([
            "app:/Applications/Alpha.app",
            "app:/Applications/Alpha.app",
            "invalid",
            "group:not-a-uuid"
        ], forKey: "launcher.order.v1")

        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        try require(model.language == "system", "Invalid language was not sanitized")
        try require(model.iconSize == 92, "Non-finite icon size was not sanitized")
        try require(model.background == "wallpaper", "Invalid background was not sanitized")
        try require(model.rootOrder == ["app:/Applications/Alpha.app"], "Invalid root order was not sanitized")
    }

    private static func duplicateSavedGroupsAndPathsAreSanitized() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let groupID = UUID()
        let saved = [
            AppGroup(
                id: groupID,
                name: "\u{0000}Work\n" + String(repeating: "x", count: 100),
                appPaths: ["/Applications/Alpha.app", "/Applications/Alpha.app", "relative.app"]
            ),
            AppGroup(id: groupID, name: "Duplicate", appPaths: ["/Applications/Beta.app"]),
            AppGroup(name: "Empty", appPaths: ["not-an-app"])
        ]
        context.defaults.set(try JSONEncoder().encode(saved), forKey: "launcher.groups.v2")

        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        try require(model.groups.count == 1, "Duplicate or empty groups were not removed")
        guard let group = model.groups.first else { throw QualityTestFailure(description: "Sanitized group is missing") }
        try require(group.id == groupID, "Valid group ID was not preserved")
        try require(group.appPaths == ["/Applications/Alpha.app"], "Duplicate or invalid paths were not removed")
        try require(group.name.count <= 64, "Folder name length was not limited")
        try require(
            !group.name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
            "Control characters were not removed from the folder name"
        )
    }

    private static func duplicateRuntimeOrderDoesNotCrashOrLoseEntries() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        let alpha = AppItem(url: URL(fileURLWithPath: "/Applications/Alpha.app"))
        let beta = AppItem(url: URL(fileURLWithPath: "/Applications/Beta.app"))
        model.apps = [alpha, beta, alpha]
        model.rootOrder = [alpha.id, alpha.id, beta.id]
        try require(
            model.rootEntries.map(\.id) == [alpha.id, alpha.id, beta.id],
            "Duplicate runtime order lost an entry"
        )
    }

    private static func dropInputValidationRejectsUnknownIdentifiers() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        let alpha = AppItem(url: URL(fileURLWithPath: "/Applications/Alpha.app"))
        let beta = AppItem(url: URL(fileURLWithPath: "/Applications/Beta.app"))
        model.apps = [alpha, beta]
        model.handleDrop(alpha.id, on: .app(beta))
        guard let group = model.groups.first else { throw QualityTestFailure(description: "Valid drop did not create a folder") }
        model.open(group)
        let originalPaths = group.appPaths

        model.addToOpenGroup("app:/tmp/Injected.app")
        model.moveOutOfOpenGroup("app:/tmp/Injected.app")
        model.reorder("invalid", beside: alpha.id, after: true)
        try require(model.groups.first?.appPaths == originalPaths, "Invalid drop data changed the folder")
        try require(!model.rootOrder.contains("app:/tmp/Injected.app"), "Invalid drop data entered the saved order")
    }

    private static func folderLifecyclePersistsSafely() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        let first = AppItem(url: URL(fileURLWithPath: "/Applications/First.app"))
        let second = AppItem(url: URL(fileURLWithPath: "/Applications/Second.app"))
        model.apps = [first, second]

        model.handleDrop(first.id, on: .app(second))
        guard let createdGroup = model.groups.first else {
            throw QualityTestFailure(description: "Folder creation failed")
        }
        try require(
            model.apps(in: createdGroup).map(\.url.path) == [second.url.path, first.url.path],
            "Folder row order was not preserved"
        )

        model.renameGroup(createdGroup.id, to: "Work\n")
        model.finalizeGroupName(createdGroup.id)
        guard let savedData = context.defaults.data(forKey: "launcher.groups.v2") else {
            throw QualityTestFailure(description: "Folder data was not saved")
        }
        let savedGroups = try JSONDecoder().decode([AppGroup].self, from: savedData)
        guard let savedGroup = savedGroups.first else {
            throw QualityTestFailure(description: "Saved folder is missing")
        }
        try require(savedGroup.name == "Work", "Sanitized folder name was not persisted")

        model.open(createdGroup)
        model.reorderInOpenGroup(first.id, before: second.id)
        try require(
            model.groups.first?.appPaths == [first.url.path, second.url.path],
            "Folder reordering failed"
        )
        model.moveOutOfOpenGroup(first.id)
        try require(model.rootEntries.contains(.app(first)), "Removed app did not return to the root page")
        try require(model.groups.isEmpty, "A folder with one remaining application was not dissolved")
        try require(model.openGroupID == nil, "A dissolved folder remained open")
    }

    private static func folderRemovalMatchesNativeLifecycle() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        let first = AppItem(url: URL(fileURLWithPath: "/Applications/First.app"))
        let second = AppItem(url: URL(fileURLWithPath: "/Applications/Second.app"))
        let third = AppItem(url: URL(fileURLWithPath: "/Applications/Third.app"))
        model.apps = [first, second, third]

        model.handleDrop(first.id, on: .app(second))
        guard let createdGroup = model.groups.first else {
            throw QualityTestFailure(description: "Folder creation failed")
        }
        model.addToOpenGroup(third.id)
        model.moveOutOfOpenGroup(first.id)
        try require(model.groups.first?.appPaths.count == 2, "A two-application folder was dissolved too early")
        try require(model.openGroupID == createdGroup.id, "A valid folder was closed too early")

        model.moveOutOfOpenGroup(second.id)
        try require(model.groups.isEmpty, "The folder was not dissolved when one application remained")
        try require(model.openGroupID == nil, "The dissolved folder remained open")
        try require(
            Set(model.rootEntries.map(\.id)) == Set([first.id, second.id, third.id]),
            "Dissolving the folder lost an application"
        )
    }

    private static func folderRenameControlsPersistExplicitly() async throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        let first = AppItem(url: URL(fileURLWithPath: "/Applications/First.app"))
        let second = AppItem(url: URL(fileURLWithPath: "/Applications/Second.app"))
        model.apps = [first, second]
        let group = AppGroup(name: "Folder", appPaths: [first.url.path, second.url.path])
        model.groups = [group]

        _ = NSApplication.shared
        let parentWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: .titled,
            backing: .buffered,
            defer: false
        )
        parentWindow.makeKeyAndOrderFront(nil)
        defer { parentWindow.orderOut(nil) }

        let coordinator = FolderRenamePanelCoordinator()
        coordinator.present(
            groupID: group.id,
            currentName: group.name,
            model: model,
            parentWindow: parentWindow
        )
        await Task.yield()
        guard let savePanel = coordinator.activePanel,
              let saveField = coordinator.activeTextField else {
            throw QualityTestFailure(description: "The native folder rename panel did not open")
        }
        try require(savePanel.isVisible, "The folder rename panel was not visible")
        try require(saveField.stringValue == "Folder", "The rename panel did not show the current name")
        saveField.stringValue = "Projects"
        coordinator.saveRename()
        await Task.yield()

        try require(model.group(for: group.id)?.name == "Projects", "The edited folder name was not applied")
        try require(!coordinator.isPresenting, "The rename panel remained open after saving")
        try require(coordinator.activePanel == nil, "The saved rename panel was retained")

        guard let savedData = context.defaults.data(forKey: "launcher.groups.v2"),
              let savedGroup = try JSONDecoder().decode([AppGroup].self, from: savedData).first else {
            throw QualityTestFailure(description: "The explicitly saved folder name was not persisted")
        }
        try require(savedGroup.name == "Projects", "The persisted folder name did not match the edit")

        coordinator.present(
            groupID: group.id,
            currentName: savedGroup.name,
            model: model,
            parentWindow: parentWindow
        )
        await Task.yield()
        guard coordinator.activePanel != nil,
              let cancelField = coordinator.activeTextField else {
            throw QualityTestFailure(description: "The cancel rename panel did not open")
        }
        cancelField.stringValue = "Discarded"
        coordinator.cancelRename()
        await Task.yield()

        try require(model.group(for: group.id)?.name == "Projects", "Cancel unexpectedly changed the folder name")
        try require(!coordinator.isPresenting, "The rename panel remained open after cancelling")

        coordinator.present(
            groupID: group.id,
            currentName: savedGroup.name,
            model: model,
            parentWindow: parentWindow
        )
        guard let blankField = coordinator.activeTextField else {
            throw QualityTestFailure(description: "The blank-name rename panel did not open")
        }
        blankField.stringValue = "   "
        coordinator.saveRename()
        try require(
            model.group(for: group.id)?.name == model.text("Folder", "フォルダ"),
            "A blank folder name did not use the localized fallback"
        )
    }

    private static func pageNavigationHandlesIntegerBoundaries() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        model.setPageCount(3)
        model.changePage(by: Int.max)
        try require(model.currentPage == 2, "Positive page overflow was not clamped")
        model.changePage(by: Int.min)
        try require(model.currentPage == 0, "Negative page overflow was not clamped")

        model.setFolderPageCount(4)
        model.openGroupID = UUID()
        model.navigateVisiblePages(by: Int.max)
        try require(model.folderPage == 3, "Positive folder-page overflow was not clamped")
        model.navigateVisiblePages(by: Int.min)
        try require(model.folderPage == 0, "Negative folder-page overflow was not clamped")
    }

    private static func modalUIBlocksBackgroundPageNavigation() throws {
        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        model.setPageCount(3)

        model.showSettings = true
        model.navigateVisiblePages(by: 1)
        try require(model.currentPage == 0, "The page moved behind the Settings sheet")
        model.showSettings = false

        model.pendingDeleteApp = AppItem(url: URL(fileURLWithPath: "/Applications/Delete.app"))
        model.navigateVisiblePages(by: 1)
        try require(model.currentPage == 0, "The page moved behind the delete confirmation")
        model.pendingDeleteApp = nil

        model.errorMessage = "Test"
        model.navigateVisiblePages(by: 1)
        try require(model.currentPage == 0, "The page moved behind an error alert")
        model.errorMessage = nil

        model.navigateVisiblePages(by: 1)
        try require(model.currentPage == 1, "Page navigation did not resume after modal UI closed")
    }

    private static func dismissMotionMatchesReferenceApplication() throws {
        try require(
            abs(LaunchpadDismissMotion.duration - 0.25) < 0.000_1,
            "The launcher dismissal duration no longer matches the reference application"
        )
        try require(
            abs(LaunchpadDismissMotion.scale - 1.10) < 0.000_1,
            "The launcher dismissal scale no longer matches the reference application"
        )
        try require(
            LaunchpadDismissMotion.shouldAnimate(
                requested: true,
                applicationIsActive: true,
                reduceMotion: false,
                windowIsVisible: true
            ),
            "A visible active launcher did not enable its dismissal animation"
        )
        try require(
            !LaunchpadDismissMotion.shouldAnimate(
                requested: true,
                applicationIsActive: true,
                reduceMotion: true,
                windowIsVisible: true
            ),
            "Reduce Motion did not suppress the dismissal animation"
        )
        try require(
            !LaunchpadDismissMotion.shouldAnimate(
                requested: true,
                applicationIsActive: false,
                reduceMotion: false,
                windowIsVisible: true
            ),
            "An inactive launcher attempted to animate its dismissal"
        )
    }

    private static func referenceIconSizingMatchesAttachedApp() throws {
        try require(
            LauncherModel.referenceDefaultIconSize(pageWidth: 1_000) == 72,
            "Reference icon size did not honor its 72-point minimum"
        )
        try require(
            abs(LauncherModel.referenceDefaultIconSize(pageWidth: 1_430) - 92.95) < 0.001,
            "Reference icon size did not follow the enlarged screen-width formula"
        )
        try require(
            LauncherModel.referenceDefaultIconSize(pageWidth: 1_800) == 112,
            "Reference icon size did not honor its 112-point maximum"
        )

        let context = try makeDefaults()
        defer { context.defaults.removePersistentDomain(forName: context.domain) }
        let model = LauncherModel(defaults: context.defaults, autoScan: false)
        model.applyReferenceDefaultIconSize(pageWidth: 1_800)
        try require(model.iconSize == 112, "A fresh install did not use the enlarged default icon size")
        model.setIconSize(80)
        model.applyReferenceDefaultIconSize(pageWidth: 1_000)
        try require(model.iconSize == 80, "A saved user icon size was overwritten by the automatic default")

        let legacyContext = try makeDefaults()
        defer { legacyContext.defaults.removePersistentDomain(forName: legacyContext.domain) }
        legacyContext.defaults.set(96, forKey: "iconSize")
        let migratedModel = LauncherModel(defaults: legacyContext.defaults, autoScan: false)
        try require(migratedModel.iconSize == 112, "The previous 96-point maximum was not migrated to 112 points")
    }

    private static func rootGridUsesAvailableScreenSpace() throws {
        let screenshotLayout = RootGridMetrics.calculate(
            containerWidth: 1_848,
            containerHeight: 956,
            preferredIconSize: 112
        )
        try require(screenshotLayout.columnCount == 7, "The screenshot layout did not keep seven columns")
        try require(screenshotLayout.rowCount == 5, "The screenshot layout did not keep five rows")
        try require(screenshotLayout.capacity == 35, "The screenshot page capacity was incorrect")
        try require(screenshotLayout.iconSize == 112, "The enlarged icon size was not preserved")
        let bottomInset = 956 - RootGridMetrics.bottomReserve
            - screenshotLayout.topInset - screenshotLayout.gridHeight
        try require(abs(bottomInset - screenshotLayout.topInset) < 0.001, "The root grid was not vertically balanced")

        let compactLayout = RootGridMetrics.calculate(
            containerWidth: 760,
            containerHeight: 472,
            preferredIconSize: 112
        )
        try require(compactLayout.columnCount == 4, "The compact layout did not reduce its column count")
        try require(compactLayout.rowCount == 2, "The compact layout did not reduce its row count")
        try require(
            compactLayout.topInset + compactLayout.gridHeight + RootGridMetrics.bottomReserve <= 472,
            "The compact root grid overflowed its page"
        )

        let extremeLayout = RootGridMetrics.calculate(
            containerWidth: .greatestFiniteMagnitude,
            containerHeight: .greatestFiniteMagnitude,
            preferredIconSize: .greatestFiniteMagnitude
        )
        try require(extremeLayout.capacity == 35, "Extreme root geometry was not safely bounded")
    }

    private static func folderGridMetricsNeverOverflowTheirPanel() throws {
        let singleRowLayout = FolderGridMetrics.calculate(
            containerWidth: 1_822,
            containerHeight: 992,
            iconSize: 92,
            itemCount: 4
        )
        try require(singleRowLayout.columnCount == 4, "A four-application folder kept unused columns")
        try require(singleRowLayout.rowCount == 1, "A four-application folder kept unused rows")
        try require(singleRowLayout.capacity == 4, "The single-row folder capacity was incorrect")
        try require(singleRowLayout.pageCount == 1, "A four-application folder unexpectedly added pages")
        try require(singleRowLayout.panelHeight == 206, "The four-application folder canvas was not compact")
        try require(folderGridFits(singleRowLayout), "The single-row folder grid overflowed its panel")

        let multiPageLayout = FolderGridMetrics.calculate(
            containerWidth: 1_822,
            containerHeight: 992,
            iconSize: 92,
            itemCount: 50
        )
        try require(multiPageLayout.columnCount == 7, "The large folder did not use seven columns")
        try require(multiPageLayout.rowCount == 3, "The large folder did not fit three rows")
        try require(multiPageLayout.capacity == 21, "The large folder page capacity was incorrect")
        try require(multiPageLayout.pageCount == 3, "The large folder page count was incorrect")
        try require(
            multiPageLayout.panelHeight > singleRowLayout.panelHeight,
            "Folder canvas height did not grow with its application count"
        )
        try require(folderGridFits(multiPageLayout), "The large folder grid overflowed its panel")

        let compactLayout = FolderGridMetrics.calculate(
            containerWidth: 760,
            containerHeight: 540,
            iconSize: 96,
            itemCount: 20
        )
        try require(compactLayout.rowCount == 1, "A compact folder incorrectly forced multiple rows")
        try require(folderGridFits(compactLayout), "The compact folder grid overflowed its panel")

        let invalidLayout = FolderGridMetrics.calculate(
            containerWidth: .nan,
            containerHeight: .infinity,
            iconSize: .nan,
            itemCount: Int.min
        )
        try require(invalidLayout.capacity > 0, "Invalid geometry produced an unusable folder capacity")
        try require(folderGridFits(invalidLayout), "Invalid geometry produced an overflowing folder layout")

        let extremeLayout = FolderGridMetrics.calculate(
            containerWidth: .greatestFiniteMagnitude,
            containerHeight: .greatestFiniteMagnitude,
            iconSize: .greatestFiniteMagnitude,
            itemCount: Int.max
        )
        try require(extremeLayout.columnCount == 7, "Extreme geometry was not safely bounded")
        try require(folderGridFits(extremeLayout), "Extreme geometry produced an overflowing folder layout")
    }

    private static func folderGridFits(_ metrics: FolderGridMetrics) -> Bool {
        let reservedHeight = FolderGridMetrics.headerHeight
            + FolderGridMetrics.verticalPadding
            + FolderGridMetrics.sectionSpacing
            + (metrics.pageCount > 1
                ? FolderGridMetrics.pageIndicatorHeight + FolderGridMetrics.sectionSpacing
                : 0)
        return metrics.gridHeight + reservedHeight <= metrics.panelHeight + 0.001
    }

    private static func pageWindowLimitsRenderedPages() throws {
        try require(
            LaunchpadPageMotion.visiblePages(currentPage: 50, pageCount: 100) == [49, 50, 51],
            "The pager rendered more than the adjacent pages"
        )
        try require(
            LaunchpadPageMotion.visiblePages(currentPage: 0, pageCount: 100) == [0, 1],
            "The first page window was incorrect"
        )
        try require(
            LaunchpadPageMotion.visiblePages(currentPage: 99, pageCount: 100) == [98, 99],
            "The final page window was incorrect"
        )
        try require(
            LaunchpadPageMotion.visiblePages(currentPage: Int.max, pageCount: 0) == [0],
            "Invalid page state was not clamped safely"
        )
    }

    private static func scannerGracefullyHandlesMissingRoots() throws {
        let missingRoot = URL(fileURLWithPath: "/tmp/launcherx-missing-\(UUID().uuidString)")
        let result = LauncherFileScanner.scanApplications(in: [missingRoot])
        try require(result.apps.isEmpty, "Missing scan root produced applications")
        try require(result.accessibleRootCount == 0, "Missing scan root was marked accessible")
    }

    private static func imageLoadersHandleMissingFiles() async throws {
        let missingApp = URL(fileURLWithPath: "/tmp/launcherx-missing-\(UUID().uuidString).app")
        let icon = await LauncherIconLoader().icon(for: missingApp)
        try require(icon.size.width > 0 && icon.size.height > 0, "Missing app path did not return a safe placeholder icon")
        try require(icon.size == NSSize(width: 512, height: 512), "The app icon was not normalized for stable rendering")

        let fakeApp = FileManager.default.temporaryDirectory
            .appendingPathComponent("launcherx-icon-\(UUID().uuidString).app", isDirectory: true)
        let contents = fakeApp.appendingPathComponent("Contents", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: fakeApp)
            } catch {
                FileHandle.standardError.write(
                    Data("Could not remove test app: \(error.localizedDescription)\n".utf8)
                )
            }
        }
        let infoData = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleIconFile": "AppIcon.png"],
            format: .xml,
            options: 0
        )
        try infoData.write(to: contents.appendingPathComponent("Info.plist"), options: .atomic)
        guard let testIconData = makeTestIconData() else {
            throw QualityTestFailure(description: "Could not create a test app icon")
        }
        try testIconData.write(
            to: resources.appendingPathComponent("AppIcon.png"),
            options: .atomic
        )
        let bundleIcon = await LauncherIconLoader().icon(for: fakeApp)
        try require(
            bundleIcon.size == NSSize(width: 512, height: 512),
            "A bundle icon was not normalized for stable rendering"
        )
        var proposedRect = NSRect(origin: .zero, size: bundleIcon.size)
        guard let bundleCGImage = bundleIcon.cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
        ),
        let bundlePixels = bundleCGImage.dataProvider?.data as Data? else {
            throw QualityTestFailure(description: "The normalized bundle icon had no pixel data")
        }
        try require(
            bundlePixels.contains(where: { $0 != 0 }),
            "The normalized bundle icon was transparent"
        )

        let missingWallpaper = URL(fileURLWithPath: "/tmp/launcherx-missing-\(UUID().uuidString).png")
        let image = await LauncherBackgroundImageLoader().image(for: missingWallpaper)
        try require(image == nil, "Missing wallpaper unexpectedly produced an image")
    }

    private static func makeTestIconData() -> Data? {
        let dimension = 32
        guard let context = CGContext(
            data: nil,
            width: dimension,
            height: dimension,
            bitsPerComponent: 8,
            bytesPerRow: dimension * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: dimension, height: dimension))
        guard let cgImage = context.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])
    }

    private static func fileOperatorRejectsUnsafeDeleteLocation() async throws {
        let fileOperator = LauncherFileOperator()
        let outcome = await fileOperator.moveApplicationToTrash(
            URL(fileURLWithPath: "/System/Applications/Finder.app"),
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        guard case .failure = outcome else {
            throw QualityTestFailure(description: "A system application was accepted for deletion")
        }
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ description: String) throws {
        guard condition() else { throw QualityTestFailure(description: description) }
    }

    private static func makeDefaults() throws -> (defaults: UserDefaults, domain: String) {
        let domain = "jp.local.launchpadclassic.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: domain) else {
            throw QualityTestFailure(description: "Could not create isolated UserDefaults")
        }
        defaults.removePersistentDomain(forName: domain)
        return (defaults, domain)
    }
}
