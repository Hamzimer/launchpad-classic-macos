// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LauncherX",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "LauncherX", targets: ["LauncherX"])],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.2")
    ],
    targets: [
        .executableTarget(
            name: "LauncherX",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        )
    ]
)
