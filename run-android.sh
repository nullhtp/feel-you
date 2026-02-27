#!/usr/bin/env bash
set -euo pipefail

# Start the Feel You app on a connected Android device/emulator.
#
# Prerequisites:
#   - Flutter SDK installed and on PATH
#   - Android device connected via USB (with USB debugging enabled)
#     OR an Android emulator running
#
# Usage:
#   ./run-android.sh            # debug mode (default)
#   ./run-android.sh --release  # release mode
#   ./run-android.sh --profile  # profile mode

APP_DIR="$(dirname "$0")/app"
MODE="${1:---debug}"

# Validate mode argument
case "$MODE" in
  --debug|--release|--profile) ;;
  *)
    echo "Error: unknown mode '$MODE'"
    echo "Usage: $0 [--debug|--release|--profile]"
    exit 1
    ;;
esac

# Check that Flutter is available
if ! command -v flutter &>/dev/null; then
  echo "Error: flutter not found on PATH"
  echo "Install Flutter: https://docs.flutter.dev/get-started/install"
  exit 1
fi

# Find the first connected Android device ID using JSON output
DEVICE_ID=$(flutter devices --machine 2>/dev/null \
  | python3 -c "
import sys, json
devices = json.load(sys.stdin)
for d in devices:
    if 'android' in d.get('targetPlatform', '').lower():
        print(d['id'])
        break
" 2>/dev/null || true)

if [ -z "$DEVICE_ID" ]; then
  echo "No Android device or emulator detected."
  echo ""
  echo "To connect a physical device:"
  echo "  1. Enable USB debugging on the device"
  echo "  2. Connect via USB and accept the debugging prompt"
  echo ""
  echo "To start an emulator:"
  echo "  flutter emulators --launch <emulator_id>"
  echo "  (list available: flutter emulators)"
  exit 1
fi

echo "Found Android device: $DEVICE_ID"
echo ""

echo "Fetching dependencies..."
(cd "$APP_DIR" && flutter pub get)

echo ""
echo "Starting Feel You on Android ($MODE)..."
(cd "$APP_DIR" && flutter run "$MODE" -d "$DEVICE_ID")
