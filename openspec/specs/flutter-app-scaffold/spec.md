### Requirement: Monorepo directory structure
The repository SHALL have a monorepo layout with the Flutter app in `app/` and a `packages/` directory for future shared packages. The root directory SHALL contain only monorepo-level configuration files (`.gitignore`, `README.md`, `openspec/`).

#### Scenario: Root directory contains expected structure
- **WHEN** a developer clones the repository
- **THEN** the root contains `app/`, `packages/`, `openspec/`, `README.md`, and `.gitignore`

#### Scenario: Packages directory exists for future use
- **WHEN** a developer inspects the `packages/` directory
- **THEN** the directory exists with a `.gitkeep` file and no packages yet

### Requirement: Flutter app runs on iOS and Android
The Flutter application in `app/` SHALL build and run on both iOS (minimum iOS 14) and Android (minimum API 21). No other platform targets (web, desktop, etc.) SHALL be included.

#### Scenario: App builds for iOS
- **WHEN** a developer runs `flutter build ios` from `app/`
- **THEN** the build completes without errors targeting iOS 14+

#### Scenario: App builds for Android
- **WHEN** a developer runs `flutter build apk` from `app/`
- **THEN** the build completes without errors targeting Android API 21+

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

### Requirement: App displays a minimal placeholder screen
The app SHALL display a minimal placeholder screen (e.g., an empty `Scaffold`) so the app is visually runnable and verifiable. No feature UI SHALL be included.

#### Scenario: App launches to a blank screen
- **WHEN** the app is launched on a device or emulator
- **THEN** a blank screen (empty `Scaffold`) is displayed without errors

#### Scenario: No feature UI present
- **WHEN** a developer inspects the lib/ source code
- **THEN** there are no feature-specific widgets, screens, or business logic — only the app shell
