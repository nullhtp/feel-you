## ADDED Requirements

### Requirement: Android release signing configuration
The Android build SHALL use a dedicated release keystore for signing release builds. A `key.properties` file SHALL reference the keystore location, alias, and passwords. The `build.gradle.kts` SHALL load signing configuration from `key.properties` when building in release mode. The `key.properties` file MUST NOT be committed to version control.

#### Scenario: Release build uses keystore signing
- **WHEN** a release build is created with `flutter build apk --release`
- **THEN** the APK is signed with the keystore defined in `key.properties`

#### Scenario: key.properties missing triggers clear error
- **WHEN** a release build is attempted without a `key.properties` file
- **THEN** the build falls back to debug signing with a warning (matching standard Flutter behavior)

#### Scenario: key.properties template is available
- **WHEN** a developer clones the repository
- **THEN** a `key.properties.example` file exists documenting the required properties and keystore generation command

### Requirement: Android ProGuard/R8 configuration
The Android release build SHALL include ProGuard rules that preserve Flutter engine classes. A `proguard-rules.pro` file SHALL be referenced in the release build type configuration.

#### Scenario: Release build with R8 minification
- **WHEN** a release APK or App Bundle is built
- **THEN** R8 minification runs with Flutter-compatible ProGuard rules applied

### Requirement: Android VIBRATE permission
The Android manifest SHALL explicitly declare the `android.permission.VIBRATE` permission to ensure vibration works on all devices.

#### Scenario: Vibration permission is declared
- **WHEN** the merged Android manifest is inspected
- **THEN** the `android.permission.VIBRATE` uses-permission element is present

### Requirement: iOS release build readiness
The iOS project SHALL have `DEVELOPMENT_TEAM` documented as a required configuration. The Xcode project SHALL use automatic signing. Build settings SHALL support both Debug and Release configurations.

#### Scenario: iOS release archive
- **WHEN** `flutter build ipa` is run with a valid team ID configured in Xcode
- **THEN** an IPA is produced suitable for App Store upload

### Requirement: Android App Bundle support
The Android build SHALL produce an App Bundle (AAB) for Google Play submission. The `flutter build appbundle` command SHALL work with release signing.

#### Scenario: App Bundle build succeeds
- **WHEN** `flutter build appbundle --release` is run with valid `key.properties`
- **THEN** a signed AAB file is produced at the expected output path
