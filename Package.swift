// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TicTieMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TicTieMac", targets: ["TicTieMac"]),
        .library(name: "TicTieCore", targets: ["TicTieCore"])
    ],
    targets: [
        // Platform-agnostic domain logic: the adding-machine tape engine,
        // tickmark / sign-off models and number formatting. No PDFKit or
        // SwiftUI here, so it is fully unit-testable and also builds on Linux.
        .target(
            name: "TicTieCore",
            resources: [
                // Canonical, user-editable tickmark legend shared with the
                // Acrobat plug-in (see AcrobatPlugin/generate-legend.sh).
                .copy("Resources/tickmark-legend.json")
            ]
        ),
        // The SwiftUI + PDFKit macOS application. All Apple-only code is
        // guarded with `#if canImport(...)` so the package still compiles on
        // other platforms (the executable becomes a no-op stub there).
        .executableTarget(
            name: "TicTieMac",
            dependencies: ["TicTieCore"]
        ),
        .testTarget(
            name: "TicTieCoreTests",
            dependencies: ["TicTieCore"]
        )
    ]
)
