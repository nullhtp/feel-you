## MODIFIED Requirements

### Requirement: Configurable Morse vibration timing
The system SHALL define Morse vibration timing through a configuration object (`MorseTimingConfig`) with the following default values: dot duration 100ms, dash duration 300ms, inter-symbol gap 100ms, inter-character gap 300ms. All values SHALL be overridable at construction time.

#### Scenario: Default timing values
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** dot is 100ms, dash is 300ms, inter-symbol gap is 100ms, and inter-character gap is 300ms

#### Scenario: Custom timing values
- **WHEN** a `MorseTimingConfig` is created with dot=150ms, dash=450ms, gap=120ms, interCharGap=400ms
- **THEN** those custom values are used instead of defaults

#### Scenario: Default inter-character gap follows ITU standard
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** the inter-character gap (300ms) SHALL be 3 times the dot duration (100ms)

## MODIFIED Requirements

### Requirement: Play Morse pattern as vibration
The system SHALL provide a `VibrationService` that can play a list of `MorseSymbol` values as a vibration sequence. Each dot SHALL vibrate for the configured dot duration, each dash for the configured dash duration, and symbols SHALL be separated by the configured inter-symbol gap (silence). A `charGap` symbol SHALL produce a silence of the configured inter-character gap duration instead of a vibration.

#### Scenario: Play single dot
- **WHEN** `playMorsePattern([dot])` is called
- **THEN** the device vibrates for 100ms (with default config)

#### Scenario: Play dot-dash sequence
- **WHEN** `playMorsePattern([dot, dash])` is called with default config
- **THEN** the device vibrates for 100ms, pauses 100ms, then vibrates for 300ms

#### Scenario: Play full letter pattern
- **WHEN** `playMorsePattern([dot, dot, dot])` is called (letter S) with default config
- **THEN** the device vibrates 100ms, pauses 100ms, vibrates 100ms, pauses 100ms, vibrates 100ms

#### Scenario: Play word pattern with charGap
- **WHEN** `playMorsePattern([dot, dot, charGap, dash])` is called (word "IT") with default config
- **THEN** the device vibrates 100ms (I-dot1), pauses 100ms (inter-symbol), vibrates 100ms (I-dot2), pauses 300ms (charGap), vibrates 300ms (T-dash)

#### Scenario: charGap produces silence not vibration
- **WHEN** a `charGap` symbol is encountered in the pattern
- **THEN** no vibration is produced — only a silence of `interCharGap` duration (300ms default)

## MODIFIED Requirements

### Requirement: Vibration pattern generation is pure logic
The conversion from `MorseSymbol` list to vibration duration pattern (list of millisecond on/off durations) SHALL be a pure function, separate from the actual device vibration call. The function SHALL handle `charGap` by producing a silence of `interCharGap` duration. This enables unit testing the pattern generation without hardware.

#### Scenario: Pattern generation returns duration list
- **WHEN** generating a vibration pattern for `[dot, dash]` with default config
- **THEN** the result is a list of durations: `[0, 100, 100, 300]` (wait 0ms, vibrate 100ms, wait 100ms, vibrate 300ms) or equivalent format expected by the vibration package

#### Scenario: Pattern generation handles charGap
- **WHEN** generating a vibration pattern for `[dot, dot, charGap, dash]` with default config
- **THEN** the charGap produces a silence of 300ms between the last dot and the dash, replacing the normal inter-symbol gap at that position

#### Scenario: Pattern generation is testable without device
- **WHEN** calling the pattern generation function in a unit test
- **THEN** no device hardware or vibration permission is required
