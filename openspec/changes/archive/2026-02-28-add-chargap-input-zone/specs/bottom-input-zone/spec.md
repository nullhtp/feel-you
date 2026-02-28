## ADDED Requirements

### Requirement: Bottom input zone occupies lower 15% of screen
The touch surface SHALL define a bottom input zone spanning the full screen width and the lower 15% of the screen height. The zone boundary SHALL be calculated as `screenHeight * 0.85` — taps with a Y position greater than or equal to this boundary are in the bottom zone.

#### Scenario: Tap in bottom zone detected
- **WHEN** the screen height is 400 logical pixels (landscape)
- **AND** the user taps at y-position 350
- **THEN** the tap SHALL be classified as a bottom-zone action (350 >= 400 * 0.85 = 340)

#### Scenario: Tap above bottom zone is not a bottom-zone action
- **WHEN** the screen height is 400 logical pixels
- **AND** the user taps at y-position 300
- **THEN** the tap SHALL NOT be classified as a bottom-zone action (300 < 340)

#### Scenario: Tap exactly at boundary is a bottom-zone action
- **WHEN** the screen height is 400 logical pixels
- **AND** the user taps at y-position 340
- **THEN** the tap SHALL be classified as a bottom-zone action (340 >= 340)

### Requirement: Bottom zone emits BottomZoneAction event on tap
When the user performs a short tap (non-swipe, non-reset) in the bottom zone, the system SHALL emit a `BottomZoneAction` gesture event on the classifier's event stream. The event SHALL be emitted on touch-up, after confirming the gesture is a tap (not a swipe or long hold).

#### Scenario: Short tap in bottom zone emits event
- **WHEN** the user taps in the bottom zone and lifts their finger within the reset threshold
- **AND** the touch displacement is below the swipe threshold
- **THEN** a `BottomZoneAction` event SHALL be emitted on the gesture event stream

#### Scenario: Swipe starting in bottom zone is not a bottom-zone action
- **WHEN** the user touches in the bottom zone and swipes horizontally with distance > 50px and velocity > 200px/s
- **THEN** the system SHALL emit a navigation event (NavigateNext/NavigatePrevious), NOT a BottomZoneAction

#### Scenario: Long hold in bottom zone triggers reset
- **WHEN** the user touches in the bottom zone and holds for more than 2000ms
- **THEN** the system SHALL emit a Reset event, NOT a BottomZoneAction

### Requirement: BottomZoneAction is a GestureEvent subtype
The system SHALL define a `BottomZoneAction` class as a sealed subtype of `GestureEvent`. It SHALL carry no data (it is a marker event). It SHALL be included in exhaustive match expressions alongside existing event types.

#### Scenario: BottomZoneAction is exhaustively matchable
- **WHEN** a developer writes a switch/match on `GestureEvent`
- **THEN** the compiler SHALL warn if `BottomZoneAction` is not handled

#### Scenario: BottomZoneAction equality
- **WHEN** two `BottomZoneAction` instances are compared
- **THEN** they SHALL be equal (value equality via Equatable)

### Requirement: Haptic feedback on bottom zone tap
The system SHALL trigger a short haptic vibration pulse (~50ms) immediately when a bottom-zone tap is detected (on touch-up, before emitting the event). This provides tactile confirmation to the user.

#### Scenario: Haptic pulse on bottom zone tap
- **WHEN** the user taps in the bottom zone (non-swipe, non-reset)
- **THEN** a short vibration pulse (~50ms) SHALL be triggered
- **AND** the vibration SHALL occur before the BottomZoneAction event is emitted

#### Scenario: No haptic pulse on swipe through bottom zone
- **WHEN** the user swipes through the bottom zone
- **THEN** no haptic pulse SHALL be triggered for the bottom zone

### Requirement: Level-aware behavior in teaching orchestrator
The `TeachingOrchestrator` SHALL handle `BottomZoneAction` events differently based on the current level:
- On the **words level** (level index 2): insert a `charGap` symbol into the gesture classifier's input buffer and emit a `MorseInput(charGap)` event
- On **other levels** (digits, letters): immediately trigger `InputComplete` with the current accumulated input buffer

#### Scenario: Bottom zone tap on words level inserts charGap
- **WHEN** the current level is words (index 2)
- **AND** the user has entered `[dot, dot]` and taps the bottom zone
- **THEN** a `charGap` symbol SHALL be added to the input buffer
- **AND** the input buffer becomes `[dot, dot, charGap]`
- **AND** the silence timer SHALL be restarted

#### Scenario: Bottom zone tap on letters level triggers InputComplete
- **WHEN** the current level is letters (index 1)
- **AND** the user has entered `[dot, dash]` and taps the bottom zone
- **THEN** an `InputComplete([dot, dash])` event SHALL be emitted
- **AND** the input buffer SHALL be cleared

#### Scenario: Bottom zone tap on digits level triggers InputComplete
- **WHEN** the current level is digits (index 0)
- **AND** the user has entered `[dash, dash, dash]` and taps the bottom zone
- **THEN** an `InputComplete([dash, dash, dash])` event SHALL be emitted
- **AND** the input buffer SHALL be cleared

#### Scenario: Bottom zone tap with empty buffer on non-words level
- **WHEN** the current level is letters
- **AND** no Morse input has been entered (empty buffer)
- **AND** the user taps the bottom zone
- **THEN** no `InputComplete` event SHALL be emitted (nothing to submit)

#### Scenario: Bottom zone tap with empty buffer on words level
- **WHEN** the current level is words
- **AND** no Morse input has been entered (empty buffer)
- **AND** the user taps the bottom zone
- **THEN** no `charGap` SHALL be inserted (cannot start with a charGap)

### Requirement: GestureClassifier exposes methods for explicit charGap and submit
The `GestureClassifier` SHALL expose two new public methods:
- `insertCharGap()`: Adds a `charGap` symbol to the input buffer and restarts the silence timer
- `submitInput()`: Immediately emits `InputComplete` with the current buffer contents and clears the buffer

These methods allow external callers (via the orchestrator) to manipulate the input buffer in response to bottom-zone taps.

#### Scenario: insertCharGap adds to buffer and restarts timer
- **WHEN** the input buffer contains `[dot, dash]`
- **AND** `insertCharGap()` is called
- **THEN** the buffer becomes `[dot, dash, charGap]`
- **AND** the silence timer is restarted

#### Scenario: insertCharGap on empty buffer does nothing
- **WHEN** the input buffer is empty
- **AND** `insertCharGap()` is called
- **THEN** the buffer remains empty
- **AND** no event is emitted

#### Scenario: submitInput emits InputComplete and clears buffer
- **WHEN** the input buffer contains `[dot, dot, charGap, dash]`
- **AND** `submitInput()` is called
- **THEN** an `InputComplete([dot, dot, charGap, dash])` event SHALL be emitted
- **AND** the buffer SHALL be cleared
- **AND** the silence timer SHALL be cancelled

#### Scenario: submitInput on empty buffer does nothing
- **WHEN** the input buffer is empty
- **AND** `submitInput()` is called
- **THEN** no event is emitted
- **AND** the buffer remains empty
