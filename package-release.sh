#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
export COPYFILE_DISABLE=1

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
if [[ ! "$VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  echo "Info.plist contains an invalid release version." >&2
  exit 1
fi

APP="dist/Launchpad Classic.app"
ZIP="dist/LaunchpadClassic-$VERSION.zip"
PKG="dist/LaunchpadClassic-$VERSION.pkg"
STAGING=$(mktemp -d "/tmp/launchpad-classic-package.XXXXXX")
trap 'rm -rf "$STAGING"' EXIT

./build-app.sh
rm -f "$ZIP" "$PKG"
ditto -c -k --norsrc --noqtn --keepParent "$APP" "$ZIP"
mkdir -p "$STAGING/Applications"
ditto --norsrc --noqtn "$APP" "$STAGING/Applications/Launchpad Classic.app"
pkgbuild \
  --root "$STAGING" \
  --install-location / \
  --identifier jp.local.launchpadclassic27.installer \
  --version "$VERSION" \
  --ownership recommended \
  "$PKG"

unzip -t "$ZIP"
pkgutil --check-signature "$PKG" || true
echo "$ZIP"
echo "$PKG"
