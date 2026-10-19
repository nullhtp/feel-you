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

[`run.sh`](../run.sh) picks a connected device for the platform you name, fetches dependencies and runs the app on it. It prefers a real phone over an emulator or simulator. Run it from the repo root:

```sh
./run.sh android             # debug (default)
./run.sh android --profile
./run.sh ios --release       # profile and release need a real iPhone
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

## Release

The version is `version: X.Y.Z+N` in [`pubspec.yaml`](pubspec.yaml). `X.Y.Z` is the version users see (Android `versionName`, iOS `CFBundleShortVersionString`). `N` is the build number (Android `versionCode`, iOS `CFBundleVersion`). The first store release is `1.0.0+1`.

1. Raise `N` by one for every build that leaves your machine: a store upload or an APK attached to a GitHub release. Never reuse or lower it. Google Play rejects a build number it has already accepted, and Android won't install an APK over one with a higher build number.
2. Raise `X.Y.Z` following [Semantic Versioning](https://semver.org/): the patch number for fixes, the minor number for new features, languages or levels, the major number for changes to gestures or signals that a user has already learned.
3. In [`CHANGELOG.md`](../CHANGELOG.md), rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD`, add a new empty `[Unreleased]` section above it and update the compare links at the bottom.
4. Set **Version** in [`store/store-info.md`](../store/store-info.md) to `X.Y.Z`.
5. Commit, tag the commit `vX.Y.Z` (for example `v1.0.0`; the older `v.0.0.2` tag has a stray dot) and push the commit and the tag.
6. Build from this directory:

   ```sh
   flutter build appbundle --release   # Google Play; needs android/key.properties, see android/key.properties.example
   flutter build apk --release         # APK for a GitHub release
   flutter build ipa                   # App Store; needs a development team set in Xcode
   ```

## Layout

| Directory | Contents |
|-----------|----------|
| `lib/tactile/` | The tactile tokens (short and long pulse, empty slot, character gap) and the `TactileCodec` interface that turns text into them |
| `lib/morse/` | Alphabets (digits, English, Arabic, Russian, Spanish, French, German), levels, word patterns and the Morse codec |
| `lib/gestures/` | Touch classification (dot, dash, swipes, hold, bottom strip) and shake detection |
| `lib/teaching/` | The play-wait-repeat loop that ties gestures, session and vibration together |
| `lib/session/` | Current language, level, position and phase |
| `lib/vibration/` | Plays tactile tokens and the success, error and tap signals; device capability checks. Knows nothing about Morse |
| `lib/settings/` | The saved language |
| `lib/cloud/` | The cloud (OpenRouter) key: validation, masking and its store in the Keychain / Keystore |
| `lib/ui/` | Home menu and language picker (built on one shared touch chooser), lesson surface, helper overlay, no-vibration screen |
| `test/`, `integration_test/` | Tests |
