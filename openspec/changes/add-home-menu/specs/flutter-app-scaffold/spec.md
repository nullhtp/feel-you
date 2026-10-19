## REMOVED Requirements

### Requirement: App starts on the language picker or the lessons
**Reason**: With a saved language the app no longer opens on the lessons but on the home menu, so the requirement's name and its "later launch" scenario no longer hold.
**Migration**: Replaced by "App starts on the language picker or the home menu" below; the lessons are opened from the menu's Learn (see `home-menu` and `touch-surface`).

## ADDED Requirements

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
