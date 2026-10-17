# app-identity Specification

## Purpose

How the app identifies itself on both platforms: bundle identifier, display name, icon and version number.

## Requirements

### Requirement: Unified bundle identifier
Both Android and iOS SHALL use `com.feelyou.app` as the application/bundle identifier. The Android `namespace` and `applicationId` in `build.gradle.kts` SHALL be `com.feelyou.app`. The iOS `PRODUCT_BUNDLE_IDENTIFIER` SHALL be `com.feelyou.app`.

#### Scenario: Android application ID is com.feelyou.app
- **WHEN** the Android build configuration is inspected
- **THEN** both `namespace` and `applicationId` are set to `com.feelyou.app`

#### Scenario: iOS bundle identifier is com.feelyou.app
- **WHEN** the iOS project settings are inspected
- **THEN** `PRODUCT_BUNDLE_IDENTIFIER` is `com.feelyou.app` for all build configurations

### Requirement: Consistent display name
The app display name SHALL be "Feel You" on both platforms. The Android manifest `android:label` SHALL be `Feel You`. The iOS `CFBundleName` in Info.plist SHALL be `Feel You`.

#### Scenario: Android display name
- **WHEN** the app is installed on an Android device
- **THEN** it appears as "Feel You" in the launcher and app settings

#### Scenario: iOS display name
- **WHEN** the app is installed on an iOS device
- **THEN** it appears as "Feel You" on the home screen and in Settings

### Requirement: App icon generation pipeline
The project SHALL use `flutter_launcher_icons` as a dev dependency with a configuration file. The configuration SHALL accept a single 1024x1024 PNG source icon and generate all required platform-specific sizes for both Android and iOS.

#### Scenario: Icon generation from source asset
- **WHEN** `dart run flutter_launcher_icons` is executed with a valid source icon
- **THEN** all Android mipmap and iOS Assets.xcassets icons are generated at correct sizes

#### Scenario: Icon configuration file exists
- **WHEN** the project is inspected
- **THEN** a `flutter_launcher_icons.yaml` configuration file exists in the `app/` directory specifying the source icon path and platform settings

### Requirement: Version management
The app version SHALL follow semantic versioning via `pubspec.yaml` in `version: X.Y.Z+N` format where `X.Y.Z` is the display version and `N` is the build number. The initial store release SHALL be version `1.0.0+1`. Every release (a store upload or an APK attached to a GitHub release) SHALL raise the build number `N` by one, SHALL have an entry in `CHANGELOG.md` at the repository root, and SHALL be tagged `vX.Y.Z`.

#### Scenario: Version propagates to both platforms
- **WHEN** `version: 1.0.0+1` is set in pubspec.yaml
- **THEN** Android versionName is `1.0.0` and versionCode is `1`
- **THEN** iOS CFBundleShortVersionString is `1.0.0` and CFBundleVersion is `1`

#### Scenario: Every release raises the build number
- **WHEN** a release is prepared and the previous release had build number `N`
- **THEN** `pubspec.yaml` has build number `N+1`

#### Scenario: Every release is in the changelog and tagged
- **WHEN** version `X.Y.Z` is released
- **THEN** `CHANGELOG.md` has a `[X.Y.Z]` section with the release date and the changes since the previous release
- **THEN** the released commit is tagged `vX.Y.Z`
