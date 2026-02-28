## ADDED Requirements

### Requirement: Classify vertical swipe as level navigation
The system SHALL classify a vertical swipe gesture as level navigation: swipe up emits `NavigateUp`, swipe down emits `NavigateDown`. A vertical swipe SHALL only be recognized if it exceeds both the configured minimum distance (default: 50px) and minimum velocity (default: 200px/s). Vertical swipe detection SHALL use the same thresholds as horizontal swipe detection.

#### Scenario: Swipe up navigates to next level
- **WHEN** a user swipes up with vertical distance > 50px and velocity > 200px/s
- **THEN** the system emits a `NavigateUp` event

#### Scenario: Swipe down navigates to previous level
- **WHEN** a user swipes down with vertical distance > 50px and velocity > 200px/s
- **THEN** the system emits a `NavigateDown` event

#### Scenario: Slow vertical swipe is ignored
- **WHEN** a user swipes up with distance > 50px but velocity < 200px/s
- **THEN** no level navigation event is emitted

#### Scenario: Short vertical swipe is ignored
- **WHEN** a user swipes up with distance < 50px
- **THEN** no level navigation event is emitted

### Requirement: Dominant axis determines swipe direction
When a touch gesture has both horizontal and vertical displacement, the system SHALL classify it based on the dominant axis (the axis with the larger absolute displacement). This prevents diagonal swipes from triggering both horizontal and vertical navigation.

#### Scenario: Diagonal swipe favoring horizontal
- **WHEN** a user swipes with horizontal displacement 80px and vertical displacement 30px
- **THEN** the system classifies it as a horizontal swipe (NavigateNext or NavigatePrevious) not a vertical swipe

#### Scenario: Diagonal swipe favoring vertical
- **WHEN** a user swipes with horizontal displacement 30px and vertical displacement 80px
- **THEN** the system classifies it as a vertical swipe (NavigateUp or NavigateDown) not a horizontal swipe

#### Scenario: Equal displacement favors horizontal
- **WHEN** a user swipes with equal horizontal and vertical displacement
- **THEN** the system SHALL classify it as a horizontal swipe (horizontal takes precedence)

### Requirement: RawTouchEvent includes Y position
The `TouchDown` and `TouchUp` events SHALL include a `y` position field (in addition to the existing `x` position) to support vertical swipe detection.

#### Scenario: TouchDown includes y position
- **WHEN** a `TouchDown` event is created
- **THEN** it SHALL have both `x` and `y` position fields

#### Scenario: TouchUp includes y position
- **WHEN** a `TouchUp` event is created
- **THEN** it SHALL have both `x` and `y` position fields

## MODIFIED Requirements

### Requirement: Gesture event type hierarchy
The system SHALL define a `GestureEvent` type with the following subtypes: `MorseInput` (contains a `MorseSymbol`), `InputComplete` (contains a `List<MorseSymbol>`), `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, and `Home`. These types SHALL be exhaustively matchable (e.g., via sealed class or equivalent).

#### Scenario: All event types are defined
- **WHEN** a developer inspects the `GestureEvent` type hierarchy
- **THEN** exactly eight subtypes exist: `MorseInput`, `InputComplete`, `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, `Home`

#### Scenario: MorseInput carries symbol data
- **WHEN** a `MorseInput` event is created
- **THEN** it contains a `MorseSymbol` value (dot or dash)

#### Scenario: InputComplete carries accumulated symbols
- **WHEN** an `InputComplete` event is created
- **THEN** it contains a `List<MorseSymbol>` representing the full input sequence

#### Scenario: Events are exhaustively matchable
- **WHEN** a developer writes a switch/match on `GestureEvent`
- **THEN** the compiler warns if any subtype is not handled

### Requirement: Input buffer resets on navigation and reset
The accumulated Morse input buffer SHALL be cleared when a `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, or `NavigateDown` event occurs. This prevents stale input from carrying over between characters or levels.

#### Scenario: Swipe clears accumulated input
- **WHEN** a user taps dot, then swipes right (before silence timeout)
- **THEN** the accumulated input is cleared and no `InputComplete` is emitted for the partial input

#### Scenario: Reset clears accumulated input
- **WHEN** a user taps dot, then long-holds to reset
- **THEN** the accumulated input is cleared and no `InputComplete` is emitted for the partial input

#### Scenario: Vertical swipe clears accumulated input
- **WHEN** a user taps dot, then swipes up (before silence timeout)
- **THEN** the accumulated input is cleared and no `InputComplete` is emitted for the partial input
