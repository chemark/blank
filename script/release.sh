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

echo "==> 打包 DMG"
DMG_PATH="$EXPORT_DIR/Blank.dmg"
STAGING_DIR="$PROJECT_ROOT/build/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
/usr/bin/ditto "$APP_PATH" "$STAGING_DIR/Blank.app"
ln -s /Applications "$STAGING_DIR/Applications"

/usr/bin/hdiutil create \
  -volname Blank \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

echo "==> 签名并公证 DMG"
codesign --sign "Developer ID Application" --timestamp "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl -a -vvv -t install "$DMG_PATH"

echo "Done: $DMG_PATH"
