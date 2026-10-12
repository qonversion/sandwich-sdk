# Qonversion Sandwich SDK

**This package is internal.** It bridges the native Qonversion SDKs into the cross-platform wrappers
and is not meant to be added to an app directly. If you are integrating Qonversion into your app,
go to the repository for your platform:

- [Flutter](https://github.com/qonversion/flutter-sdk)
- [React Native](https://github.com/qonversion/react-native-sdk)
- [Unity](https://github.com/qonversion/unity-sdk)
- [Cordova](https://github.com/qonversion/cordova-plugin)
- [Capacitor](https://github.com/qonversion/capacitor-plugin)

Native SDKs bridged by this one:

- [iOS](https://github.com/qonversion/qonversion-ios-sdk)
- [Android](https://github.com/qonversion/android-sdk)

[![Version](https://img.shields.io/github/v/release/qonversion/sandwich-sdk?label=version)](https://github.com/qonversion/sandwich-sdk/releases)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.txt)

## Integration (iOS)

The iOS part is distributed both as a CocoaPod and as a Swift package. CocoaPods trunk becomes
read-only on December 2, 2026 ([announcement](https://blog.cocoapods.org/CocoaPods-Specs-Repo/)), so
wrappers should resolve the sandwich through the Swift package wherever their host framework
supports it — see the
[migration guide](https://documentation.qonversion.io/docs/dec-2026-migration-guide-cocoapods-to-spm).
Both pin the same Qonversion iOS SDK version, and both pins are exact — an app that also depends on
`Qonversion` / `qonversion-ios-sdk` directly must use that same version, otherwise dependency
resolution fails.

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

Wrapper code only needs `import QonversionSandwich` (`@import QonversionSandwich;` from
Objective-C). Under SPM the Qonversion iOS SDK is split into the `Qonversion`, `QonversionSwift` and
`NoCodes` modules, which is why the bridge sources import them under `#if SWIFT_PACKAGE` — this is
internal to the bridge. The version numbers above are rewritten by the release pipeline.

## Integration (Android)

The Android part is published to Maven Central as `io.qonversion:sandwich`. Wrappers declare it the
way their build system requires — for example, a Cordova plugin declares it in `plugin.xml`:

```xml
<framework src="io.qonversion:sandwich:7.14.0" />
```

The pin is exact for the same reason as on iOS.

## Documentation

* [Welcome](https://documentation.qonversion.io/docs/qonversion-platform) — what the platform does.
* [Installing the SDKs](https://documentation.qonversion.io/docs/install-sdk) — the per-platform packages this one sits under.

## Requirements

| | Minimum |
|---|---|
| iOS | 13.0 |
| macOS | 10.15 |
| Swift tools | 5.9 |
| Android `minSdkVersion` | 23 (inherited from the Android SDK) |

## Help

Contact us via [issues on GitHub](https://github.com/qonversion/sandwich-sdk/issues) or the
[contact form](https://qonversion.io/contact-us) on our site.

## License

Qonversion Sandwich SDK is available under the MIT license. See [LICENSE.txt](LICENSE.txt).
