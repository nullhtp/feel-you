## ADDED Requirements

### Requirement: Centralized tuning reference
The system SHALL provide a centralized Dart file that documents all adjustable timing constants across gesture recognition, vibration engine, and teaching loop. The file SHALL reference the existing config classes without replacing them.

#### Scenario: All gesture timing constants documented
- **WHEN** a developer opens the tuning reference file
- **THEN** it SHALL list all `GestureTimingConfig` parameters: `dotMaxDuration`, `dashMaxDuration`, `resetMinDuration`, `silenceTimeout`, `minSwipeDistance`, `minSwipeVelocity`
- **THEN** each parameter SHALL have a doc comment explaining its role and units

#### Scenario: All vibration timing constants documented
- **WHEN** a developer opens the tuning reference file
- **THEN** it SHALL list all `MorseTimingConfig` parameters: `dotDuration`, `dashDuration`, `interSymbolGap`, `signalDuration`, `signalSteps`
- **THEN** each parameter SHALL have a doc comment explaining its role and units

#### Scenario: All teaching timing constants documented
- **WHEN** a developer opens the tuning reference file
- **THEN** it SHALL list all `TeachingTimingConfig` parameters: `repeatPause`
- **THEN** each parameter SHALL have a doc comment explaining its role and units

### Requirement: TODO markers for device-dependent values
The tuning reference SHALL mark timing values that need real-device validation with `// TODO(tuning):` comments.

#### Scenario: Vibration durations marked for tuning
- **WHEN** reviewing the tuning reference
- **THEN** `dotDuration`, `dashDuration`, `interSymbolGap`, `signalDuration`, and `signalSteps` SHALL each have a `// TODO(tuning):` comment indicating they need real-device validation

#### Scenario: Gesture thresholds marked for tuning
- **WHEN** reviewing the tuning reference
- **THEN** `dotMaxDuration`, `dashMaxDuration`, `resetMinDuration`, and `silenceTimeout` SHALL each have a `// TODO(tuning):` comment indicating they may need adjustment based on real-device feel

#### Scenario: Teaching loop pause marked for tuning
- **WHEN** reviewing the tuning reference
- **THEN** `repeatPause` SHALL have a `// TODO(tuning):` comment indicating it needs real-device validation for comfortable learning pace

### Requirement: Tuning config aggregates existing defaults
The tuning reference SHALL expose a constant that creates all three config objects with their current default values, demonstrating the single point from which all timing can be adjusted.

#### Scenario: Default configs accessible from tuning reference
- **WHEN** a developer imports the tuning reference
- **THEN** they SHALL be able to access default instances of `GestureTimingConfig`, `MorseTimingConfig`, and `TeachingTimingConfig` with all current default values
