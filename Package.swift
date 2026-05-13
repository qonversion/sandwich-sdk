// swift-tools-version:5.9
// Dual-distribution: this Package.swift ships alongside QonversionSandwich.podspec.
// SPM consumers get a pre-built XCFramework via .binaryTarget; CocoaPods consumers
// keep using the source pod until trunk goes read-only (2026-12-02).
//
// Release CI updates `version` and the two checksums atomically, then re-tags so
// SPM resolves the same commit it pushed to pod trunk.
import PackageDescription

let version = "7.10.0"
let sandwichChecksum = "REPLACE_AT_RELEASE_QONVERSION_SANDWICH"
let qonversionChecksum = "REPLACE_AT_RELEASE_QONVERSION"
let base = "https://github.com/qonversion/sandwich-sdk/releases/download/\(version)"

let package = Package(
    name: "QonversionSandwich",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "QonversionSandwich",
            targets: ["QonversionSandwich", "Qonversion"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "QonversionSandwich",
            url: "\(base)/QonversionSandwich.xcframework.zip",
            checksum: sandwichChecksum
        ),
        .binaryTarget(
            name: "Qonversion",
            url: "\(base)/Qonversion.xcframework.zip",
            checksum: qonversionChecksum
        )
    ]
)
