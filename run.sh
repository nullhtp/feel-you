#!/usr/bin/env bash
set -euo pipefail

# Start the Feel You app on a connected Android or iOS device.
#
# Prerequisites:
#   - Flutter SDK installed and on PATH
#   - Android: a device connected via USB (with USB debugging enabled)
#     OR an Android emulator running
#   - iOS (macOS only): Xcode, and an iPhone connected via USB (with
#     Developer Mode on) OR a booted iOS simulator
#
# A real device is picked before an emulator or simulator: the iOS simulator
# has no vibration motor, and an Android emulator's vibrations can't be felt.
#
# Usage:
#   ./run.sh android            # debug mode (default)
#   ./run.sh ios --release      # release mode (iOS: real iPhone only)
#   ./run.sh android --profile  # profile mode

APP_DIR="$(dirname "$0")/app"
USAGE="Usage: $0 <android|ios> [--debug|--release|--profile]"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "$USAGE"
  exit 1
fi

PLATFORM="$1"
MODE="${2:---debug}"

# Validate platform argument
case "$PLATFORM" in
  android) PLATFORM_NAME="Android"; EMULATOR_NAME="emulator" ;;
  ios) PLATFORM_NAME="iOS"; EMULATOR_NAME="simulator" ;;
  *)
    echo "Error: unknown platform '$PLATFORM'"
    echo "$USAGE"
    exit 1
    ;;
esac

# Validate mode argument
case "$MODE" in
  --debug|--release|--profile) ;;
  *)
    echo "Error: unknown mode '$MODE'"
    echo "$USAGE"
    exit 1
    ;;
esac

if [ "$PLATFORM" = ios ] && [ "$(uname -s)" != Darwin ]; then
  echo "Error: building for iOS needs macOS with Xcode"
  exit 1
fi

# Check that Flutter is available
if ! command -v flutter &>/dev/null; then
  echo "Error: flutter not found on PATH"
  echo "Install Flutter: https://docs.flutter.dev/get-started/install"
  exit 1
fi

# Find a connected device for the platform using JSON output, real devices
# first. Prints "<id> <emulator>", where <emulator> is true or false.
DEVICE=$(flutter devices --machine 2>/dev/null \
  | python3 -c "
import sys, json
platform = sys.argv[1]
devices = [d for d in json.load(sys.stdin)
           if d.get('targetPlatform', '').lower().startswith(platform)]
devices.sort(key=lambda d: bool(d.get('emulator')))
if devices:
    print(devices[0]['id'], str(bool(devices[0].get('emulator'))).lower())
" "$PLATFORM" 2>/dev/null || true)

if [ -z "$DEVICE" ]; then
  echo "No $PLATFORM_NAME device detected."
  echo ""
  if [ "$PLATFORM" = android ]; then
    echo "To connect a physical device:"
    echo "  1. Enable USB debugging on the device"
    echo "  2. Connect via USB and accept the debugging prompt"
    echo ""
    echo "To start an emulator:"
    echo "  flutter emulators --launch <emulator_id>"
    echo "  (list available: flutter emulators)"
  else
    echo "To connect an iPhone:"
    echo "  1. Turn on Settings > Privacy & Security > Developer Mode"
    echo "  2. Connect via USB and trust this computer"
    echo ""
    echo "To start a simulator (it has no vibration motor):"
    echo "  flutter emulators --launch apple_ios_simulator"
  fi
  exit 1
fi

read -r DEVICE_ID EMULATOR <<<"$DEVICE"

if [ "$EMULATOR" = true ]; then
  echo "Found $PLATFORM_NAME $EMULATOR_NAME: $DEVICE_ID"
  if [ "$PLATFORM" = ios ]; then
    if [ "$MODE" != --debug ]; then
      echo "Error: Flutter runs $MODE only on a real iPhone, not the simulator"
      exit 1
    fi
    echo "The simulator has no vibration motor, so the app opens on its"
    echo "\"No vibration motor\" screen. Tap \"Continue anyway (debug build)\"."
  fi
else
  echo "Found $PLATFORM_NAME device: $DEVICE_ID"
fi
echo ""

echo "Fetching dependencies..."
(cd "$APP_DIR" && flutter pub get)

echo ""
echo "Starting Feel You on $PLATFORM_NAME ($MODE)..."
(cd "$APP_DIR" && flutter run "$MODE" -d "$DEVICE_ID")
