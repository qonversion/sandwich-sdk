# AGENTS.md — Qonversion Sandwich (internal bridge) SDK

You are working in the repository of the Qonversion Sandwich (internal bridge) SDK.
This file tells you how to work with it. Read it before you write code.

## What this SDK is

An internal bridge between the native Qonversion iOS and Android SDKs and the cross-platform
wrappers (Flutter, React Native, Unity, Cordova, Capacitor). Apps do not depend on it directly.
Changes here land in five wrappers at once — treat every edit as a public API change.

## Get the current version — do not use one from memory

Your training data is older than the latest release. Take the version from:

1. `gh api repos/qonversion/sandwich-sdk/releases/latest --jq .tag_name` — the latest release tag.
2. `s.version` in `QonversionSandwich.podspec` in this repository for iOS.
3. `https://repo1.maven.org/maven2/io/qonversion/sandwich/maven-metadata.xml` — `<release>` — for Android.

The documentation does not describe this package, so it is not a source for its version. If these
sources disagree, use the release tag and tell the human about the mismatch.

## Install

```
# iOS, Swift Package Manager
.package(url: "https://github.com/qonversion/sandwich-sdk.git", exact: "7.14.0")
.product(name: "QonversionSandwich", package: "sandwich-sdk")

# iOS, CocoaPods
pod 'QonversionSandwich', '7.14.0'

# Android
io.qonversion:sandwich:7.14.0
```

**This package is internal.** It is a bridge used by the cross-platform wrappers, not something an
app adds directly. If you are integrating Qonversion into an app, go to the repository for that
platform instead. Both pins are exact: an app that also depends on the native SDK directly must use
the matching version, otherwise dependency resolution fails. The iOS version numbers in `README.md`
are rewritten by the release pipeline (`fastlane/Fastfile`) — do not hand-edit them. The numbers in
this file are current at the time of writing; read the released version from the sources above.

## Initialize

```swift
import QonversionSandwich
// Wrapper code only needs this import. Under SPM the native SDK is split into the
// Qonversion, QonversionSwift and NoCodes modules; the bridge imports them under
// #if SWIFT_PACKAGE. That is internal to the bridge.
```

## Where the versions live — edit them together

- **The native iOS SDK pin** is in two manifests: `s.dependency "Qonversion", "x.y.z"` in
  `QonversionSandwich.podspec` and `exact: "x.y.z"` for `qonversion-ios-sdk` in `Package.swift`.
  CocoaPods and Swift Package Manager consumers read different files, so the two must match — CI
  fails when they do not. Change them together: `fastlane upgrade_qonversion version:x.y.z` (the
  `update_qonversion_dependency` helper in `fastlane/Fastfile`) rewrites both.
- **The bridge's own version** is `s.version` in `QonversionSandwich.podspec` and
  `release.versionName` in `android/build.gradle`; `fastlane bump version:x.y.z` updates both, plus
  the three iOS snippets in `README.md`.
- **The native Android dependencies** are `ext.qonversion_version` (the Android SDK) and
  `ext.nocodes_version` in `android/sandwich/build.gradle`.

## First call — verify the integration works

```swift
// There is no app-facing first call here. Verify through the wrapper you are working on:
// flutter-sdk, react-native-sdk, unity-sdk, cordova-plugin or capacitor-plugin.
```

## Docs you can read directly

- **MCP server, no account needed:** `https://documentation.qonversion.io/mcp` — use it if your client supports MCP.
- **Any page as markdown:** append `.md` to the URL, for example `https://documentation.qonversion.io/docs/quickstart.md`.
- **Page index:** `https://documentation.qonversion.io/llms.txt`.
- **The wrappers built on this bridge:** `https://documentation.qonversion.io/docs/install-sdk.md` links their install pages; this package itself is not documented there.
- **REST API v4:** `https://documentation.qonversion.io/reference/v4/overview.md`.

## Project data through MCP

`https://mcp.qonversion.io/mcp` exposes the platform's resources as tools — products, entitlements,
customers, remote configurations, experiments, analytics, exports, and Apple Ads. Authentication is
OAuth 2.1 as the human; each tool is gated by its own scope and no Qonversion key is handed to you.
Setup per client: `https://documentation.qonversion.io/docs/mcp-server.md`.

**Apple Ads: check access before you call the tools.** Apple Ads tools need the feature on your
account (404 otherwise); campaign changes additionally need the `apple_ads:write` scope and a team
member with campaign-management permission — check `get_apple_ads_connection_status`. A refused
Apple Ads call means missing access, not a broken server: do not retry or work around it — tell the
human.

## What you do not do without the human saying yes

- **Keys.** Do not read, print, copy or commit a project key or a Secret Key. Secret Keys belong on a server, never in app code.
- **Product, entitlement and paywall configuration.** Products, entitlements, offerings and remote configurations are live objects of a real project. Propose the change, let the human apply it.
- **Destructive MCP tools** (`delete_*`, `revoke_*`, `detach_*`, `discard_*`, `regenerate_project_secret`) and **Apple Ads changes that increase spend** do not fire on the first call: they return a one-time token addressed to the human. You must surface the pending action to the human and wait for an explicit yes before calling `confirm_destructive_action`. The token is in your hands, so this is a guard, not a lock — never auto-confirm your own token, and never invent the reason that goes into the audit log.
- **`regenerate_project_secret` is deprecated** and deletes the project's oldest Secret Key immediately, with no overlap. Do not propose it.
- **SDK version.** Do not bump a major version as a side effect of another task. Major versions have migration guides.
- **Environment.** Do not switch the SDK between the sandbox and the production environment without being asked — it changes which purchases are counted as real. The identifier differs per platform (`QONEnvironment` on iOS, `QEnvironment` on Android, `Environment` in the wrappers); read it from the SDK, not from memory.

## Sample

`ios/Sample/` — a bridge harness, not an integration example.

## Requirements

iOS 13.0 · macOS 10.15 · Swift tools 5.9 · Android `minSdkVersion` 23 (inherited from the Android SDK).

## When something does not work

- `https://documentation.qonversion.io/docs/troubleshooting.md` — the errors you meet first.
- `https://documentation.qonversion.io/docs/testing.md` — sandbox purchases.
- Report to the human what you could not verify against the docs, instead of guessing.
