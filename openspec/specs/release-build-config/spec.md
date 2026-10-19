# release-build-config Specification

## Purpose

Release build settings: Android signing, R8, the VIBRATE permission and App Bundles, and iOS release readiness.

## Requirements

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

### Requirement: Android backup leaves out the secure storage
The Android app SHALL declare backup rules for Android 11 and lower (`android:fullBackupContent`) and data extraction rules for Android 12 and higher (`android:dataExtractionRules`) that leave the secure storage files out of cloud backup and device-to-device transfer. Backup SHALL stay enabled, and the rules SHALL leave out nothing else, so the app's other preferences keep being backed up.

#### Scenario: Both rule sets are declared
- **WHEN** the merged Android manifest is inspected
- **THEN** the application element SHALL reference a full backup content rules file and a data extraction rules file
- **AND** `android:allowBackup` SHALL NOT be `false`

#### Scenario: Secure storage files are excluded
- **WHEN** the full backup content rules, and the cloud backup and device transfer sections of the data extraction rules, are inspected
- **THEN** each SHALL exclude, in the `sharedpref` domain, `FlutterSecureStorage.xml`, `FlutterSecureKeyStorage.xml` and `FlutterSecureStorageConfiguration:FlutterSecureStorage.xml`
- **AND** none SHALL contain any other include or exclude rule

#### Scenario: Other preferences are still backed up
- **WHEN** the app's data is backed up or transferred to another phone
- **THEN** `FlutterSharedPreferences.xml`, which holds the saved language and learned items, SHALL be included
