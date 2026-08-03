#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/NewFile.xcodeproj"
SCHEME="NewFile"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="$PROJECT_ROOT/.derivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Blank.app"
INSTALL_DIR="/Applications"
INSTALLED_APP_PATH="$INSTALL_DIR/Blank.app"
INSTALLED_EXTENSION_PATH="$INSTALLED_APP_PATH/Contents/PlugIns/NewFileFinderExtension.appex"
EXTENSION_BUNDLE_ID="com.xingshuhao.NewFile.FinderExtension"

# 注销当前注册的所有同 bundle id 扩展。多份同时注册时 Finder 挑哪个不确定，
# 归档产物在 DerivedData 里的路径还带哈希，只注销已知路径不够。
unregister_all_extensions() {
  /usr/bin/pluginkit -m -A -D -vvv -p com.apple.FinderSync 2>/dev/null \
    | grep -A1 "$EXTENSION_BUNDLE_ID" \
    | sed -n 's/.*Path = //p' \
    | while IFS= read -r appex; do
        /usr/bin/pluginkit -r "$appex" >/dev/null 2>&1 || true
      done
}

cd "$PROJECT_ROOT"

if [[ ! -d "$PROJECT_PATH" ]]; then
  tuist generate --no-open --cache-profile none
fi

/usr/bin/pkill -x Blank >/dev/null 2>&1 || true
/usr/bin/pkill -x NewFileFinderExtension >/dev/null 2>&1 || true

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -skipPackagePluginValidation \
  -allowProvisioningUpdates \
  build

unregister_all_extensions
rm -rf "${INSTALLED_APP_PATH:?}"
/usr/bin/ditto "$APP_PATH" "$INSTALLED_APP_PATH"
/usr/bin/pluginkit -a "$INSTALLED_EXTENSION_PATH"
/usr/bin/pluginkit -e use -i "$EXTENSION_BUNDLE_ID"

case "${1:-}" in
  --verify)
    /usr/bin/open -n "$INSTALLED_APP_PATH"
    sleep 1
    /usr/bin/pgrep -x Blank >/dev/null
    echo "Blank is running."
    ;;
  --logs)
    /usr/bin/open -n "$INSTALLED_APP_PATH"
    /usr/bin/log stream --style compact --predicate 'process == "Blank" || process == "NewFileFinderExtension"'
    ;;
  --telemetry)
    /usr/bin/open -n "$INSTALLED_APP_PATH"
    /usr/bin/log stream --style compact --predicate 'subsystem BEGINSWITH "com.xingshuhao.NewFile"'
    ;;
  "")
    /usr/bin/open -n "$INSTALLED_APP_PATH"
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 2
    ;;
esac
