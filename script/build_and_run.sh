#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/NewFile.xcodeproj"
SCHEME="NewFile"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="$PROJECT_ROOT/.derivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/NewFile.app"

cd "$PROJECT_ROOT"

if [[ ! -d "$PROJECT_PATH" ]]; then
  tuist generate --no-open --cache-profile none
fi

/usr/bin/pkill -x NewFile >/dev/null 2>&1 || true

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -skipPackagePluginValidation \
  -allowProvisioningUpdates \
  build

case "${1:-}" in
  --verify)
    /usr/bin/open -n "$APP_PATH"
    sleep 1
    /usr/bin/pgrep -x NewFile >/dev/null
    echo "NewFile is running."
    ;;
  --logs)
    /usr/bin/open -n "$APP_PATH"
    /usr/bin/log stream --style compact --predicate 'process == "NewFile" || process == "NewFileFinderExtension"'
    ;;
  --telemetry)
    /usr/bin/open -n "$APP_PATH"
    /usr/bin/log stream --style compact --predicate 'subsystem BEGINSWITH "com.xingshuhao.NewFile"'
    ;;
  "")
    /usr/bin/open -n "$APP_PATH"
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 2
    ;;
esac
