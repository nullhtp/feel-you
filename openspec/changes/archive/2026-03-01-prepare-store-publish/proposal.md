## Why

The app has completed Phase 1 (Morse code learning tool) but cannot be distributed to users because it lacks store publishing configuration. There is no release signing, no app icons setup, no store metadata, and the bundle IDs are inconsistent across platforms. Preparing the app for App Store and Google Play submission is the next step to get Feel You into the hands of deaf-blind users.

## What Changes

- Unify bundle/application ID to `com.feelyou.app` across both Android and iOS
- Configure Android release signing (keystore setup, Gradle signing config)
- Configure iOS release build settings (team, provisioning, export options)
- Set up `flutter_launcher_icons` to generate app icons from user-provided assets
- Fix Android app display name from `feel_you` to `Feel You`
- Add store metadata files (app descriptions, keywords, category, content rating info)
- Add a privacy policy document (required by both stores)
- Configure ProGuard/R8 rules for Android release builds
- Verify VIBRATE permission is declared in Android manifest
- Set proper version management strategy in pubspec.yaml

## Non-goals

- CI/CD pipeline or automated deployment (separate future change)
- Splash screen configuration
- Fastlane or other deployment automation tooling
- Generating actual icon artwork (user will provide assets)
- App Store Connect or Google Play Console account setup
- Screenshot generation or marketing assets

## Capabilities

### New Capabilities

- `release-build-config`: Android and iOS release build configuration including signing, ProGuard, and build settings
- `app-identity`: Unified bundle ID, display name, versioning, and app icon setup across platforms
- `store-metadata`: Store listing metadata (descriptions, keywords, categories) and privacy policy for both App Store and Google Play

### Modified Capabilities

_None — this change adds new configuration without modifying existing app behavior or specs._

## Impact

- **Android**: `build.gradle.kts`, `AndroidManifest.xml`, new `key.properties` template, ProGuard rules
- **iOS**: Xcode project settings (bundle ID, team, signing), `Info.plist` updates
- **Root config**: `pubspec.yaml` (version, new dev dependency for launcher icons), new `flutter_launcher_icons.yaml`
- **New files**: Store metadata documents, privacy policy, icon generation config
- **Dependencies**: `flutter_launcher_icons` added as dev dependency
- **No runtime behavior changes** — all changes are build/config/metadata only
