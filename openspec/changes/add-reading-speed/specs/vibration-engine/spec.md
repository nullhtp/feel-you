## MODIFIED Requirements

### Requirement: Configurable Morse vibration timing
The system SHALL define Morse vibration timing through a configuration object (`MorseTimingConfig`) with the following default values: dot duration 100ms, dash duration 300ms, inter-symbol gap 100ms, inter-character gap 300ms, inter-word gap 700ms. The inter-character and inter-word gaps SHALL be independent of each other. All values SHALL be overridable at construction time, and a copy SHALL be able to replace any of them.

#### Scenario: Default timing values
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** dot is 100ms, dash is 300ms, inter-symbol gap is 100ms, inter-character gap is 300ms, and inter-word gap is 700ms

#### Scenario: Custom timing values
- **WHEN** a `MorseTimingConfig` is created with dot=150ms, dash=450ms, gap=120ms, interCharGap=400ms, interWordGap=900ms
- **THEN** those custom values are used instead of defaults

#### Scenario: Default inter-character gap follows ITU standard
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** the inter-character gap (300ms) SHALL be 3 times the dot duration (100ms)

#### Scenario: Default inter-word gap follows ITU standard
- **WHEN** a `MorseTimingConfig` is created with no arguments
- **THEN** the inter-word gap (700ms) SHALL be 7 times the dot duration (100ms)

#### Scenario: Gaps change independently
- **WHEN** a copy of the default config replaces only the inter-word gap, with 1000ms
- **THEN** the inter-character gap SHALL stay 300ms and every other value SHALL stay as it was

### Requirement: Vibration pattern generation is pure logic
The conversion from a list of tactile tokens to a vibration duration pattern (millisecond durations alternating wait and vibrate, starting with a wait) SHALL be a pure function, separate from the actual device vibration call. A character gap SHALL produce a silence of `interCharGap` duration, consecutive silences SHALL merge into one wait, and tokens without a pulse SHALL produce an empty pattern. This enables unit testing the pattern generation without hardware.

#### Scenario: Pattern generation returns duration list
- **WHEN** generating a vibration pattern for `[shortPulse, longPulse]` with default config
- **THEN** the result is a list of durations: `[0, 100, 100, 300]` (wait 0ms, vibrate 100ms, wait 100ms, vibrate 300ms), the format expected by the vibration package

#### Scenario: Pattern generation handles charGap
- **WHEN** generating a vibration pattern for `[shortPulse, shortPulse, characterGap, longPulse]` with default config
- **THEN** the character gap produces a silence of 300ms between the last short pulse and the long pulse, replacing the normal inter-symbol gap at that position: `[0, 100, 100, 100, 300, 300]`

#### Scenario: Silences merge into one wait
- **WHEN** generating a vibration pattern for `[emptySlot, shortPulse]` with default config
- **THEN** the result is `[200, 100]`: the empty slot and the inter-symbol gap make one 200ms wait before the pulse

#### Scenario: Pattern without a pulse is empty
- **WHEN** generating a vibration pattern for `[characterGap]` or `[emptySlot]`
- **THEN** the result is empty, so no pattern made only of silence is ever sent to the device

#### Scenario: Pattern generation is testable without device
- **WHEN** calling the pattern generation function in a unit test
- **THEN** no device hardware or vibration permission is required

#### Scenario: Pattern generation handles a word gap
- **WHEN** generating a vibration pattern for `[shortPulse, wordGap, longPulse]` with default config
- **THEN** the word gap produces a silence of 700ms in place of the inter-symbol gap: `[0, 100, 700, 300]`
- **AND** `[wordGap]` alone produces an empty pattern

### Requirement: Play tactile tokens as vibration
The `VibrationService` SHALL play a list of tactile tokens as one vibration pattern and complete once it has played. A short pulse SHALL vibrate for the dot duration, a long pulse for the dash duration, and an empty slot SHALL be silent for the dot duration. Consecutive slots SHALL be separated by the inter-symbol gap; a character gap SHALL be a silence of the inter-character gap in its place, and a word gap a silence of the inter-word gap.

#### Scenario: Play single short pulse
- **WHEN** `playTokens([shortPulse])` is called with the default config
- **THEN** the device vibrates for 100ms

#### Scenario: Play short-long sequence
- **WHEN** `playTokens([shortPulse, longPulse])` is called with the default config (Morse A)
- **THEN** the device vibrates for 100ms, pauses 100ms, then vibrates for 300ms

#### Scenario: Play full letter pattern
- **WHEN** `playTokens([shortPulse, shortPulse, shortPulse])` is called with the default config (Morse S)
- **THEN** the device vibrates 100ms, pauses 100ms, vibrates 100ms, pauses 100ms, vibrates 100ms

#### Scenario: Play word pattern with character gap
- **WHEN** `playTokens([shortPulse, shortPulse, characterGap, longPulse])` is called with the default config (Morse IT)
- **THEN** the device vibrates 100ms, pauses 100ms, vibrates 100ms, pauses 300ms, vibrates 300ms

#### Scenario: Character gap produces silence not vibration
- **WHEN** a character gap is encountered in the tokens
- **THEN** no vibration is produced, only a silence of `interCharGap` (300ms by default) in place of the inter-symbol gap

#### Scenario: Empty slot produces silence
- **WHEN** `playTokens([shortPulse, emptySlot, shortPulse])` is called with the default config
- **THEN** the device vibrates 100ms, stays silent for 300ms (gap, empty slot, gap), then vibrates 100ms

#### Scenario: A run of pulses has only inter-symbol gaps
- **WHEN** nine pulses with no character gap are played (three short, three long, three short)
- **THEN** every pause between them is the 100ms inter-symbol gap

#### Scenario: Play two words with a word gap
- **WHEN** the tokens of "E T" (`[shortPulse, wordGap, longPulse]`) are played on the device service with the default config
- **THEN** it SHALL send the durations `[0, 100, 700, 300]` ms with the intensities `[0, 255, 0, 255]`: the device vibrates 100ms, pauses 700ms, then vibrates 300ms
