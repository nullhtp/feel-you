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

### Requirement: Configurable signal vibration timing
The `MorseTimingConfig` SHALL also define signal vibration timing with defaults: signal duration 400ms, signal steps 4. Both success and error signals share the same duration and step count but differ in intensity direction. All values SHALL be overridable.

#### Scenario: Default signal timing values
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** signal duration is 400ms and signal steps is 4

#### Scenario: Custom signal timing
- **WHEN** a `MorseTimingConfig` is created with signal duration=600ms
- **THEN** the signal duration is 600ms and all other values remain at defaults

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

### Requirement: Play success signal
The `VibrationService` SHALL provide a `playSuccess()` method that vibrates a continuous signal with rising intensity. The signal duration is split into steps, with amplitude ramping linearly from low (1) to high (255). With defaults (400ms, 4 steps): 4 segments of 100ms at intensities 64, 128, 191, 255.

#### Scenario: Success signal with default config
- **WHEN** `playSuccess()` is called with default config
- **THEN** the device vibrates continuously for 400ms with intensity rising from low to max

#### Scenario: Success signal is distinct from Morse patterns
- **WHEN** comparing the success vibration to any Morse pattern
- **THEN** the success signal (continuous rising intensity) is tactilely distinct from Morse patterns (on/off at constant intensity)

### Requirement: Play error signal
The `VibrationService` SHALL provide a `playError()` method that vibrates a continuous signal with falling intensity. The signal duration is split into steps, with amplitude ramping linearly from high (255) to low (1). With defaults (400ms, 4 steps): 4 segments of 100ms at intensities 255, 191, 128, 64.

#### Scenario: Error signal with default config
- **WHEN** `playError()` is called with default config
- **THEN** the device vibrates continuously for 400ms with intensity falling from max to low

#### Scenario: Error signal is distinct from Morse and success patterns
- **WHEN** comparing the error vibration to Morse or success patterns
- **THEN** the error signal (continuous falling intensity) is the opposite of success (rising) and tactilely distinct from Morse (on/off at constant intensity)

### Requirement: VibrationService is abstract with injectable implementation
The `VibrationService` SHALL be defined as an abstract class with methods for playing Morse patterns, success signals, error signals, and cancelling ongoing vibration. A concrete implementation using the `vibration` package SHALL be provided. The service SHALL be exposed through a Riverpod provider, allowing the implementation to be swapped for testing.

#### Scenario: Abstract service can be mocked
- **WHEN** writing a unit test that depends on `VibrationService`
- **THEN** the developer can provide a mock implementation without device vibration hardware

#### Scenario: Riverpod provider exposes the service
- **WHEN** a widget or provider needs vibration functionality
- **THEN** it can obtain `VibrationService` through a Riverpod provider

#### Scenario: Cancel stops ongoing vibration
- **WHEN** `cancel()` is called on the vibration service
- **THEN** any ongoing vibration pattern is stopped immediately
- **AND** the method returns a `Future<void>` that completes when cancellation is done

### Requirement: Cancel ongoing vibration
The `VibrationService` SHALL provide a `cancel()` method that stops any currently playing vibration pattern. The `DeviceVibrationService` SHALL implement this via `Vibration.cancel()`.

#### Scenario: Cancel during Morse pattern playback
- **WHEN** `playMorsePattern` is in progress
- **AND** `cancel()` is called
- **THEN** the vibration stops

#### Scenario: Cancel when no vibration is playing
- **WHEN** no vibration is currently active
- **AND** `cancel()` is called
- **THEN** the call completes without error (no-op)

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
