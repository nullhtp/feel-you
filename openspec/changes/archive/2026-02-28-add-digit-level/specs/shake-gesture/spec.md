## ADDED Requirements

### Requirement: ShakeDetector listens to accelerometer
The system SHALL create a `ShakeDetector` class that subscribes to the device accelerometer stream (via `sensors_plus` package). It SHALL compute the acceleration magnitude from x, y, z values and detect shakes when the magnitude exceeds a configurable threshold.

#### Scenario: ShakeDetector subscribes to accelerometer on creation
- **WHEN** a `ShakeDetector` is created
- **THEN** it SHALL subscribe to the accelerometer event stream

#### Scenario: ShakeDetector can be disposed
- **WHEN** `dispose()` is called on the `ShakeDetector`
- **THEN** the accelerometer subscription SHALL be cancelled

### Requirement: Shake detection emits Home event
The `ShakeDetector` SHALL emit a `Home` gesture event on its `events` stream when a shake is detected. A shake is detected when the acceleration magnitude exceeds the configured threshold (default: 15 m/s^2, accounting for gravity subtraction).

#### Scenario: Shake exceeds threshold
- **WHEN** the accelerometer reports a magnitude exceeding 15 m/s^2 (after gravity)
- **THEN** the `ShakeDetector` SHALL emit a `Home` event

#### Scenario: Normal movement below threshold
- **WHEN** the accelerometer reports magnitudes below 15 m/s^2
- **THEN** no `Home` event SHALL be emitted

### Requirement: Shake cooldown prevents repeat triggers
The `ShakeDetector` SHALL enforce a cooldown period (default: 1000ms) after emitting a `Home` event. During cooldown, no additional `Home` events SHALL be emitted regardless of accelerometer readings.

#### Scenario: Rapid shaking triggers only once
- **WHEN** the user shakes the phone continuously for 3 seconds
- **THEN** only one `Home` event SHALL be emitted per cooldown period (e.g., at most 3 events with 1000ms cooldown)

#### Scenario: Shake after cooldown triggers again
- **WHEN** the user shakes, waits 1000ms, then shakes again
- **THEN** two `Home` events SHALL be emitted

### Requirement: Configurable shake thresholds
The `ShakeDetector` SHALL accept a `ShakeConfig` with configurable threshold (default: 15 m/s^2) and cooldown (default: 1000ms). All values SHALL be overridable at construction time.

#### Scenario: Default config values
- **WHEN** a `ShakeConfig` is created with no arguments
- **THEN** the threshold SHALL be 15 m/s^2 and the cooldown SHALL be 1000ms

#### Scenario: Custom config values
- **WHEN** a `ShakeConfig` is created with threshold=20 and cooldown=2000ms
- **THEN** those custom values SHALL be used

### Requirement: ShakeDetector gracefully handles missing sensor
The `ShakeDetector` SHALL handle the case where the accelerometer is unavailable (no events from the stream or stream error). It SHALL not crash; instead, it SHALL simply never emit `Home` events.

#### Scenario: No accelerometer available
- **WHEN** the accelerometer stream emits an error or no events
- **THEN** the `ShakeDetector` SHALL not crash and SHALL not emit any events

### Requirement: ShakeDetector exposed via Riverpod provider
The `ShakeDetector` SHALL be accessible through a Riverpod provider. The provider SHALL auto-dispose and cancel the accelerometer subscription when no longer used.

#### Scenario: Provider creates ShakeDetector
- **WHEN** the shake detector provider is read
- **THEN** it SHALL return a `ShakeDetector` instance subscribed to the accelerometer

#### Scenario: Provider disposes cleanly
- **WHEN** the shake detector provider is disposed
- **THEN** the accelerometer subscription SHALL be cancelled
