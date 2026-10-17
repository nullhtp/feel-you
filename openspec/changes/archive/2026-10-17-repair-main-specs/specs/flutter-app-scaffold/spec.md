## REMOVED Requirements

### Requirement: App displays a minimal placeholder screen
**Reason**: The app has had feature UI since `touch-ui-layer`; the empty `Scaffold` is long gone.
**Migration**: Replaced by *App starts on the language picker or the lessons*.

## ADDED Requirements

### Requirement: App starts on the language picker or the lessons
`main` SHALL lock the app to landscape and load the saved language before the first frame, then run `FeelYouApp` in a `ProviderScope`. `FeelYouApp` SHALL be a `MaterialApp` with a dark theme and a black scaffold background. Its first screen SHALL be the language picker when no language is saved, and the lesson surface otherwise. A vibration gate around the navigator SHALL show the no-vibration screen instead of any route on a device that reports no vibration motor.

#### Scenario: First launch opens the picker
- **WHEN** the app is launched with no saved language
- **THEN** the language picker is shown

#### Scenario: Later launch opens the lessons
- **WHEN** the app is launched with a saved language
- **THEN** the lesson surface is shown in that language, and the picker never appears

#### Scenario: Device without a vibration motor
- **WHEN** the app runs on a device that reports no vibration motor
- **THEN** the no-vibration screen is shown instead of the picker or the lessons, including routes opened after launch

#### Scenario: Vibration support unknown
- **WHEN** the app cannot tell whether the device has a vibration motor
- **THEN** it assumes there is one and shows the picker or the lessons
