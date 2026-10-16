## MODIFIED Requirements

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
