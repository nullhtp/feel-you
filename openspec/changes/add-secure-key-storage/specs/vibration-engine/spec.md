## ADDED Requirements

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

## MODIFIED Requirements

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
