### Requirement: Configurable Morse vibration timing
The system SHALL define Morse vibration timing through a configuration object (`MorseTimingConfig`) with the following default values: dot duration 100ms, dash duration 300ms, inter-symbol gap 100ms. All values SHALL be overridable at construction time.

#### Scenario: Default timing values
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** dot is 100ms, dash is 300ms, and inter-symbol gap is 100ms

#### Scenario: Custom timing values
- **WHEN** a `MorseTimingConfig` is created with dot=150ms, dash=450ms, gap=120ms
- **THEN** those custom values are used instead of defaults

### Requirement: Configurable signal vibration timing
The `MorseTimingConfig` SHALL also define signal vibration timing with defaults: success pulse duration 80ms, success inter-pulse gap 80ms, success pulse count 3, error buzz duration 600ms. All values SHALL be overridable.

#### Scenario: Default signal timing values
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** success pulse is 80ms, success gap is 80ms, success count is 3, and error buzz is 600ms

#### Scenario: Custom signal timing
- **WHEN** a `MorseTimingConfig` is created with error buzz=800ms
- **THEN** the error buzz duration is 800ms and all other values remain at defaults

### Requirement: Play Morse pattern as vibration
The system SHALL provide a `VibrationService` that can play a list of `MorseSymbol` values as a vibration sequence. Each dot SHALL vibrate for the configured dot duration, each dash for the configured dash duration, and symbols SHALL be separated by the configured inter-symbol gap (silence).

#### Scenario: Play single dot
- **WHEN** `playMorsePattern([dot])` is called
- **THEN** the device vibrates for 100ms (with default config)

#### Scenario: Play dot-dash sequence
- **WHEN** `playMorsePattern([dot, dash])` is called with default config
- **THEN** the device vibrates for 100ms, pauses 100ms, then vibrates for 300ms

#### Scenario: Play full letter pattern
- **WHEN** `playMorsePattern([dot, dot, dot])` is called (letter S) with default config
- **THEN** the device vibrates 100ms, pauses 100ms, vibrates 100ms, pauses 100ms, vibrates 100ms

### Requirement: Play success signal
The `VibrationService` SHALL provide a `playSuccess()` method that vibrates the configured success pattern: a series of quick pulses (default: 3 pulses of 80ms with 80ms gaps between them).

#### Scenario: Success signal with default config
- **WHEN** `playSuccess()` is called with default config
- **THEN** the device vibrates 80ms, pauses 80ms, vibrates 80ms, pauses 80ms, vibrates 80ms

#### Scenario: Success signal is distinct from Morse patterns
- **WHEN** comparing the success vibration pattern to any single-letter Morse pattern
- **THEN** the success pattern (3 very short equal pulses) is tactilely distinct from Morse patterns (which mix dots and dashes of different lengths)

### Requirement: Play error signal
The `VibrationService` SHALL provide a `playError()` method that vibrates the configured error pattern: one long continuous buzz (default: 600ms).

#### Scenario: Error signal with default config
- **WHEN** `playError()` is called with default config
- **THEN** the device vibrates continuously for 600ms

#### Scenario: Error signal is distinct from Morse patterns
- **WHEN** comparing the error vibration to any Morse pattern
- **THEN** the error buzz (600ms continuous) is longer than any single Morse dash (300ms) making it tactilely distinct

### Requirement: VibrationService is abstract with injectable implementation
The `VibrationService` SHALL be defined as an abstract class. A concrete implementation using the `vibration` package SHALL be provided. The service SHALL be exposed through a Riverpod provider, allowing the implementation to be swapped for testing.

#### Scenario: Abstract service can be mocked
- **WHEN** writing a unit test that depends on `VibrationService`
- **THEN** the developer can provide a mock implementation without device vibration hardware

#### Scenario: Riverpod provider exposes the service
- **WHEN** a widget or provider needs vibration functionality
- **THEN** it can obtain `VibrationService` through a Riverpod provider

### Requirement: Vibration pattern generation is pure logic
The conversion from `MorseSymbol` list to vibration duration pattern (list of millisecond on/off durations) SHALL be a pure function, separate from the actual device vibration call. This enables unit testing the pattern generation without hardware.

#### Scenario: Pattern generation returns duration list
- **WHEN** generating a vibration pattern for `[dot, dash]` with default config
- **THEN** the result is a list of durations: `[0, 100, 100, 300]` (wait 0ms, vibrate 100ms, wait 100ms, vibrate 300ms) or equivalent format expected by the vibration package

#### Scenario: Pattern generation is testable without device
- **WHEN** calling the pattern generation function in a unit test
- **THEN** no device hardware or vibration permission is required
