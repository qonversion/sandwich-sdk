# Qonversion Sandwich SDK
Qonversion Sandwich SDK is used for bridging in cross-platform SDKs. It is intended for internal purposes only.
If you are looking for cross-platform SDKs then visit the corresponding repositories:
- [Flutter](https://github.com/qonversion/flutter-sdk)
- [React Native](https://github.com/qonversion/react-native-sdk)
- [Unity](https://github.com/qonversion/unity-sdk)
- [Cordova](https://github.com/qonversion/cordova-plugin)
- [Capacitor](https://github.com/qonversion/capacitor-plugin)

Native SDKs used in this hybrid one:
- [iOS](https://github.com/qonversion/qonversion-ios-sdk)
- [Android](https://github.com/qonversion/android-sdk)

## Integration (iOS)

The iOS part is distributed both as a CocoaPod and as a Swift package. CocoaPods trunk becomes read-only on December 2, 2026 ([announcement](https://blog.cocoapods.org/CocoaPods-Specs-Repo/)), so wrappers should resolve the sandwich through the Swift package wherever their host framework supports it — see the [migration guide](https://documentation.qonversion.io/docs/dec-2026-migration-guide-cocoapods-to-spm). Both pin the same Qonversion iOS SDK version, and both pins are exact — an app that also depends on `Qonversion` / `qonversion-ios-sdk` directly must use that same version, otherwise dependency resolution fails.

CocoaPods (a wrapper podspec):
```ruby
s.dependency "QonversionSandwich", "7.14.0"
```

CocoaPods (a Podfile):
```ruby
pod 'QonversionSandwich', '7.14.0'
```

Swift Package Manager (a wrapper `Package.swift`):
```swift
.package(url: "https://github.com/qonversion/sandwich-sdk.git", exact: "7.14.0")
// target dependency:
.product(name: "QonversionSandwich", package: "sandwich-sdk")
```

Wrapper code only needs `import QonversionSandwich` (`@import QonversionSandwich;` from Objective-C). Under SPM the Qonversion SDK is split into the `Qonversion`, `QonversionSwift` and `NoCodes` modules, which is why the bridge sources import them under `#if SWIFT_PACKAGE` — this is internal to the bridge. The version numbers above are rewritten by the release pipeline.
