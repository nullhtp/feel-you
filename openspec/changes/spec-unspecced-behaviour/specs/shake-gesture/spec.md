## ADDED Requirements

### Requirement: Double shake emits ChangeLanguage
The `ShakeDetector` SHALL recognise a double shake: a second shake that starts at most `doubleShakeWindow` after the first one ended. A shake ends at its last reading above the threshold, and only a reading after at least `shakeSettle` without one starts a new shake. The first shake SHALL emit `Home` at once, as any shake does. The second SHALL emit `ChangeLanguage` instead of `Home`, despite the cooldown, and restart the cooldown. A third shake SHALL start a new pair.

#### Scenario: Double shake timing
- **WHEN** the default `ShakeConfig` is used
- **THEN** the timing of a double shake SHALL be:
  - a shake: readings above 15 m/s² (after gravity), which the default sensor stream delivers every 200 ms
  - `shakeSettle`, 700 ms: the shortest quiet spell that separates two shakes, so two missed readings in a row (600 ms) do not split a shake
  - `doubleShakeWindow`, 1500 ms: the longest quiet spell between the end of the first shake and the start of the second
  - so a double shake is: shake, pause for 0.7 to 1.5 s, shake again

#### Scenario: Two shakes within the window
- **WHEN** the user shakes with strong readings at 0, 200 and 400 ms
- **AND** shakes again with strong readings from 1200 ms, 800 ms after the first shake ended
- **THEN** the detector SHALL emit `Home` at 0 ms and `ChangeLanguage` at 1200 ms, and nothing else

#### Scenario: The first shake does not wait for a second
- **WHEN** the first strong reading of a shake arrives
- **THEN** `Home` SHALL be emitted at once, not after the double-shake window

#### Scenario: Second shake at the edge of the window
- **WHEN** the second shake starts exactly 1500 ms after the first one ended
- **THEN** it SHALL emit `ChangeLanguage`

#### Scenario: Pause longer than the window
- **WHEN** the second shake starts 1600 ms after the first one ended
- **THEN** each shake SHALL emit `Home`, and no `ChangeLanguage` SHALL be emitted

#### Scenario: Pause shorter than the settle time
- **WHEN** a shake misses two readings in a row (600 ms without a strong reading) and then goes on
- **THEN** it SHALL count as one shake and emit only one `Home`

#### Scenario: One long vigorous shake
- **WHEN** the user shakes for 3 s without a quiet spell of 700 ms
- **THEN** no `ChangeLanguage` SHALL be emitted
- **AND** `Home` MAY be emitted again each time the cooldown has passed

#### Scenario: A third shake starts a new pair
- **WHEN** the user shakes four times, each shake starting 800 ms after the previous one ended
- **THEN** the detector SHALL emit `Home`, `ChangeLanguage`, `Home`, `ChangeLanguage`

### Requirement: Shake detection can be paused
The `ShakeDetector` SHALL provide `pause()` and `resume()`. While paused it SHALL emit no events. With a broadcast accelerometer stream, as the default one is, `pause()` SHALL unsubscribe so the platform can stop the sensor, and `resume()` SHALL subscribe again. A single-subscription stream stays subscribed, and its readings SHALL be dropped while paused. A shake before a pause SHALL never pair with one after it. Both calls SHALL be idempotent and do nothing after `dispose()`.

#### Scenario: No events while paused
- **WHEN** the detector is paused and the phone is shaken
- **THEN** no `Home` or `ChangeLanguage` SHALL be emitted

#### Scenario: Pausing releases the sensor
- **WHEN** a detector on a broadcast accelerometer stream is paused
- **THEN** it SHALL no longer be subscribed to the stream, and it SHALL subscribe again on `resume()`

#### Scenario: Shakes while paused are not replayed
- **WHEN** the phone is shaken while the detector is paused and the detector is then resumed
- **THEN** no event SHALL be emitted for those shakes
- **AND** a shake after the resume SHALL emit `Home`

#### Scenario: A pause breaks a pair
- **WHEN** the user shakes, the detector is paused and resumed, and the user shakes again 800 ms after the first shake ended
- **THEN** the second shake SHALL emit `Home`, not `ChangeLanguage`

## MODIFIED Requirements

### Requirement: Shake cooldown prevents repeat triggers
The `ShakeDetector` SHALL enforce a cooldown period (default: 1000ms) after emitting a `Home` or `ChangeLanguage` event. During cooldown, no additional `Home` events SHALL be emitted regardless of accelerometer readings. Only the second shake of a double shake can emit during the cooldown, and it emits `ChangeLanguage` (see *Double shake emits ChangeLanguage*).

#### Scenario: Rapid shaking triggers only once
- **WHEN** the user shakes the phone continuously for 3 seconds
- **THEN** only one `Home` event SHALL be emitted per cooldown period (e.g., at most 3 events with 1000ms cooldown)
- **AND** no `ChangeLanguage` SHALL be emitted

#### Scenario: Shake after cooldown triggers again
- **WHEN** the user shakes, then shakes again more than 1500ms after the first shake ended
- **THEN** two `Home` events SHALL be emitted

### Requirement: Configurable shake thresholds
The `ShakeDetector` SHALL accept a `ShakeConfig` with a configurable threshold (default: 15 m/s^2), cooldown (default: 1000ms), settle time (`shakeSettle`, default: 700ms) and double-shake window (`doubleShakeWindow`, default: 1500ms). All values SHALL be overridable at construction time.

#### Scenario: Default config values
- **WHEN** a `ShakeConfig` is created with no arguments
- **THEN** the threshold SHALL be 15 m/s^2, the cooldown 1000ms, the settle time 700ms and the double-shake window 1500ms

#### Scenario: Custom config values
- **WHEN** a `ShakeConfig` is created with threshold=20 and cooldown=2000ms
- **THEN** those custom values SHALL be used
- **AND** the settle time and the double-shake window SHALL keep their defaults

#### Scenario: Custom double-shake timing
- **WHEN** a `ShakeConfig` is created with a settle time of 100ms and a double-shake window of 300ms
- **THEN** a second shake starting 200ms after the first one ended SHALL emit `ChangeLanguage`

### Requirement: ShakeDetector exposed via Riverpod provider
The `ShakeDetector` SHALL be accessible through a Riverpod provider, built from the `ShakeConfig` provider. The provider SHALL dispose the detector, cancelling the accelerometer subscription, when the provider is disposed.

#### Scenario: Provider creates ShakeDetector
- **WHEN** the shake detector provider is read
- **THEN** it SHALL return a `ShakeDetector` instance subscribed to the accelerometer

#### Scenario: Provider disposes cleanly
- **WHEN** the shake detector provider is disposed
- **THEN** the accelerometer subscription SHALL be cancelled
