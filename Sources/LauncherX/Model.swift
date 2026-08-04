import SwiftUI
import AppKit
import QuartzCore

struct AppItem: Identifiable, Hashable, Sendable {
    let url: URL
    let category: String?
    let isDeletable: Bool
    init(url: URL, category: String? = nil, isDeletable: Bool = false) {
        self.url = url; self.category = category; self.isDeletable = isDeletable
    }
    var id: String { "app:" + url.path }
    var name: String { url.deletingPathExtension().lastPathComponent }
}

struct WallpaperItem: Identifiable, Hashable, Sendable {
    let url: URL
    var id: String { url.path }
    var name: String { url.deletingPathExtension().lastPathComponent }
}

struct AppGroup: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var appPaths: [String]
    var systemKind: String? = nil
}

enum LauncherEntry: Identifiable, Hashable, Sendable {
    case app(AppItem)
    case group(AppGroup)
    var id: String {
        switch self {
        case .app(let app): app.id
        case .group(let group): "group:" + group.id.uuidString
        }
    }
}

enum LaunchpadPageMotion {
    static let maximumVelocity = 4_000.0
    static let velocityProjectionDuration = 0.32
    static let pageDecisionRatio = 0.15
    static let standardDuration = 0.34
    static let minimumDuration = 0.22

    static func animation(initialVelocity: Double = 0) -> Animation {
        let safeVelocity = initialVelocity.isFinite
            ? min(max(initialVelocity, 0), maximumVelocity)
            : 0
        let velocityReduction = min(safeVelocity * 0.025, standardDuration - minimumDuration)
        return .timingCurve(
            0.20,
            0.82,
            0.20,
            1.00,
            duration: standardDuration - velocityReduction
        )
    }

    static func normalizedInitialVelocity(
        translation: CGFloat,
        projectedTranslation: CGFloat,
        pageWidth: CGFloat
    ) -> Double {
        guard pageWidth.isFinite, pageWidth > 0 else { return 0 }
        let projectedDelta = Double(abs(projectedTranslation - translation))
        let pointsPerSecond = min(projectedDelta / velocityProjectionDuration, maximumVelocity)
        return pointsPerSecond / Double(pageWidth)
    }

    nonisolated static func visiblePages(currentPage: Int, pageCount: Int) -> [Int] {
        let safePageCount = max(1, pageCount)
        let safeCurrentPage = min(max(0, currentPage), safePageCount - 1)
        let firstPage = max(0, safeCurrentPage - 1)
        let lastPage = min(safePageCount - 1, safeCurrentPage + 1)
        return Array(firstPage...lastPage)
    }
}

enum LaunchpadDismissMotion {
    static let duration = 0.25
    static let scale = 1.10

    nonisolated static func shouldAnimate(
        requested: Bool,
        applicationIsActive: Bool,
        reduceMotion: Bool,
        windowIsVisible: Bool
    ) -> Bool {
        requested && applicationIsActive && !reduceMotion && windowIsVisible
    }
}

struct FolderGridMetrics: Equatable, Sendable {
    static let headerHeight = 42.0
    static let pageIndicatorHeight = 26.0
    static let verticalPadding = 36.0
    static let sectionSpacing = 12.0
    static let rowSpacing = 20.0

    let columnCount: Int
    let rowCount: Int
    let capacity: Int
    let cellWidth: Double
    let gridWidth: Double
    let gridHeight: Double
    let panelHeight: Double
    let pageCount: Int

    nonisolated static func calculate(
        containerWidth: Double,
        containerHeight: Double,
        iconSize: Double,
        itemCount: Int
    ) -> FolderGridMetrics {
        let safeWidth = containerWidth.isFinite ? min(max(760, containerWidth), 100_000) : 760
        let safeHeight = containerHeight.isFinite ? min(max(540, containerHeight), 100_000) : 540
        let safeIconSize = iconSize.isFinite ? min(max(iconSize, 60), 112) : 92
        let safeItemCount = min(max(0, itemCount), 1_000_000)
        let horizontalPanelPadding = 140.0
        let columnSpacing = 20.0
        let availableGridWidth = max(1, safeWidth - horizontalPanelPadding)
        let cellWidth = safeIconSize + 120
        let possibleColumns = Int((availableGridWidth + columnSpacing) / (cellWidth + columnSpacing))
        let maximumColumnCount = max(1, min(7, possibleColumns))
        let columnCount = min(maximumColumnCount, max(1, safeItemCount))
        let gridWidth = (Double(columnCount) * cellWidth)
            + (Double(max(0, columnCount - 1)) * columnSpacing)

        let heightClearance = min(120, safeHeight * 0.18)
        let heightLimit = max(1, safeHeight - heightClearance)
        let maximumPanelHeight = min(heightLimit, min(620, max(280, safeHeight * 0.58)))
        let maximumReservedHeight = headerHeight + pageIndicatorHeight
            + verticalPadding + (sectionSpacing * 2)
        let availableGridHeight = max(1, maximumPanelHeight - maximumReservedHeight)
        let itemHeight = safeIconSize + 24
        let possibleRows = Int((availableGridHeight + rowSpacing) / (itemHeight + rowSpacing))
        let maximumRowCount = max(1, min(3, possibleRows))
        let requiredRows = Int(ceil(Double(max(1, safeItemCount)) / Double(columnCount)))
        let rowCount = min(maximumRowCount, max(1, requiredRows))
        let capacity = max(1, columnCount * rowCount)
        let pageCount = max(1, Int(ceil(Double(safeItemCount) / Double(capacity))))
        let gridHeight = (Double(rowCount) * itemHeight)
            + (Double(max(0, rowCount - 1)) * rowSpacing)
        let indicatorHeight = pageCount > 1 ? pageIndicatorHeight + sectionSpacing : 0
        let panelHeight = verticalPadding + headerHeight + sectionSpacing + gridHeight + indicatorHeight

        return FolderGridMetrics(
            columnCount: columnCount,
            rowCount: rowCount,
            capacity: capacity,
            cellWidth: cellWidth,
            gridWidth: gridWidth,
            gridHeight: gridHeight,
            panelHeight: min(maximumPanelHeight, panelHeight),
            pageCount: pageCount
        )
    }
}

struct RootGridMetrics: Equatable, Sendable {
    static let maximumColumns = 7
    static let maximumRows = 5
    static let columnSpacing = 16.0
    static let rowSpacing = 20.0
    static let labelHeight = 24.0
    static let dragTargetWidth = 28.0
    static let minimumTopInset = 24.0
    static let bottomReserve = 64.0

    let columnCount: Int
    let rowCount: Int
    let capacity: Int
    let iconSize: Double
    let horizontalPadding: Double
    let gridHeight: Double
    let topInset: Double

    nonisolated static func calculate(
        containerWidth: Double,
        containerHeight: Double,
        preferredIconSize: Double
    ) -> RootGridMetrics {
        let safeWidth = containerWidth.isFinite ? min(max(760, containerWidth), 100_000) : 1_440
        let safeHeight = containerHeight.isFinite ? min(max(1, containerHeight), 100_000) : 760
        let iconSize = preferredIconSize.isFinite ? min(max(preferredIconSize, 60), 112) : 92
        let horizontalPadding = max(42, min(180, safeWidth * 0.055))
        let availableWidth = max(1, safeWidth - (horizontalPadding * 2))
        let requiredCellWidth = iconSize + dragTargetWidth
        let possibleColumns = Int(
            (availableWidth + columnSpacing) / (requiredCellWidth + columnSpacing)
        )
        let columnCount = max(1, min(maximumColumns, possibleColumns))

        let itemHeight = iconSize + labelHeight
        let availableHeight = max(1, safeHeight - minimumTopInset - bottomReserve)
        let possibleRows = Int((availableHeight + rowSpacing) / (itemHeight + rowSpacing))
        let rowCount = max(1, min(maximumRows, possibleRows))
        let gridHeight = (Double(rowCount) * itemHeight)
            + (Double(max(0, rowCount - 1)) * rowSpacing)
        let centeredTopInset = (safeHeight - bottomReserve - gridHeight) / 2
        let topInset = max(minimumTopInset, centeredTopInset)

        return RootGridMetrics(
            columnCount: columnCount,
            rowCount: rowCount,
            capacity: max(1, columnCount * rowCount),
            iconSize: iconSize,
            horizontalPadding: horizontalPadding,
            gridHeight: gridHeight,
            topInset: topInset
        )
    }
}

@MainActor final class LauncherModel: ObservableObject {
    @Published var apps: [AppItem] = []
    @Published var groups: [AppGroup] = [] { didSet { saveGroups() } }
    @Published var search = "" { didSet {
        let cleaned = Self.sanitizedSearch(search)
        if cleaned != search { search = cleaned; return }
        if oldValue != search { currentPage = 0 }
    } }
    @Published var showSettings = false
    @Published var openGroupID: UUID?
    @Published var currentPage = 0
    @Published var pageCount = 1
    @Published var folderPage = 0
    @Published var folderPageCount = 1
    @Published var rootOrder: [String] = [] { didSet { saveOrder() } }
    @Published var wallpapers: [WallpaperItem] = []
    @Published private(set) var selectedBackgroundImage: NSImage?
    @Published var pendingDeleteApp: AppItem?
    @Published private(set) var isScanning = false
    @Published private(set) var isDeleting = false
    @Published private(set) var isDismissing = false
    @Published var errorMessage: String?
    @Published var language: String { didSet {
        let cleaned = Self.sanitizedLanguage(language)
        if cleaned != language { language = cleaned; return }
        defaults.set(language, forKey: "language")
    } }
    @Published var background: String { didSet {
        let cleaned = Self.sanitizedBackground(background)
        if cleaned != background { background = cleaned; return }
        defaults.set(background, forKey: "background")
        refreshBackgroundImage()
    } }
    @Published var iconSize: Double { didSet {
        let cleaned = Self.sanitizedIconSize(iconSize)
        if cleaned != iconSize { iconSize = cleaned; return }
        if isApplyingReferenceIconSize { return }
        usesReferenceIconSize = false
        defaults.set(iconSize, forKey: "iconSize")
    } }

    private let groupsKey = "launcher.groups.v2"
    private let orderKey = "launcher.order.v1"
    private let defaultsKey = "launcher.defaultGroups.v1"
    private let displayVersionKey = "launcher.display.version"
    private let defaults: UserDefaults
    private let applicationScanner = LauncherFileScanner()
    private let wallpaperScanner = LauncherFileScanner()
    private let fileOperator = LauncherFileOperator()
    private let iconLoader = LauncherIconLoader()
    private let backgroundImageLoader = LauncherBackgroundImageLoader()
    private var applicationScanTask: Task<Void, Never>?
    private var wallpaperScanTask: Task<Void, Never>?
    private var deleteTask: Task<Void, Never>?
    private var backgroundLoadTask: Task<Void, Never>?
    private var requestedBackgroundPath: String?
    private var presentationRequestID: UUID?
    private var dismissalRequestID: UUID?
    private var usesReferenceIconSize = true
    private var isApplyingReferenceIconSize = false

    init(defaults: UserDefaults = .standard, autoScan: Bool = true) {
        self.defaults = defaults
        language = Self.sanitizedLanguage(defaults.string(forKey: "language"))
        if let storedNumber = defaults.object(forKey: "iconSize") as? NSNumber,
           storedNumber.doubleValue.isFinite {
            let storedSize = storedNumber.doubleValue
            let needsLegacyMaximumMigration = defaults.integer(forKey: displayVersionKey) < 2
                && abs(storedSize - 96) < 0.001
            iconSize = Self.sanitizedIconSize(needsLegacyMaximumMigration ? 112 : storedSize)
            usesReferenceIconSize = false
        } else {
            iconSize = 92
            usesReferenceIconSize = true
            defaults.removeObject(forKey: "iconSize")
        }
        defaults.set(2, forKey: displayVersionKey)
        background = Self.sanitizedBackground(defaults.string(forKey: "background") ?? "wallpaper")
        if let data = defaults.data(forKey: groupsKey), data.count <= 2_000_000,
           let saved = try? JSONDecoder().decode([AppGroup].self, from: data) {
            groups = Self.sanitizedGroups(saved)
        }
        rootOrder = Self.sanitizedOrder(defaults.stringArray(forKey: orderKey) ?? [])
        if autoScan {
            scanWallpapers()
            scan()
        }
        refreshBackgroundImage()
    }

    var isJapanese: Bool {
        language == "ja" || (language == "system" && Locale.preferredLanguages.first?.hasPrefix("ja") == true)
    }
    func text(_ en: String, _ ja: String) -> String { isJapanese ? ja : en }

    var rootEntries: [LauncherEntry] {
        if !search.isEmpty {
            return apps.filter { $0.name.localizedCaseInsensitiveContains(search) }.map(LauncherEntry.app)
        }
        let grouped = Set(groups.flatMap(\.appPaths))
        let availablePaths = Set(apps.map(\.url.path))
        let folders = groups.filter { group in
            group.appPaths.contains(where: availablePaths.contains)
        }.map(LauncherEntry.group)
        let looseApps = apps.filter { !grouped.contains($0.url.path) }.map(LauncherEntry.app)
        let entries = folders + looseApps
        var rank: [String: Int] = [:]
        for (offset, identifier) in rootOrder.enumerated() where rank[identifier] == nil {
            rank[identifier] = offset
        }
        return entries.enumerated().sorted {
            let left = rank[$0.element.id] ?? (rootOrder.count + $0.offset)
            let right = rank[$1.element.id] ?? (rootOrder.count + $1.offset)
            return left < right
        }.map(\.element)
    }

    func apps(in group: AppGroup) -> [AppItem] {
        var byPath: [String: AppItem] = [:]
        for app in apps where byPath[app.url.path] == nil { byPath[app.url.path] = app }
        return group.appPaths.compactMap { byPath[$0] }
    }

    func loadIcon(for app: AppItem) async -> NSImage {
        await iconLoader.icon(for: app.url)
    }

    func scan() {
        applicationScanTask?.cancel()
        isScanning = true
        let scanner = applicationScanner
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        applicationScanTask = Task { [weak self] in
            let result = await scanner.scanApplications(homeDirectory: homeDirectory)
            guard !Task.isCancelled, let self else { return }
            self.applicationScanTask = nil
            self.isScanning = false
            guard result.accessibleRootCount > 0 else {
                self.presentError(
                    en: "The Applications folders could not be read.",
                    ja: "アプリケーションフォルダを読み込めませんでした。"
                )
                return
            }
            self.apps = result.apps
            self.removeMissingApplicationsFromOpenState()
            self.bootstrapDefaultGroupsIfNeeded()
            self.syncNewGames()
        }
    }

    func scanWallpapers() {
        wallpaperScanTask?.cancel()
        let scanner = wallpaperScanner
        wallpaperScanTask = Task { [weak self] in
            let discovered = await scanner.scanWallpapers()
            guard !Task.isCancelled, let self else { return }
            self.wallpaperScanTask = nil
            self.wallpapers = discovered
            if self.background.hasPrefix("file:") {
                let selectedPath = String(self.background.dropFirst(5))
                if !discovered.contains(where: { $0.url.path == selectedPath }) {
                    self.background = "wallpaper"
                }
            }
        }
    }

    func launch(_ app: AppItem) {
        guard apps.contains(where: { $0.id == app.id }),
              app.url.isFileURL,
              app.url.pathExtension.lowercased() == "app" else {
            presentError(en: "This application is no longer available.", ja: "このアプリケーションは利用できません。")
            return
        }
        dismissLauncher()
        NSWorkspace.shared.openApplication(at: app.url, configuration: .init()) { [weak self] _, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.restoreLauncherAfterFailedLaunch()
                    self.presentError(
                        en: "The application could not be opened: \(error.localizedDescription)",
                        ja: "アプリケーションを開けませんでした: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    func open(_ group: AppGroup) {
        guard groups.contains(where: { $0.id == group.id }) else { return }
        folderPage = 0
        openGroupID = group.id
    }
    func dismissLauncher(animated: Bool = true) {
        guard dismissalRequestID == nil else { return }
        presentationRequestID = nil
        guard let window = launcherWindow(), window.isVisible else {
            NSApp.presentationOptions = []
            return
        }

        let requestID = UUID()
        dismissalRequestID = requestID
        isDismissing = true
        let shouldAnimate = LaunchpadDismissMotion.shouldAnimate(
            requested: animated,
            applicationIsActive: NSApp.isActive,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            windowIsVisible: window.isVisible
        )
        guard shouldAnimate else {
            finishLauncherDismissal(requestID: requestID, window: window)
            return
        }
        animateLauncherDismissal(requestID: requestID, window: window)
    }

    func handleApplicationDidResignActive() {
        guard !showSettings else { return }
        dismissLauncher(animated: false)
    }

    func handleApplicationDidHide() {
        presentationRequestID = nil
        isDismissing = false
        NSApp.presentationOptions = []
        if let window = launcherWindow() {
            resetLauncherWindowVisualState(window)
        }
    }
    func closeFolder() { openGroupID = nil; folderPage = 0; folderPageCount = 1 }
    func group(for id: UUID?) -> AppGroup? { groups.first { $0.id == id } }

    func renameGroup(_ id: UUID, to name: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = Self.sanitizedGroupName(name, allowEmpty: true, fallback: text("Folder", "フォルダ"))
    }

    func finalizeGroupName(_ id: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = Self.sanitizedGroupName(
            groups[index].name,
            allowEmpty: false,
            fallback: text("Folder", "フォルダ")
        )
    }

    func applyReferenceDefaultIconSize(pageWidth: Double) {
        guard usesReferenceIconSize else { return }
        let calculatedSize = Self.referenceDefaultIconSize(pageWidth: pageWidth)
        guard calculatedSize != iconSize else { return }
        isApplyingReferenceIconSize = true
        iconSize = calculatedSize
        isApplyingReferenceIconSize = false
    }

    func setIconSize(_ size: Double) { iconSize = Self.sanitizedIconSize(size) }
    func adjustIconSize(by amount: Double) { setIconSize(iconSize + amount) }

    func setPageCount(_ count: Int) {
        pageCount = max(1, count)
        currentPage = min(currentPage, pageCount - 1)
    }

    func goToPage(_ page: Int, initialVelocity: Double = 0) {
        let destination = min(max(0, page), pageCount - 1)
        guard destination != currentPage else { return }
        let animation = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            ? nil
            : LaunchpadPageMotion.animation(initialVelocity: initialVelocity)
        withAnimation(animation) {
            currentPage = destination
        }
    }

    func changePage(by delta: Int, initialVelocity: Double = 0) {
        let addition = currentPage.addingReportingOverflow(delta)
        goToPage(
            addition.overflow ? (delta > 0 ? Int.max : Int.min) : addition.partialValue,
            initialVelocity: initialVelocity
        )
    }

    func setFolderPageCount(_ count: Int) {
        folderPageCount = max(1, count)
        folderPage = min(folderPage, folderPageCount - 1)
    }

    func goToFolderPage(_ page: Int, initialVelocity: Double = 0) {
        let destination = min(max(0, page), folderPageCount - 1)
        guard destination != folderPage else { return }
        let animation = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            ? nil
            : LaunchpadPageMotion.animation(initialVelocity: initialVelocity)
        withAnimation(animation) {
            folderPage = destination
        }
    }

    func navigateVisiblePages(by delta: Int) {
        guard !showSettings, pendingDeleteApp == nil, errorMessage == nil else { return }
        if openGroupID == nil { changePage(by: delta) }
        else {
            let addition = folderPage.addingReportingOverflow(delta)
            goToFolderPage(addition.overflow ? (delta > 0 ? Int.max : Int.min) : addition.partialValue)
        }
    }

    func remove(_ app: AppItem, from group: AppGroup) {
        moveAppOut(app, from: group.id)
    }

    func handleDrop(_ sourceID: String, on target: LauncherEntry) {
        guard sourceID.count <= 4_200, sourceID != target.id,
              let source = entry(for: sourceID),
              let resolvedTarget = entry(for: target.id) else { return }
        switch (source, resolvedTarget) {
        case (.app(let sourceApp), .app(let targetApp)):
            let previousOrder = rootEntries.map(\.id)
            detachFromGroups(paths: [sourceApp.url.path, targetApp.url.path])
            let group = AppGroup(name: text("Folder", "フォルダ"), appPaths: [targetApp.url.path, sourceApp.url.path])
            groups.append(group)
            replaceOrderItems([targetApp.id, sourceApp.id], with: "group:" + group.id.uuidString, in: previousOrder)
            openGroupID = group.id
        case (.app(let sourceApp), .group(let targetGroup)):
            detachFromGroups(paths: [sourceApp.url.path])
            guard let index = groups.firstIndex(where: { $0.id == targetGroup.id }) else { break }
            if !groups[index].appPaths.contains(sourceApp.url.path) { groups[index].appPaths.append(sourceApp.url.path) }
        default: break
        }
    }

    func reorder(_ sourceID: String, beside targetID: String, after: Bool) {
        guard sourceID.count <= 4_200, targetID.count <= 4_200, sourceID != targetID else { return }
        var order = rootEntries.map(\.id)
        let validIDs = Set(order)
        guard validIDs.contains(sourceID), validIDs.contains(targetID) else { return }
        order.removeAll { $0 == sourceID }
        guard let targetIndex = order.firstIndex(of: targetID) else { return }
        order.insert(sourceID, at: min(order.count, targetIndex + (after ? 1 : 0)))
        rootOrder = order
    }

    func addToOpenGroup(_ sourceID: String) {
        guard sourceID.count <= 4_200, sourceID.hasPrefix("app:"),
              let sourceApp = apps.first(where: { $0.id == sourceID }),
              let groupID = openGroupID,
              let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let path = sourceApp.url.path
        guard !groups[index].appPaths.contains(path) else { return }
        detachFromGroups(paths: [path])
        guard let refreshedIndex = groups.firstIndex(where: { $0.id == groupID }) else { return }
        if !groups[refreshedIndex].appPaths.contains(path) { groups[refreshedIndex].appPaths.append(path) }
    }

    func moveOutOfOpenGroup(_ sourceID: String) {
        guard sourceID.count <= 4_200, sourceID.hasPrefix("app:"),
              let sourceApp = apps.first(where: { $0.id == sourceID }),
              let groupID = openGroupID else { return }
        moveAppOut(sourceApp, from: groupID)
    }

    func reorderInOpenGroup(_ sourceID: String, before targetID: String) {
        guard sourceID.count <= 4_200, targetID.count <= 4_200,
              sourceID.hasPrefix("app:"), targetID.hasPrefix("app:"), sourceID != targetID,
              let groupID = openGroupID, let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let sourcePath = String(sourceID.dropFirst(4))
        let targetPath = String(targetID.dropFirst(4))
        guard groups[index].appPaths.contains(sourcePath),
              let targetIndex = groups[index].appPaths.firstIndex(of: targetPath) else { return }
        groups[index].appPaths.removeAll { $0 == sourcePath }
        let insertion = min(targetIndex, groups[index].appPaths.count)
        groups[index].appPaths.insert(sourcePath, at: insertion)
    }

    func deletePendingApplication() {
        guard let app = pendingDeleteApp, app.isDeletable else { pendingDeleteApp = nil; return }
        pendingDeleteApp = nil
        deleteTask?.cancel()
        isDeleting = true
        let fileOperator = fileOperator
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        deleteTask = Task { [weak self] in
            let outcome = await fileOperator.moveApplicationToTrash(app.url, homeDirectory: homeDirectory)
            guard !Task.isCancelled, let self else { return }
            self.deleteTask = nil
            self.isDeleting = false
            switch outcome {
            case .success:
                self.scan()
            case .failure(let details):
                self.presentError(
                    en: "The application could not be moved to the Trash: \(details)",
                    ja: "アプリケーションをゴミ箱へ移動できませんでした: \(details)"
                )
            }
        }
    }

    func maximizeLauncherWindow() {
        dismissalRequestID = nil
        isDismissing = false
        let requestID = UUID()
        presentationRequestID = requestID
        configureLauncherWindow(requestID: requestID, remainingAttempts: 6)
    }

    private func configureLauncherWindow(requestID: UUID, remainingAttempts: Int) {
        guard presentationRequestID == requestID else { return }
        let mainWindow = launcherWindow()

        guard let window = mainWindow, let screen = window.screen ?? NSScreen.main else {
            guard remainingAttempts > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.configureLauncherWindow(
                    requestID: requestID,
                    remainingAttempts: remainingAttempts - 1
                )
            }
            return
        }

        NSApp.setActivationPolicy(.accessory)
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.toolbar = nil
        window.styleMask = [.borderless]
        window.hasShadow = false
        window.level = .floating
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.collectionBehavior.insert([.canJoinAllSpaces, .fullScreenAuxiliary])
        window.setFrame(screen.frame, display: true, animate: false)
        resetLauncherWindowVisualState(window)
        if background == "wallpaper" { refreshBackgroundImage(screen: screen) }
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate()
    }

    private func launcherWindow() -> NSWindow? {
        if let keyWindow = NSApp.keyWindow,
           keyWindow.sheetParent == nil,
           !(keyWindow is NSPanel) {
            return keyWindow
        }
        return NSApp.windows.first(where: { window in
            window.sheetParent == nil && !(window is NSPanel)
        })
    }

    private func animateLauncherDismissal(requestID: UUID, window: NSWindow) {
        let contentLayer = window.contentView.flatMap { contentView -> CALayer? in
            contentView.wantsLayer = true
            return contentView.layer
        }
        if let contentLayer {
            centerAnchorPoint(of: contentLayer)
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = LaunchpadDismissMotion.scale
            scaleAnimation.duration = LaunchpadDismissMotion.duration
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            contentLayer.transform = CATransform3DMakeScale(
                LaunchpadDismissMotion.scale,
                LaunchpadDismissMotion.scale,
                1
            )
            CATransaction.commit()
            contentLayer.add(scaleAnimation, forKey: "launchpad.dismiss.scale")
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = LaunchpadDismissMotion.duration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            Task { @MainActor [weak self, weak window] in
                guard let self, let window else { return }
                self.finishLauncherDismissal(requestID: requestID, window: window)
            }
        }
    }

    private func finishLauncherDismissal(requestID: UUID, window: NSWindow) {
        guard dismissalRequestID == requestID else { return }
        window.orderOut(nil)
        resetLauncherWindowVisualState(window)
        for childWindow in window.childWindows ?? [] {
            childWindow.close()
        }
        showSettings = false
        pendingDeleteApp = nil
        closeFolder()
        search = ""
        NSApp.presentationOptions = []
        dismissalRequestID = nil
        isDismissing = false
        NSApp.hide(nil)
    }

    private func restoreLauncherAfterFailedLaunch() {
        dismissalRequestID = nil
        isDismissing = false
        NSApp.unhide(nil)
        if let window = launcherWindow() {
            resetLauncherWindowVisualState(window)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
        NSApp.activate()
        maximizeLauncherWindow()
    }

    private func resetLauncherWindowVisualState(_ window: NSWindow) {
        window.alphaValue = 1
        guard let contentLayer = window.contentView?.layer else { return }
        contentLayer.removeAnimation(forKey: "launchpad.dismiss.scale")
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentLayer.transform = CATransform3DIdentity
        CATransaction.commit()
    }

    private func centerAnchorPoint(of layer: CALayer) {
        let centeredAnchor = CGPoint(x: 0.5, y: 0.5)
        guard layer.anchorPoint != centeredAnchor else { return }
        let oldPoint = CGPoint(
            x: layer.bounds.width * layer.anchorPoint.x,
            y: layer.bounds.height * layer.anchorPoint.y
        )
        let newPoint = CGPoint(
            x: layer.bounds.width * centeredAnchor.x,
            y: layer.bounds.height * centeredAnchor.y
        )
        var position = layer.position
        position.x += newPoint.x - oldPoint.x
        position.y += newPoint.y - oldPoint.y
        layer.position = position
        layer.anchorPoint = centeredAnchor
    }

    private func entry(for id: String) -> LauncherEntry? {
        if id.hasPrefix("app:"), let app = apps.first(where: { $0.id == id }) { return .app(app) }
        if id.hasPrefix("group:"), let uuid = UUID(uuidString: String(id.dropFirst(6))),
           let group = groups.first(where: { $0.id == uuid }) { return .group(group) }
        return nil
    }

    private func saveGroups() {
        do {
            let data = try JSONEncoder().encode(groups)
            defaults.set(data, forKey: groupsKey)
        } catch {
            presentError(
                en: "The folder arrangement could not be saved.",
                ja: "フォルダの構成を保存できませんでした。"
            )
        }
    }

    private func refreshBackgroundImage(screen: NSScreen? = nil) {
        backgroundLoadTask?.cancel()
        let imageURL: URL?
        if background.hasPrefix("file:") {
            imageURL = URL(fileURLWithPath: String(background.dropFirst(5)))
        } else if background == "wallpaper", let targetScreen = screen ?? NSScreen.main {
            imageURL = NSWorkspace.shared.desktopImageURL(for: targetScreen)
        } else {
            imageURL = nil
        }

        guard let imageURL else {
            requestedBackgroundPath = nil
            selectedBackgroundImage = nil
            return
        }
        let path = imageURL.standardizedFileURL.path
        if requestedBackgroundPath == path, selectedBackgroundImage != nil { return }
        requestedBackgroundPath = path
        selectedBackgroundImage = nil
        let loader = backgroundImageLoader
        backgroundLoadTask = Task { [weak self] in
            let image = await loader.image(for: imageURL)
            guard !Task.isCancelled, let self, self.requestedBackgroundPath == path else { return }
            self.backgroundLoadTask = nil
            self.selectedBackgroundImage = image
            if image == nil { self.requestedBackgroundPath = nil }
        }
    }
    private func saveOrder() { defaults.set(Self.sanitizedOrder(rootOrder), forKey: orderKey) }
    private func bootstrapDefaultGroupsIfNeeded() {
        guard !defaults.bool(forKey: defaultsKey) else { return }
        let alreadyGrouped = Set(groups.flatMap(\.appPaths))
        let utilities = apps.filter { $0.url.path.contains("/Utilities/") && !alreadyGrouped.contains($0.url.path) }
        let games = apps.filter { $0.category == "public.app-category.games" && !alreadyGrouped.contains($0.url.path) }
        if !utilities.isEmpty { groups.append(AppGroup(name: text("Utilities", "ユーティリティ"), appPaths: utilities.map(\.url.path), systemKind: "utilities")) }
        if !games.isEmpty { groups.append(AppGroup(name: text("Games", "ゲーム"), appPaths: games.map(\.url.path), systemKind: "games")) }
        defaults.set(true, forKey: defaultsKey)
    }
    private func syncNewGames() {
        let gamePaths = apps.filter { $0.category == "public.app-category.games" }.map(\.url.path)
        guard !gamePaths.isEmpty else { return }
        let grouped = Set(groups.flatMap(\.appPaths))
        let newPaths = gamePaths.filter { !grouped.contains($0) }
        guard !newPaths.isEmpty else { return }
        if let index = groups.firstIndex(where: { $0.systemKind == "games" }) {
            groups[index].appPaths.append(contentsOf: newPaths)
        } else {
            groups.append(AppGroup(name: text("Games", "ゲーム"), appPaths: newPaths, systemKind: "games"))
        }
    }
    private func detachFromGroups(paths: Set<String>) {
        for index in groups.indices { groups[index].appPaths.removeAll { paths.contains($0) } }
        groups.removeAll { $0.appPaths.isEmpty }
    }

    private func moveAppOut(_ sourceApp: AppItem, from groupID: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }),
              groups[index].appPaths.contains(sourceApp.url.path) else { return }

        let previousOrder = rootEntries.map(\.id)
        let folderID = "group:" + groupID.uuidString
        groups[index].appPaths.removeAll { $0 == sourceApp.url.path }

        var replacements = [folderID, sourceApp.id]
        let remainingApps = apps(in: groups[index])
        if remainingApps.count <= 1 {
            groups.remove(at: index)
            replacements = remainingApps.map(\.id) + [sourceApp.id]
            if openGroupID == groupID { closeFolder() }
        }

        var order = previousOrder
        let insertion = order.firstIndex(of: folderID) ?? order.count
        order.removeAll { $0 == folderID || replacements.contains($0) }
        order.insert(contentsOf: replacements, at: min(insertion, order.count))
        rootOrder = order
    }
    private func replaceOrderItems(_ removed: [String], with newID: String, in existingOrder: [String]) {
        var order = existingOrder
        let indices = removed.compactMap { order.firstIndex(of: $0) }
        let insertion = indices.min() ?? order.count
        order.removeAll { removed.contains($0) }
        order.removeAll { $0 == newID }
        order.insert(newID, at: min(insertion, order.count))
        rootOrder = order
    }

    private func removeMissingApplicationsFromOpenState() {
        if let pendingDeleteApp, !apps.contains(where: { $0.id == pendingDeleteApp.id }) {
            self.pendingDeleteApp = nil
        }
        if let openGroupID {
            guard let group = groups.first(where: { $0.id == openGroupID }) else {
                closeFolder()
                return
            }
            if apps(in: group).isEmpty { closeFolder() }
        }
    }

    func clearError() { errorMessage = nil }

    private func presentError(en: String, ja: String) {
        errorMessage = text(en, ja)
    }

    nonisolated static func sanitizedLanguage(_ value: String?) -> String {
        guard let value, ["system", "en", "ja"].contains(value) else { return "system" }
        return value
    }

    nonisolated static func sanitizedIconSize(_ value: Double) -> Double {
        guard value.isFinite else { return 92 }
        return min(max(value, 60), 112)
    }

    nonisolated static func referenceDefaultIconSize(pageWidth: Double) -> Double {
        guard pageWidth.isFinite, pageWidth > 0 else { return 92 }
        return min(max(pageWidth * 0.065, 72), 112)
    }

    nonisolated static func sanitizedBackground(_ value: String) -> String {
        let builtInValues: Set<String> = ["wallpaper", "aurora", "ocean", "dark", "light"]
        if builtInValues.contains(value) { return value }
        guard value.hasPrefix("file:") else { return "wallpaper" }
        let path = String(value.dropFirst(5))
        let allowedExtensions: Set<String> = ["heic", "jpg", "jpeg", "png"]
        guard path.hasPrefix("/"), path.count <= 4_096,
              !path.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
              allowedExtensions.contains(URL(fileURLWithPath: path).pathExtension.lowercased()),
              FileManager.default.isReadableFile(atPath: path) else { return "wallpaper" }
        return "file:" + URL(fileURLWithPath: path).standardizedFileURL.path
    }

    nonisolated static func sanitizedSearch(_ value: String) -> String {
        let withoutControls = value.components(separatedBy: .controlCharacters).joined()
        return String(withoutControls.prefix(128))
    }

    nonisolated static func sanitizedGroupName(_ value: String, allowEmpty: Bool, fallback: String) -> String {
        let withoutControls = value.components(separatedBy: .controlCharacters).joined()
        let limited = String(withoutControls.prefix(64))
        if allowEmpty { return limited }
        let trimmed = limited.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    nonisolated static func sanitizedOrder(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values.prefix(10_000) {
            guard value.count <= 4_200, isStructurallyValidEntryID(value), seen.insert(value).inserted else { continue }
            result.append(value)
        }
        return result
    }

    nonisolated static func sanitizedGroups(_ values: [AppGroup]) -> [AppGroup] {
        var seenGroupIDs: Set<UUID> = []
        var assignedPaths: Set<String> = []
        var result: [AppGroup] = []

        for group in values.prefix(500) where seenGroupIDs.insert(group.id).inserted {
            var paths: [String] = []
            for path in group.appPaths.prefix(2_000) {
                guard isStructurallyValidAppPath(path), assignedPaths.insert(path).inserted else { continue }
                paths.append(path)
            }
            guard !paths.isEmpty else { continue }
            let fallback = group.systemKind == "utilities" ? "Utilities" : (group.systemKind == "games" ? "Games" : "Folder")
            let systemKind = ["utilities", "games"].contains(group.systemKind ?? "") ? group.systemKind : nil
            result.append(AppGroup(
                id: group.id,
                name: sanitizedGroupName(group.name, allowEmpty: false, fallback: fallback),
                appPaths: paths,
                systemKind: systemKind
            ))
        }
        return result
    }

    nonisolated private static func isStructurallyValidEntryID(_ value: String) -> Bool {
        if value.hasPrefix("app:") { return isStructurallyValidAppPath(String(value.dropFirst(4))) }
        if value.hasPrefix("group:") { return UUID(uuidString: String(value.dropFirst(6))) != nil }
        return false
    }

    nonisolated private static func isStructurallyValidAppPath(_ path: String) -> Bool {
        path.hasPrefix("/") && path.count <= 4_096
            && !path.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
            && URL(fileURLWithPath: path).pathExtension.lowercased() == "app"
    }
}
