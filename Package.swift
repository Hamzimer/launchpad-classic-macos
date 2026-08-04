// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LauncherX",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "LauncherX", targets: ["LauncherX"])],
    targets: [.executableTarget(name: "LauncherX")]
)
