// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftUIBase",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftUIBase",
            type: .dynamic,
            targets: ["SwiftUIBase"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/bizz84/SwiftyStoreKit.git", from: "0.16.4")
    ],
    targets: [
        .target(
            name: "SwiftUIBase",
            dependencies: [
                .product(name: "SwiftyStoreKit", package: "SwiftyStoreKit")
            ],
            path: "Sources/SwiftUIBase",
            exclude: [],
            resources: []
        ),
    ],
    swiftLanguageModes: [.v6]
)
