# Qonversion Sandwich SDK
Qonversion Sandwich SDK is used for bridging in cross-platform SDKs. It is intended for internal purposes only.
If you are looking for cross-platform SDKs then visit the corresponding repositories:
- [Flutter](https://github.com/qonversion/flutter-sdk)
- [React Native](https://github.com/qonversion/react-native-sdk)
- [Unity](https://github.com/qonversion/unity-sdk)
- [Cordova](https://github.com/qonversion/cordova-plugin)

Native SDKs used in this hybrid one:
- [iOS](https://github.com/qonversion/qonversion-ios-sdk)
- [Android](https://github.com/qonversion/android-sdk)

## Integration (iOS)

The iOS part is distributed both as a CocoaPod and as a Swift package; both pin the same Qonversion iOS SDK version.

CocoaPods:
```ruby
pod 'QonversionSandwich', '7.13.0'
```

Swift Package Manager (Package.swift):
```swift
.package(url: "https://github.com/qonversion/sandwich-sdk.git", exact: "7.13.0")
// target dependency:
.product(name: "QonversionSandwich", package: "sandwich-sdk")
```

Under SPM the Qonversion SDK is split into the `Qonversion`, `QonversionSwift` and `NoCodes` modules, which is why the bridge sources import them under `#if SWIFT_PACKAGE`.
