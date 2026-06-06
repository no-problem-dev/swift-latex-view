// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-latex-view",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LaTeXCore",
            targets: ["LaTeXCore"]
        ),
        .library(
            name: "SwiftLaTeXView",
            targets: ["SwiftLaTeXView"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mgriebling/SwiftMath.git", .upToNextMajor(from: "1.7.0")),
        .package(url: "https://github.com/no-problem-dev/swift-design-system.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.0"))
    ],
    targets: [
        .target(
            name: "LaTeXCore",
            dependencies: [
                .product(name: "SwiftMath", package: "SwiftMath")
            ]
        ),
        .target(
            name: "SwiftLaTeXView",
            dependencies: [
                "LaTeXCore",
                .product(name: "SwiftMath", package: "SwiftMath"),
                .product(name: "DesignSystem", package: "swift-design-system")
            ]
        ),
        .testTarget(
            name: "LaTeXCoreTests",
            dependencies: ["LaTeXCore"]
        ),
        .testTarget(
            name: "SwiftLaTeXViewTests",
            dependencies: [
                "SwiftLaTeXView",
                .product(name: "VisualTesting", package: "swift-visual-testing")
            ]
        )
    ]
)
