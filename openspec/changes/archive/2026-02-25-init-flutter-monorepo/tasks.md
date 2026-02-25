## 1. Create Flutter App

- [x] 1.1 Run `flutter create` in `app/` with org name, targeting iOS and Android only (no web/desktop)
- [x] 1.2 Remove any auto-generated web/desktop/linux/macos/windows directories if created
- [x] 1.3 Set minimum iOS deployment target to 14.0 in `ios/Podfile` and Xcode project settings
- [x] 1.4 Set minimum Android SDK to 21 in `android/app/build.gradle` (should be default, verify)
- [x] 1.5 Verify `flutter build apk` and `flutter build ios --no-codesign` succeed from `app/`

## 2. Configure Monorepo Structure

- [x] 2.1 Create `packages/` directory at repo root with a `.gitkeep` file
- [x] 2.2 Update root `.gitignore` to cover Flutter artifacts, IDE files, and platform-specific build outputs
- [x] 2.3 Verify root directory only contains `app/`, `packages/`, `openspec/`, `README.md`, and `.gitignore`

## 3. Add Analysis and Linting

- [x] 3.1 Add `very_good_analysis` as a dev dependency in `app/pubspec.yaml`
- [x] 3.2 Create `app/analysis_options.yaml` that includes `very_good_analysis` rules
- [x] 3.3 Fix any analysis warnings in the auto-generated scaffold code
- [x] 3.4 Verify `dart analyze` from `app/` reports zero issues

## 4. Set Up Riverpod

- [x] 4.1 Add `flutter_riverpod` and `riverpod_annotation` as dependencies in `app/pubspec.yaml`
- [x] 4.2 Replace the default `main.dart` with a minimal entry point that wraps the app in `ProviderScope`
- [x] 4.3 Create `app/lib/app.dart` with a `MaterialApp` returning an empty `Scaffold` as the home screen
- [x] 4.4 Verify the app launches on an emulator/simulator showing a blank screen with no errors

## 5. Verify and Clean Up

- [x] 5.1 Run `dart analyze` from `app/` — confirm zero warnings and errors
- [x] 5.2 Run `flutter test` from `app/` — confirm default tests pass (update widget test for new app structure)
- [x] 5.3 Confirm the monorepo directory structure matches the design doc layout
