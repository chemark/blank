#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/NewFile.xcodeproj"
SCHEME="NewFile"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="$PROJECT_ROOT/.derivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Blank.app"
INSTALL_DIR="$HOME/Applications"
INSTALLED_APP_PATH="$INSTALL_DIR/Blank.app"
DERIVED_DEBUG_EXTENSION_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex"
DERIVED_RELEASE_EXTENSION_PATH="$DERIVED_DATA_PATH/Build/Products/Release/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex"
INSTALLED_EXTENSION_PATH="$INSTALLED_APP_PATH/Contents/PlugIns/NewFileFinderExtension.appex"

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

mkdir -p "$INSTALL_DIR"
/usr/bin/ditto "$APP_PATH" "$INSTALLED_APP_PATH"
/usr/bin/pluginkit -r "$DERIVED_DEBUG_EXTENSION_PATH" >/dev/null 2>&1 || true
/usr/bin/pluginkit -r "$DERIVED_RELEASE_EXTENSION_PATH" >/dev/null 2>&1 || true
/usr/bin/pluginkit -a "$INSTALLED_EXTENSION_PATH"
/usr/bin/pluginkit -e use -i com.xingshuhao.NewFile.FinderExtension

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
