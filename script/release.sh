#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/NewFile.xcodeproj"
ARCHIVE_PATH="$PROJECT_ROOT/build/Blank.xcarchive"
EXPORT_DIR="$PROJECT_ROOT/dist"
APP_PATH="$EXPORT_DIR/Blank.app"
NOTARY_PROFILE="blank-notary"

cd "$PROJECT_ROOT"

rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme NewFile \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -skipPackagePluginValidation \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$PROJECT_ROOT/ExportOptions.plist"

echo "==> 检查签名"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "==> 公证 app"
NOTARY_ZIP="$PROJECT_ROOT/build/Blank.zip"
/usr/bin/ditto -c -k --keepParent "$APP_PATH" "$NOTARY_ZIP"
xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> 装订 app"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl -a -vvv -t exec "$APP_PATH"

echo "Done: $APP_PATH"
