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
    private let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 96
        cache.totalCostLimit = 64 * 1_024 * 1_024
        return cache
    }()

    func icon(for url: URL) -> NSImage {
        let standardizedURL = url.standardizedFileURL
        let key = standardizedURL.path as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let icon: NSImage
        if let bundleIcon = Self.bundleIcon(for: standardizedURL),
           let normalizedBundleIcon = Self.normalizedIcon(bundleIcon) {
            icon = normalizedBundleIcon
        } else {
            let workspaceIcon = NSWorkspace.shared.icon(forFile: standardizedURL.path)
            icon = Self.normalizedIcon(workspaceIcon) ?? workspaceIcon
        }
        let pixelSize = Self.renderedPixelSize
        cache.setObject(icon, forKey: key, cost: pixelSize * pixelSize * 4)
        return icon
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

    private nonisolated static func normalizedIcon(_ source: NSImage) -> NSImage? {
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
        return NSImage(
            cgImage: renderedImage,
            size: NSSize(width: renderedPixelSize, height: renderedPixelSize)
        )
    }
}

actor LauncherBackgroundImageLoader {
    private let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 8
        cache.totalCostLimit = 256 * 1_024 * 1_024
        return cache
    }()

    func image(for url: URL) -> NSImage? {
        let standardizedURL = url.standardizedFileURL
        let key = standardizedURL.path as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard !Task.isCancelled,
              standardizedURL.isFileURL,
              FileManager.default.isReadableFile(atPath: standardizedURL.path) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 4_096,
            kCGImageSourceShouldCacheImmediately: true
        ]
        let decodedImage: NSImage?
        let decodedCost: Int
        if let source = CGImageSourceCreateWithURL(standardizedURL as CFURL, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            decodedImage = NSImage(
                cgImage: cgImage,
                size: NSSize(width: cgImage.width, height: cgImage.height)
            )
            decodedCost = cgImage.width * cgImage.height * 4
        } else {
            decodedImage = NSImage(contentsOf: standardizedURL)
            decodedCost = 16 * 1_024 * 1_024
        }

        guard !Task.isCancelled, let decodedImage else { return nil }
        cache.setObject(decodedImage, forKey: key, cost: decodedCost)
        return decodedImage
    }
}
