// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "QonversionSandwich",
    platforms: [
        .iOS(.v13), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "QonversionSandwich",
            targets: ["QonversionSandwich"])
    ],
    dependencies: [
        .package(url: "https://github.com/qonversion/qonversion-ios-sdk.git", exact: "6.10.0")
    ],
    targets: [
        .target(
            name: "QonversionSandwich",
            dependencies: [
                .product(name: "Qonversion", package: "qonversion-ios-sdk")
            ],
            path: "ios/sandwich"
        )
    ]
)
