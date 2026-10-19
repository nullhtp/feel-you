## ADDED Requirements

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
The device service SHALL send every Morse pattern with one intensity per segment: 0 for every silence, including the leading 0 ms wait, and 255 for every vibration. It SHALL do so whether or not the motor has amplitude control. Without them the iOS plugin vibrates through the gaps, and a letter is felt as one long buzz. A call SHALL complete only once the whole pattern has played. An empty pattern SHALL not vibrate.

#### Scenario: A letter
- **WHEN** `playMorsePattern([dot, dash])` is called on the device service with the default timing
- **THEN** it SHALL send the durations `[0, 100, 100, 300]` ms with the intensities `[0, 255, 0, 255]`
- **AND** the call SHALL complete 500 ms later

#### Scenario: A word
- **WHEN** the token pattern of "IT" (`[dot, dot, charGap, dash]`) is played with the default timing
- **THEN** it SHALL send the durations `[0, 100, 100, 100, 300, 300]` ms with the intensities `[0, 255, 0, 255, 0, 255]`

#### Scenario: No amplitude control
- **WHEN** a Morse pattern is played on a motor without amplitude control
- **THEN** the same intensities SHALL still be sent

#### Scenario: Empty pattern
- **WHEN** an empty pattern is played
- **THEN** nothing SHALL vibrate and the call SHALL complete at once

## MODIFIED Requirements

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
The `VibrationService` SHALL be defined as an abstract class with methods for playing Morse patterns (`playMorsePattern` for a character's signals, `playMorseTokenPattern` for a word with its letter gaps), the success and error signals, the tap feedback, and cancelling ongoing vibration. A concrete implementation using the `vibration` package SHALL be provided. The service SHALL be exposed through a Riverpod provider, allowing the implementation to be swapped for testing.

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

## REMOVED Requirements

### Requirement: Configurable signal vibration timing
**Reason**: `MorseTimingConfig` has no signal duration or step count, and success and error do not share them. The signals are fixed patterns, because their rhythm does not reduce to a duration and a number of steps.
**Migration**: None in code. The signal timings are in *Play success signal*, *Play error signal* and *Signals follow the motor's amplitude control*.
