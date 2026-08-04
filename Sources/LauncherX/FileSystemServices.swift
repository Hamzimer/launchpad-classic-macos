import Foundation
import AppKit
import ImageIO

struct AppScanResult: Sendable {
    let apps: [AppItem]
    let accessibleRootCount: Int
}

enum FileOperationOutcome: Sendable {
    case success
    case failure(String)
}

actor LauncherFileScanner {
    func scanApplications(homeDirectory: URL) -> AppScanResult {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            homeDirectory.appendingPathComponent("Applications", isDirectory: true)
        ]
        return Self.scanApplications(in: roots)
    }

    func scanWallpapers() -> [WallpaperItem] {
        let roots = [
            URL(fileURLWithPath: "/System/Library/Desktop Pictures", isDirectory: true),
            URL(fileURLWithPath: "/Library/Desktop Pictures", isDirectory: true)
        ]
        return Self.scanWallpapers(in: roots)
    }

    nonisolated static func scanApplications(in roots: [URL]) -> AppScanResult {
        let fileManager = FileManager()
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
        var accessibleRootCount = 0
        var found: [String: AppItem] = [:]

        for root in roots {
            guard !Task.isCancelled, root.isFileURL,
                  fileManager.fileExists(atPath: root.path),
                  let enumerator = fileManager.enumerator(
                    at: root,
                    includingPropertiesForKeys: resourceKeys,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants],
                    errorHandler: { _, _ in true }
                  ) else { continue }

            accessibleRootCount += 1
            for case let url as URL in enumerator {
                guard !Task.isCancelled else {
                    return AppScanResult(apps: [], accessibleRootCount: accessibleRootCount)
                }
                guard isSafeFileURL(url, extensions: ["app"]) else { continue }

                let bundle = Bundle(url: url)
                let category = bundle?.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
                let receipt = url.appendingPathComponent("Contents/_MASReceipt/receipt").path
                let isSystemApp = url.standardizedFileURL.path.hasPrefix("/System/")
                let deletable = !isSystemApp && fileManager.fileExists(atPath: receipt)
                found[url.standardizedFileURL.path] = AppItem(
                    url: url.standardizedFileURL,
                    category: category,
                    isDeletable: deletable
                )
            }
        }

        let apps = found.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        return AppScanResult(apps: apps, accessibleRootCount: accessibleRootCount)
    }

    nonisolated static func scanWallpapers(in roots: [URL]) -> [WallpaperItem] {
        let fileManager = FileManager()
        let allowedExtensions: Set<String> = ["heic", "jpg", "jpeg", "png"]
        var found: [String: WallpaperItem] = [:]

        for root in roots {
            guard !Task.isCancelled, root.isFileURL,
                  fileManager.fileExists(atPath: root.path),
                  let enumerator = fileManager.enumerator(
                    at: root,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles],
                    errorHandler: { _, _ in true }
                  ) else { continue }

            for case let url as URL in enumerator {
                guard !Task.isCancelled else { return [] }
                guard isSafeFileURL(url, extensions: allowedExtensions) else { continue }
                let standardizedURL = url.standardizedFileURL
                found[standardizedURL.path] = WallpaperItem(url: standardizedURL)
            }
        }

        return found.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    nonisolated private static func isSafeFileURL(_ url: URL, extensions: Set<String>) -> Bool {
        guard url.isFileURL, url.path.count <= 4_096,
              !url.path.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
              extensions.contains(url.pathExtension.lowercased()) else { return false }
        return true
    }
}

actor LauncherFileOperator {
    func moveApplicationToTrash(_ url: URL, homeDirectory: URL) -> FileOperationOutcome {
        let fileManager = FileManager()
        let appURL = url.standardizedFileURL
        let appPath = appURL.path
        let userApplicationsPath = homeDirectory
            .appendingPathComponent("Applications", isDirectory: true)
            .standardizedFileURL.path + "/"
        let isInApplications = appPath.hasPrefix("/Applications/") || appPath.hasPrefix(userApplicationsPath)
        let receiptPath = appURL.appendingPathComponent("Contents/_MASReceipt/receipt").path

        guard appURL.isFileURL,
              appURL.pathExtension.lowercased() == "app",
              appPath.count <= 4_096,
              !appPath.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
              isInApplications,
              fileManager.fileExists(atPath: appPath),
              fileManager.fileExists(atPath: receiptPath) else {
            return .failure("The application is no longer in a deletable location.")
        }

        do {
            try fileManager.trashItem(at: appURL, resultingItemURL: nil)
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}

actor LauncherIconLoader {
    private static let renderedPixelSize = 512
    private let cache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 96
        cache.totalCostLimit = 64 * 1_024 * 1_024
        return cache
    }()

    func iconData(for url: URL) -> Data? {
        let standardizedURL = url.standardizedFileURL
        let key = standardizedURL.path as NSString
        if let cached = cache.object(forKey: key) { return cached as Data }
        let iconData: Data?
        if let bundleIcon = Self.bundleIcon(for: standardizedURL),
           let normalizedBundleIconData = Self.normalizedIconData(bundleIcon) {
            iconData = normalizedBundleIconData
        } else {
            let workspaceIcon = NSWorkspace.shared.icon(forFile: standardizedURL.path)
            iconData = Self.normalizedIconData(workspaceIcon)
        }
        guard !Task.isCancelled, let iconData else { return nil }
        cache.setObject(iconData as NSData, forKey: key, cost: iconData.count)
        return iconData
    }

    private nonisolated static func bundleIcon(for appURL: URL) -> NSImage? {
        guard appURL.isFileURL, appURL.pathExtension.lowercased() == "app" else { return nil }
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist", isDirectory: false)
        var iconNames: [String] = []

        do {
            let data = try Data(contentsOf: infoURL, options: .mappedIfSafe)
            let propertyList = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
            if let dictionary = propertyList as? [String: Any] {
                if let iconFile = dictionary["CFBundleIconFile"] as? String {
                    iconNames.append(iconFile)
                }
                if let iconName = dictionary["CFBundleIconName"] as? String {
                    iconNames.append(iconName)
                }
            }
        } catch {
            iconNames = []
        }

        var visitedNames: Set<String> = []
        for rawName in iconNames where visitedNames.insert(rawName).inserted {
            guard let safeName = sanitizedIconResourceName(rawName) else { continue }
            let names = URL(fileURLWithPath: safeName).pathExtension.isEmpty
                ? [safeName + ".icns", safeName]
                : [safeName]
            for name in names {
                let iconURL = resourcesURL.appendingPathComponent(name, isDirectory: false)
                if FileManager.default.isReadableFile(atPath: iconURL.path),
                   let image = NSImage(contentsOf: iconURL) {
                    return image
                }
            }
        }

        do {
            let resourceURLs = try FileManager.default.contentsOfDirectory(
                at: resourcesURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            for iconURL in resourceURLs.prefix(512)
                where iconURL.pathExtension.lowercased() == "icns" {
                if let image = NSImage(contentsOf: iconURL) { return image }
            }
        } catch {
            return nil
        }
        return nil
    }

    private nonisolated static func sanitizedIconResourceName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.count <= 255,
              !trimmed.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
              URL(fileURLWithPath: trimmed).lastPathComponent == trimmed else { return nil }
        return trimmed
    }

    private nonisolated static func normalizedIconData(_ source: NSImage) -> Data? {
        var proposedRect = NSRect(
            x: 0,
            y: 0,
            width: renderedPixelSize,
            height: renderedPixelSize
        )
        guard let sourceImage = source.cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
        ),
        let context = CGContext(
            data: nil,
            width: renderedPixelSize,
            height: renderedPixelSize,
            bitsPerComponent: 8,
            bytesPerRow: renderedPixelSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.clear(CGRect(x: 0, y: 0, width: renderedPixelSize, height: renderedPixelSize))
        context.draw(
            sourceImage,
            in: CGRect(x: 0, y: 0, width: renderedPixelSize, height: renderedPixelSize)
        )
        guard let renderedImage = context.makeImage() else { return nil }
        guard let pixelData = renderedImage.dataProvider?.data,
              (pixelData as Data).contains(where: { $0 != 0 }) else { return nil }
        return NSBitmapImageRep(cgImage: renderedImage).representation(
            using: .png,
            properties: [:]
        )
    }
}

struct LauncherDecodedImage: Sendable {
    let pixels: Data
    let width: Int
    let height: Int
    let bytesPerRow: Int

    var memoryCost: Int { pixels.count }

    @MainActor
    func makeImage() -> NSImage? {
        guard width > 0,
              height > 0,
              bytesPerRow == width * 4,
              pixels.count == bytesPerRow * height,
              let provider = CGDataProvider(data: pixels as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(
                    rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                ),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else { return nil }
        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: width, height: height)
        )
    }
}

actor LauncherBackgroundImageLoader {
    private static let maximumCachedImages = 8
    private static let maximumCacheCost = 256 * 1_024 * 1_024
    private var cache: [String: LauncherDecodedImage] = [:]
    private var cacheOrder: [String] = []
    private var cacheCost = 0

    func imageData(for url: URL) -> LauncherDecodedImage? {
        let standardizedURL = url.standardizedFileURL
        let key = standardizedURL.path
        if let cached = cachedImage(forKey: key) { return cached }
        guard !Task.isCancelled,
              standardizedURL.isFileURL,
              FileManager.default.isReadableFile(atPath: standardizedURL.path) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 4_096,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let source = CGImageSourceCreateWithURL(standardizedURL as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                options as CFDictionary
              ),
              !Task.isCancelled,
              let decodedImage = Self.rgbaImage(from: cgImage),
              !Task.isCancelled else { return nil }
        store(decodedImage, forKey: key)
        return decodedImage
    }

    private func cachedImage(forKey key: String) -> LauncherDecodedImage? {
        guard let image = cache[key] else { return nil }
        cacheOrder.removeAll { $0 == key }
        cacheOrder.append(key)
        return image
    }

    private func store(_ image: LauncherDecodedImage, forKey key: String) {
        guard image.memoryCost <= Self.maximumCacheCost else { return }
        if let existing = cache.removeValue(forKey: key) {
            cacheCost -= existing.memoryCost
        }
        cacheOrder.removeAll { $0 == key }
        while (cache.count >= Self.maximumCachedImages
            || cacheCost + image.memoryCost > Self.maximumCacheCost),
            let oldestKey = cacheOrder.first {
            cacheOrder.removeFirst()
            if let removed = cache.removeValue(forKey: oldestKey) {
                cacheCost -= removed.memoryCost
            }
        }
        cache[key] = image
        cacheOrder.append(key)
        cacheCost += image.memoryCost
    }

    private nonisolated static func rgbaImage(from source: CGImage) -> LauncherDecodedImage? {
        let width = source.width
        let height = source.height
        let rowCalculation = width.multipliedReportingOverflow(by: 4)
        guard width > 0,
              height > 0,
              !rowCalculation.overflow else { return nil }
        let bytesPerRow = rowCalculation.partialValue
        let sizeCalculation = bytesPerRow.multipliedReportingOverflow(by: height)
        guard !sizeCalculation.overflow,
              sizeCalculation.partialValue <= maximumCacheCost else { return nil }

        var pixels = Data(count: sizeCalculation.partialValue)
        let didRender = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return false }
            context.interpolationQuality = .high
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didRender else { return nil }
        return LauncherDecodedImage(
            pixels: pixels,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow
        )
    }
}
