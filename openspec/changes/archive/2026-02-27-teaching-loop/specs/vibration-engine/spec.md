## MODIFIED Requirements

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

## ADDED Requirements

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
