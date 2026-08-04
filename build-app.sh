#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
BIN="$PWD/.build/out/Products/Release/LauncherX"
rm -f "$BIN"
set +e
swift build -c release --disable-sandbox --scratch-path "$PWD/.build" -debug-info-format none \
  --arch arm64 --arch x86_64
BUILD_STATUS=$?
set -e
if [[ ! -x "$BIN" ]]; then
  echo "Build failed before producing an executable (status $BUILD_STATUS)." >&2
  exit "$BUILD_STATUS"
fi
APP="dist/LauncherX.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/LauncherX"
cp Info.plist "$APP/Contents/Info.plist"
MASTER_ICON="$PWD/.build/AppIcon-1024.png"
ICON_GENERATOR="$PWD/.build/GenerateAppIcon"
swiftc Tools/GenerateAppIcon.swift -o "$ICON_GENERATOR" -framework AppKit
"$ICON_GENERATOR" "$MASTER_ICON" "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP"
echo "$APP"
