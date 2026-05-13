#!/usr/bin/env bash
# Builds QonversionSandwich.xcframework and Qonversion.xcframework, signs them,
# zips, and emits SHA-256 checksums for the SPM Package.swift.
#
# Outputs (relative to repo root):
#   build/QonversionSandwich.xcframework.zip
#   build/Qonversion.xcframework.zip
#   build/checksums.env  (key=value pairs consumed by the publish workflow)
#
# Required env:
#   SIGNING_IDENTITY  Apple Developer ID code-signing identity, e.g. "Developer ID Application: Qonversion (XXXX)"
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
OUT="$REPO_ROOT/build"
mkdir -p "$OUT"

# Sandwich source pod uses Pods/Qonversion at build time — make sure the
# workspace has resolved pods before invoking this script in CI.
WORKSPACE="$REPO_ROOT/ios/QonversionSandwich.xcworkspace"

build_archive() {
  local scheme="$1" destination="$2" out_name="$3"
  xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$scheme" \
    -destination "$destination" \
    -archivePath "$WORK/$out_name" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ENABLE_BITCODE=NO \
    | xcpretty || true
}

create_xcframework() {
  local scheme="$1" framework_name="$2"
  build_archive "$scheme" "generic/platform=iOS"           "${scheme}-iphoneos"
  build_archive "$scheme" "generic/platform=iOS Simulator" "${scheme}-iphonesimulator"

  rm -rf "$OUT/${framework_name}.xcframework"
  xcodebuild -create-xcframework \
    -framework "$WORK/${scheme}-iphoneos.xcarchive/Products/Library/Frameworks/${framework_name}.framework" \
    -framework "$WORK/${scheme}-iphonesimulator.xcarchive/Products/Library/Frameworks/${framework_name}.framework" \
    -output "$OUT/${framework_name}.xcframework"

  if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
    codesign --sign "$SIGNING_IDENTITY" --timestamp --force \
      "$OUT/${framework_name}.xcframework"
  fi

  (cd "$OUT" && rm -f "${framework_name}.xcframework.zip" \
    && zip -ry "${framework_name}.xcframework.zip" "${framework_name}.xcframework" > /dev/null)
}

# QonversionSandwich and Qonversion are separate schemes in the workspace;
# both must be archived and packaged for the SPM binaryTargets.
create_xcframework "QonversionSandwich" "QonversionSandwich"
create_xcframework "Qonversion"         "Qonversion"

SANDWICH_SHA=$(swift package compute-checksum "$OUT/QonversionSandwich.xcframework.zip")
QONVERSION_SHA=$(swift package compute-checksum "$OUT/Qonversion.xcframework.zip")

cat > "$OUT/checksums.env" <<EOF
SANDWICH_CHECKSUM=$SANDWICH_SHA
QONVERSION_CHECKSUM=$QONVERSION_SHA
EOF

echo "Wrote $OUT/checksums.env"
cat "$OUT/checksums.env"
