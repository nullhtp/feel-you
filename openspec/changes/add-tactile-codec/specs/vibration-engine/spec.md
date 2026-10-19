## REMOVED Requirements

### Requirement: Play Morse pattern as vibration
**Reason**: The vibration engine no longer knows Morse. It plays tactile tokens, which a codec produces from text; the Morse alphabet lives in the Morse codec. See "Play tactile tokens as vibration" below and the `tactile-codec` capability.
**Migration**: Replace `playMorsePattern(signals)` and `playMorseTokenPattern(tokens)` with `playTokens(codec.encode(text))`, using the codec of the session language (`tactileCodecProvider`). A dot is a short pulse, a dash a long pulse and a `CharGap` a character gap; the durations are unchanged.

## ADDED Requirements

### Requirement: Play tactile tokens as vibration
The `VibrationService` SHALL play a list of tactile tokens as one vibration pattern and complete once it has played. A short pulse SHALL vibrate for the dot duration, a long pulse for the dash duration, and an empty slot SHALL be silent for the dot duration. Consecutive slots SHALL be separated by the inter-symbol gap; a character gap SHALL be a silence of the inter-character gap in its place.

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

### Requirement: The vibration engine has no Morse dependency
The vibration engine SHALL depend only on the tactile tokens and its timing configuration. No code in the engine SHALL import or reference the Morse types (signals, tokens, alphabets, languages); codecs SHALL depend on the tactile tokens, never on the engine.

#### Scenario: No Morse types in the engine
- **WHEN** a developer searches the vibration engine's code for imports of the Morse code
- **THEN** there SHALL be none

#### Scenario: Engine and codec meet at tokens
- **WHEN** any part of the app plays a text
- **THEN** it SHALL encode the text with a codec and pass the resulting tokens to the vibration service

## MODIFIED Requirements

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

### Requirement: VibrationService is abstract with injectable implementation
The `VibrationService` SHALL be defined as an abstract class with methods for playing tactile tokens (`playTokens`, for the characters, words and markers a codec has encoded), the success and error signals, the tap feedback, and cancelling ongoing vibration. A concrete implementation using the `vibration` package SHALL be provided. The service SHALL be exposed through a Riverpod provider, allowing the implementation to be swapped for testing.

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
- **WHEN** `playTokens` is in progress, for example playing a Morse letter
- **AND** `cancel()` is called
- **THEN** the vibration stops

#### Scenario: Cancel when no vibration is playing
- **WHEN** no vibration is currently active
- **AND** `cancel()` is called
- **THEN** the call completes without error (no-op)

### Requirement: Morse patterns are sent with explicit intensities
The device service SHALL send every tactile pattern, Morse included, with one intensity per segment: 0 for every silence, including the leading wait, and 255 for every vibration. It SHALL do so whether or not the motor has amplitude control. Without them the iOS plugin vibrates through the gaps, and a letter is felt as one long buzz. A call SHALL complete only once the whole pattern has played. An empty pattern, or tokens without a pulse, SHALL not vibrate.

#### Scenario: A letter
- **WHEN** `playTokens([shortPulse, longPulse])` (Morse A) is called on the device service with the default timing
- **THEN** it SHALL send the durations `[0, 100, 100, 300]` ms with the intensities `[0, 255, 0, 255]`
- **AND** the call SHALL complete 500 ms later

#### Scenario: A word
- **WHEN** the tokens of "IT" (`[shortPulse, shortPulse, characterGap, longPulse]`) are played with the default timing
- **THEN** it SHALL send the durations `[0, 100, 100, 100, 300, 300]` ms with the intensities `[0, 255, 0, 255, 0, 255]`

#### Scenario: No amplitude control
- **WHEN** a Morse pattern is played on a motor without amplitude control
- **THEN** the same intensities SHALL still be sent

#### Scenario: Empty pattern
- **WHEN** an empty token list, or one with only character gaps and empty slots, is played
- **THEN** nothing SHALL vibrate and the call SHALL complete at once
