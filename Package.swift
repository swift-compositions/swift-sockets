// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-sockets",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Sockets", targets: ["Sockets"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-compositions/swift-io-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-threads.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-executors.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-span.git", branch: "main", traits: ["Byte"]),

        .package(url: "https://github.com/swift-compositions/swift-posix.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Sockets",
            dependencies: [
                .product(name: "IO Kernel", package: "swift-io-kernel"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Thread Actor", package: "swift-threads"),
                .product(name: "Executors", package: "swift-executors"),
                .product(name: "Span Raw", package: "swift-span"),
            ]
        ),
        .testTarget(
            name: "Sockets Tests",
            dependencies: [
                "Sockets",
                .product(name: "IO Kernel", package: "swift-io-kernel"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Span Raw", package: "swift-span"),

                .product(name: "Thread Actor", package: "swift-threads"),
                .product(name: "Executors", package: "swift-executors"),
                .product(name: "POSIX Kernel Poll", package: "swift-posix"),
            ],
            path: "Tests/Sockets Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
