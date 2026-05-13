#!/usr/bin/env bash
# Patches Package.swift with the released version and the freshly-built
# XCFramework checksums. Run in CI between build_xcframework.sh and the
# git commit + force-retag step.
#
# Usage: update_spm_version.sh <version> <sandwich-checksum> <qonversion-checksum>
set -euo pipefail

VERSION="$1"
SANDWICH_SHA="$2"
QONVERSION_SHA="$3"

PKG="$(cd "$(dirname "$0")/.." && pwd)/Package.swift"

# macOS sed: -i '' is required; GNU sed (in CI Linux runners) would need -i without arg.
SED_INPLACE=(-i '')
if sed --version >/dev/null 2>&1; then SED_INPLACE=(-i); fi

sed "${SED_INPLACE[@]}" -E "s/^let version = .*/let version = \"$VERSION\"/" "$PKG"
sed "${SED_INPLACE[@]}" -E "s/^let sandwichChecksum = .*/let sandwichChecksum = \"$SANDWICH_SHA\"/" "$PKG"
sed "${SED_INPLACE[@]}" -E "s/^let qonversionChecksum = .*/let qonversionChecksum = \"$QONVERSION_SHA\"/" "$PKG"

echo "Patched $PKG -> $VERSION"
grep -E '^let (version|sandwichChecksum|qonversionChecksum) ' "$PKG"
