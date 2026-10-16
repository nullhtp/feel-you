# Feel You: Flutter app

The Flutter app for Feel You, a Morse code teacher for deaf-blind users that works through touch and vibration only. See the [root README](../README.md) for what the app does, its gestures and its vibration signals.

## Requirements

- **Flutter 3.47.3** (stable channel, Dart 3.13.3). CI pins this version in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml); use the same one locally.
- The Android SDK and/or Xcode, as described in the [Flutter install guide](https://docs.flutter.dev/get-started/install).
- A **real phone** to feel anything. The iOS simulator reports no vibration motor, so the app opens there on its "No vibration motor" screen; debug builds show a *Continue anyway (debug build)* button to get past it. An Android emulator reports a motor and opens on the picker, but you can't feel its vibrations.

The app runs in landscape only. On iOS it is built for iPhone only.

## Build and run

All commands run from this `app/` directory:

```sh
flutter pub get      # install dependencies
flutter run          # run on a connected device or emulator (debug)
```

On Android, [`run-android.sh`](../run-android.sh) finds the first connected Android device or emulator, fetches dependencies and runs the app on it. Run it from the repo root:

```sh
./run-android.sh             # debug (default)
./run-android.sh --profile
./run-android.sh --release
```

## Test

```sh
flutter test                     # unit and widget tests in test/
flutter test integration_test    # integration tests; needs a connected device or emulator
```

CI runs these checks on every push to `master` and on every pull request:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test --coverage
```

## Layout

| Directory | Contents |
|-----------|----------|
| `lib/morse/` | Alphabets (digits, English, Arabic, Russian), levels and word patterns |
| `lib/gestures/` | Touch classification (dot, dash, swipes, hold, bottom strip) and shake detection |
| `lib/teaching/` | The play-wait-repeat loop that ties gestures, session and vibration together |
| `lib/session/` | Current language, level, position and phase |
| `lib/vibration/` | Morse and signal vibration patterns, device capability checks |
| `lib/settings/` | The saved language |
| `lib/ui/` | Language picker, lesson surface, helper overlay, no-vibration screen |
| `test/`, `integration_test/` | Tests |
