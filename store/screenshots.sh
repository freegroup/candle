#!/usr/bin/env bash
# App Store screenshots on the iOS simulators: runs app/integration_test/store_screenshots_test.dart
# and takes a screenshot whenever the test prints "SCREENSHOT <name>".
#
#   store/screenshots.sh "iPhone 17 Pro Max" iphone-6.9
#   store/screenshots.sh "iPad Pro 13-inch (M5)" ipad-13
#
# Language German; the test places the user at Pariser Platz in Berlin.
set -euo pipefail

device="$1"
out="$(cd "$(dirname "$0")" && pwd)/screenshots/ios/$2"
mkdir -p "$out"

udid="$(xcrun simctl list devices available | grep -F "$device (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
# German, a clean status bar like Apple's own screenshots
xcrun simctl spawn "$udid" defaults write -g AppleLanguages -array de
xcrun simctl spawn "$udid" defaults write -g AppleLocale -string de_DE
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3

cd "$(dirname "$0")/../app"
flutter test integration_test/store_screenshots_test.dart -d "$udid" \
    --dart-define-from-file=env/dev.json 2>&1 | while IFS= read -r line; do
  echo "$line"
  if [[ "$line" =~ SCREENSHOT\ ([a-z0-9_]+) ]]; then
    xcrun simctl io "$udid" screenshot "$out/${BASH_REMATCH[1]}.png" >/dev/null
    echo ">> saved $out/${BASH_REMATCH[1]}.png"
  fi
done
