#!/usr/bin/env bash
# Sign the CMake-built SilentHill.app with Drew's Apple Development identity and
# the team's wildcard development profile, then install it on the iPhone.
# Usage: [SH_IOS_DEVICE=<devicectl id>] ios_port/sign/sign_and_install.sh [path/to/SilentHill.app]
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
APP="${1:-$(find "$REPO/build-ios" -maxdepth 4 -name 'SilentHill.app' -type d | head -1)}"
IDENTITY="Apple Development: Drew Atz (6A9K9K6MBY)"
PROFILE=~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/17b15c4c-13f5-4b7f-9023-bc20b8991f90.mobileprovision   # "iOS Team Provisioning Profile: *", GTSKP564KA.*, to 2027-10-17
# Drew's iPhone by default (devicectl id, same as DRUSIC's drusic.env); SH_IOS_DEVICE
# picks another paired device, e.g. the iPad Mothpad 5489E677-7EBD-57AA-B979-715914EE5B73.
DEV_UUID="${SH_IOS_DEVICE:-BC03397F-A753-52B1-A98F-80C59E5CB41B}"
[ -d "$APP" ] || { echo "no SilentHill.app under $REPO/build-ios; run ios_port/build_ios.sh first" >&2; exit 1; }
cp "$PROFILE" "$APP/embedded.mobileprovision"
# Nested code first (SDL is static here, but sign anything that is present), then the app.
find "$APP" -name '*.dylib' -o -name '*.framework' -maxdepth 3 2>/dev/null | while read -r n; do codesign --force --sign "$IDENTITY" "$n"; done
codesign --force --sign "$IDENTITY" --entitlements "$HERE/entitlements.plist" --timestamp=none "$APP"
codesign --verify --deep --strict "$APP" && echo "signed: $APP"
xcrun devicectl device install app --device "$DEV_UUID" "$APP"
