# vibration-engine Specification

## Purpose

Playing tactile token patterns (Morse today) and the app's signals as vibrations, through an injectable service that knows nothing of Morse.

## Requirements

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

### Requirement: Play success signal
The `VibrationService` SHALL provide a `playSuccess()` method that plays five short taps at full strength. The intensity version is five 50 ms taps with 40 ms of silence between them, 410 ms in all. The duration-only version, for a motor without amplitude control, is five 50 ms taps with 60 ms gaps, 490 ms in all (see *Signals follow the motor's amplitude control*). The call SHALL complete once the signal has finished.

#### Scenario: Success signal with default config
- **WHEN** `playSuccess()` is called on a motor with amplitude control, or whose amplitude control is unknown
- **THEN** the device SHALL play the segments `[50, 40, 50, 40, 50, 40, 50, 40, 50]` ms with the intensities `[255, 0, 255, 0, 255, 0, 255, 0, 255]`
- **AND** the call SHALL complete 410 ms later

#### Scenario: Success signal without amplitude control
- **WHEN** `playSuccess()` is called on a motor without amplitude control
- **THEN** the device SHALL play the segments `[0, 50, 60, 50, 60, 50, 60, 50, 60, 50]` ms with the intensities `[0, 255, 0, 255, 0, 255, 0, 255, 0, 255]`
- **AND** the call SHALL complete 490 ms later

#### Scenario: Success signal is distinct from Morse patterns
- **WHEN** comparing the success vibration to any Morse pattern
- **THEN** its 50 ms taps SHALL be shorter than a Morse dot (100 ms)
- **AND** its 40 ms or 60 ms gaps SHALL be shorter than any Morse gap (100 ms)
- **AND** so it is felt as faster than any Morse character, even the digit 5, which is also five equal elements

### Requirement: Play error signal
The `VibrationService` SHALL provide a `playError()` method that plays one long buzz at full strength. The intensity version is a single 500 ms vibration. The duration-only version, for a motor without amplitude control, is a 0 ms silence followed by a 700 ms vibration: without amplitude, length is the only contrast left (see *Signals follow the motor's amplitude control*). The call SHALL complete once the buzz has finished.

#### Scenario: Error signal with default config
- **WHEN** `playError()` is called on a motor with amplitude control, or whose amplitude control is unknown
- **THEN** the device SHALL play the segment `[500]` ms with the intensity `[255]`
- **AND** the call SHALL complete 500 ms later

#### Scenario: Error signal without amplitude control
- **WHEN** `playError()` is called on a motor without amplitude control
- **THEN** the device SHALL play the segments `[0, 700]` ms with the intensities `[0, 255]`
- **AND** the call SHALL complete 700 ms later

#### Scenario: Error signal is distinct from Morse and success patterns
- **WHEN** comparing the error vibration to Morse or success patterns
- **THEN** it SHALL be longer than a Morse dash (300 ms), and the duration-only version more than twice as long
- **AND** it SHALL have no gap, unlike the five taps of the success signal and every Morse character of more than one element

### Requirement: VibrationService is abstract with injectable implementation
The `VibrationService` SHALL be defined as an abstract class with methods for playing tactile tokens (`playTokens`, for the characters, words and markers a codec has encoded), the success and error signals, the cloud-off signal (`playCloudOff`), the tap feedback, and cancelling ongoing vibration. A concrete implementation using the `vibration` package SHALL be provided. The service SHALL be exposed through a Riverpod provider, allowing the implementation to be swapped for testing.

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

### Requirement: Play tap feedback
The `VibrationService` SHALL provide a `playTapFeedback()` method that vibrates once for 50 ms and completes once the vibration has finished. It confirms a bottom-strip tap (see `bottom-input-zone`). At half a Morse dot it is shorter than any Morse element, and as a single tap it cannot be mistaken for the five taps of the success signal.

#### Scenario: Tap feedback on the device
- **WHEN** `playTapFeedback()` is called on the device service
- **THEN** the device SHALL vibrate once for 50 ms at its default strength
- **AND** the call SHALL complete 50 ms later

#### Scenario: Tap feedback is shorter than a dot
- **WHEN** the tap feedback is compared with the default Morse timing
- **THEN** its 50 ms SHALL be half the 100 ms dot

### Requirement: Signals follow the motor's amplitude control
The success and error signals SHALL each have an intensity version and a duration-only version. The device service SHALL play the duration-only versions only on a motor that definitely lacks amplitude control (see `vibration-capability-gate`), and the intensity versions when amplitude control is present or unknown. It SHALL read the capabilities each time it plays a signal, so a detection that ends after launch takes effect without rebuilding the service.

#### Scenario: Amplitude control present
- **WHEN** the device reports amplitude control and a signal is played
- **THEN** the intensity version SHALL be played

#### Scenario: Amplitude control unknown
- **WHEN** amplitude control is unknown, or detection has not finished
- **THEN** the intensity version SHALL be played

#### Scenario: No amplitude control
- **WHEN** the device reports that its motor has no amplitude control
- **THEN** the duration-only version SHALL be played

#### Scenario: Detection ends after launch
- **WHEN** detection reports no amplitude control after the session started
- **THEN** the next success or error signal SHALL be the duration-only version

#### Scenario: Why the duration-only versions exist
- **WHEN** a motor without amplitude control is sent the intensity versions
- **THEN** the platform drops the intensities and reads the durations as alternating silence and vibration, starting with silence
- **AND** so the success signal would lose a tap and the error signal would not vibrate at all, which the duration-only versions avoid by starting with a 0 ms silence and using only the intensities 0 and 255

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

### Requirement: The vibration engine has no Morse dependency
The vibration engine SHALL depend only on the tactile tokens and its timing configuration. No code in the engine SHALL import or reference the Morse types (signals, tokens, alphabets, languages); codecs SHALL depend on the tactile tokens, never on the engine.

#### Scenario: No Morse types in the engine
- **WHEN** a developer searches the vibration engine's code for imports of the Morse code
- **THEN** there SHALL be none

#### Scenario: Engine and codec meet at tokens
- **WHEN** any part of the app plays a text
- **THEN** it SHALL encode the text with a codec and pass the resulting tokens to the vibration service

### Requirement: Play cloud-off signal
The `VibrationService` SHALL provide a `playCloudOff()` method that plays the cloud-off signal: two 700 ms buzzes at full strength with 300 ms of silence between them, 1700 ms in total. The signal SHALL rely on timing alone and SHALL be sent the same way whether or not the motor has amplitude control. The method SHALL complete once the signal has played.

#### Scenario: Cloud-off timing
- **WHEN** `playCloudOff()` is called on the device service
- **THEN** the device SHALL play the segments `[0, 700, 300, 700]` ms with the intensities `[0, 255, 0, 255]`: it vibrates for 700 ms, pauses for 300 ms, then vibrates for 700 ms

#### Scenario: Same signal on every motor
- **WHEN** `playCloudOff()` is called on a device with amplitude control, on one without it, and on one whose amplitude control is unknown
- **THEN** the same pattern SHALL be sent to the platform each time
- **AND** it SHALL be felt as two 700 ms buzzes whether or not the platform honours intensities, because it starts with a 0 ms silence and uses only the intensities 0 and 255

#### Scenario: Cloud-off is distinct from Morse and from the wrong signal
- **WHEN** comparing the cloud-off signal to Morse patterns and to the error signal
- **THEN** each of its buzzes SHALL be more than twice as long as a Morse dash
- **AND** it SHALL have two buzzes where the error signal, in both its versions, has one

#### Scenario: Completes after the signal
- **WHEN** `playCloudOff()` is called and awaited
- **THEN** it SHALL complete no earlier than 1700 ms after the call
