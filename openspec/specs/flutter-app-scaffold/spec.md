# flutter-app-scaffold Specification

## Purpose

The Flutter project the app is built on: repository layout, supported platforms, state management, analysis rules and the app shell.

## Requirements

### Requirement: Repository directory structure
The repository SHALL keep the Flutter app, its only Dart package, in `app/`. It SHALL NOT have a `packages/` directory until a second package exists. Files and directories at the root SHALL concern the repository as a whole (documentation, CI, OpenSpec, store listing, helper scripts), not the Flutter build.

#### Scenario: Root directory contains expected structure
- **WHEN** a developer clones the repository
- **THEN** the root contains `app/`, `openspec/`, `README.md`, and `.gitignore`
- **THEN** there is no `packages/` directory

#### Scenario: Flutter commands run from app/
- **WHEN** a developer runs a `flutter` command such as `flutter pub get` or `flutter test`
- **THEN** they run it from `app/`, which holds `pubspec.yaml`

### Requirement: Flutter app runs on iOS and Android
The Flutter application in `app/` SHALL build and run on both iOS (minimum iOS 15) and Android (minimum API 24). No other platform targets (web, desktop, etc.) SHALL be included.

#### Scenario: App builds for iOS
- **WHEN** a developer runs `flutter build ios` from `app/`
- **THEN** the build completes without errors targeting iOS 15+

#### Scenario: App builds for Android
- **WHEN** a developer runs `flutter build apk` from `app/`
- **THEN** the build completes without errors targeting Android API 24+

#### Scenario: No web or desktop targets
- **WHEN** a developer inspects the `app/` directory
- **THEN** there are no `web/`, `linux/`, `macos/`, or `windows/` directories

### Requirement: Riverpod state management is configured
The app SHALL use `flutter_riverpod` as its state management foundation. The root widget SHALL be wrapped in a `ProviderScope`.

#### Scenario: ProviderScope wraps the app
- **WHEN** the app starts
- **THEN** `ProviderScope` is the outermost widget wrapping `MaterialApp`

#### Scenario: Riverpod dependencies are declared
- **WHEN** a developer inspects `app/pubspec.yaml`
- **THEN** `flutter_riverpod` and `riverpod_annotation` are listed as dependencies

### Requirement: Strict Dart analysis is enforced
The app SHALL use `very_good_analysis` (or equivalent strict analysis rules) and the analysis configuration SHALL produce zero warnings on the initial scaffold.

#### Scenario: Analysis passes on clean project
- **WHEN** a developer runs `dart analyze` from `app/`
- **THEN** no warnings or errors are reported

#### Scenario: Analysis config references strict rules
- **WHEN** a developer inspects `app/analysis_options.yaml`
- **THEN** it includes `very_good_analysis` or equivalent strict rule set

### Requirement: App starts on the language picker or the home menu
`main` SHALL lock the app to landscape and load the saved language before the first frame, then run `FeelYouApp` in a `ProviderScope`. `FeelYouApp` SHALL be a `MaterialApp` with a dark theme and a black scaffold background. Its first screen SHALL be the language picker when no language is saved, and the home menu otherwise. A vibration gate around the navigator SHALL show the no-vibration screen instead of any route on a device that reports no vibration motor.

#### Scenario: First launch opens the picker
- **WHEN** the app is launched with no saved language
- **THEN** the language picker is shown

#### Scenario: Later launch opens the menu
- **WHEN** the app is launched with a saved language
- **THEN** the home menu is shown with Learn highlighted, and neither the picker nor the lessons appear, not even for the first frame

#### Scenario: Device without a vibration motor
- **WHEN** the app runs on a device that reports no vibration motor
- **THEN** the no-vibration screen is shown instead of the picker, the menu or the lessons, including routes opened after launch

#### Scenario: Vibration support unknown
- **WHEN** the app cannot tell whether the device has a vibration motor
- **THEN** it assumes there is one and shows the picker or the menu
