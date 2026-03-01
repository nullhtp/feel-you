## 1. App Identity

- [x] 1.1 Update Android `applicationId` and `namespace` to `com.feelyou.app` in `app/android/app/build.gradle.kts`
- [x] 1.2 Update iOS `PRODUCT_BUNDLE_IDENTIFIER` to `com.feelyou.app` in Xcode project.pbxproj (all build configurations: Debug, Release, Profile)
- [x] 1.3 Update Android manifest `android:label` from `feel_you` to `Feel You` in `app/android/app/src/main/AndroidManifest.xml`
- [x] 1.4 Update iOS `CFBundleName` from `feel_you` to `Feel You` in `app/ios/Runner/Info.plist`

## 2. Android Release Signing

- [x] 2.1 Create `app/android/key.properties.example` template with documented fields (storePassword, keyPassword, keyAlias, storeFile) and keystore generation command
- [x] 2.2 Add `key.properties` and `*.jks` / `*.keystore` to `app/android/.gitignore` (already present)
- [x] 2.3 Update `app/android/app/build.gradle.kts` to load `key.properties` and configure release signing config
- [x] 2.4 Add `android.permission.VIBRATE` to `app/android/app/src/main/AndroidManifest.xml`

## 3. Android Release Build Config

- [x] 3.1 Create `app/android/app/proguard-rules.pro` with Flutter-compatible R8 rules
- [x] 3.2 Update release build type in `build.gradle.kts` to enable minification and reference ProGuard rules

## 4. iOS Release Build Readiness

- [x] 4.1 Document iOS signing setup: add comment or placeholder for `DEVELOPMENT_TEAM` in project.pbxproj and document the Xcode configuration steps
- [x] 4.2 Verify iOS release build configuration has proper settings (ensure no debug-only flags leak into release)

## 5. App Icon Setup

- [x] 5.1 Add `flutter_launcher_icons` as dev dependency in `app/pubspec.yaml`
- [x] 5.2 Create `app/flutter_launcher_icons.yaml` configuration file pointing to icon source path with both Android and iOS targets enabled
- [x] 5.3 Create `app/assets/` directory with a placeholder README documenting that the user must place their 1024x1024 icon at `assets/icon/icon.png`

## 6. Store Metadata

- [x] 6.1 Create `store/` directory at project root
- [x] 6.2 Create `store/description-en.md` with short and full English store descriptions
- [x] 6.3 Create `store/description-ar.md` with short and full Arabic store descriptions
- [x] 6.4 Create `store/keywords.md` with English and Arabic keyword lists
- [x] 6.5 Create `store/store-info.md` with category, content rating, supported languages, contact info, and store declarations

## 7. Privacy Policy

- [x] 7.1 Create `store/privacy-policy.md` covering: no data collection, device permissions used (vibration, accelerometer, wake lock) with explanations, and store compliance language

## 8. Verification

- [x] 8.1 Verify `flutter build appbundle --release` succeeds with debug signing (before real keystore is set up)
- [x] 8.2 Verify `flutter build ipa` configuration is correct (requires Xcode team — fails with clear instructions to set DEVELOPMENT_TEAM in Xcode)
- [x] 8.3 Verify `dart run flutter_launcher_icons` config is valid (config parses correctly; only fails on missing icon file which user will provide)
