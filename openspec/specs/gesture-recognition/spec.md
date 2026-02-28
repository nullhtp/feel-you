### Requirement: Configurable gesture timing thresholds
The system SHALL define gesture timing through a configuration object (`GestureTimingConfig`) with the following defaults: reset hold minimum 2000ms, silence timeout 1000ms, minimum swipe distance 50px, minimum swipe velocity 200px/s. All values SHALL be overridable at construction time. The `dotMaxDuration` and `dashMaxDuration` parameters SHALL be removed since dot/dash classification is now position-based.

#### Scenario: Default timing values
- **WHEN** a `GestureTimingConfig` is created with no arguments
- **THEN** reset min is 2000ms, silence timeout is 1000ms, min swipe distance is 50px, and min swipe velocity is 200px/s

#### Scenario: Custom timing values
- **WHEN** a `GestureTimingConfig` is created with silence timeout=1500ms
- **THEN** that custom value is used and all other values remain at defaults

#### Scenario: No dot/dash duration parameters exist
- **WHEN** a developer inspects `GestureTimingConfig`
- **THEN** there SHALL be no `dotMaxDuration` or `dashMaxDuration` properties

### Requirement: Classify long hold as reset
The system SHALL classify a press held longer than the configured reset threshold (default: 2000ms) as a `Reset` event. The reset event SHALL be emitted when the threshold is crossed, not when the user releases.

#### Scenario: Long hold triggers reset
- **WHEN** a user presses and holds for more than 2000ms
- **THEN** the system emits a `Reset` event at the 2000ms mark

### Requirement: Detect input completion via silence timeout
The system SHALL track time since the last Morse input event. When the configured silence timeout (default: 1000ms) elapses without a new input, the system SHALL emit an `InputComplete` event containing the accumulated list of `MorseSymbol` values.

#### Scenario: Silence after input triggers completion
- **WHEN** a user taps dot, then dash, then does nothing for 1000ms
- **THEN** the system emits an `InputComplete([dot, dash])` event

#### Scenario: Continued tapping resets the timer
- **WHEN** a user taps dot, waits 500ms, then taps dash
- **THEN** the silence timer resets after the second tap and no `InputComplete` is emitted yet

#### Scenario: No completion without prior input
- **WHEN** 1000ms passes with no taps and no prior accumulated input
- **THEN** no `InputComplete` event is emitted

### Requirement: Classify horizontal swipe as navigation
The system SHALL classify a horizontal swipe gesture as navigation: swipe right emits `NavigateNext`, swipe left emits `NavigatePrevious`. A swipe SHALL only be recognized if it exceeds both the configured minimum distance (default: 50px) and minimum velocity (default: 200px/s).

#### Scenario: Swipe right navigates next
- **WHEN** a user swipes right with distance > 50px and velocity > 200px/s
- **THEN** the system emits a `NavigateNext` event

#### Scenario: Swipe left navigates previous
- **WHEN** a user swipes left with distance > 50px and velocity > 200px/s
- **THEN** the system emits a `NavigatePrevious` event

#### Scenario: Slow swipe is ignored
- **WHEN** a user swipes right with distance > 50px but velocity < 200px/s
- **THEN** no navigation event is emitted

#### Scenario: Short swipe is ignored
- **WHEN** a user swipes right with distance < 50px
- **THEN** no navigation event is emitted

### Requirement: Gesture events are emitted as a stream
The `GestureClassifier` SHALL expose classified events as a Dart `Stream<GestureEvent>`. Consumers SHALL subscribe to this stream to receive gesture events reactively.

#### Scenario: Stream emits events in order
- **WHEN** a user taps (dot), then swipes right
- **THEN** the stream emits `MorseInput(dot)` followed by `NavigateNext` in order

#### Scenario: Multiple subscribers receive events
- **WHEN** two consumers subscribe to the gesture stream
- **THEN** both consumers receive all emitted events

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

### Requirement: GestureClassifier is exposed via Riverpod provider
The `GestureClassifier` SHALL be accessible through a Riverpod provider. The classifier SHALL accept a `GestureTimingConfig` for its timing thresholds.

#### Scenario: Provider exposes classifier
- **WHEN** a widget or provider needs gesture classification
- **THEN** it can obtain the `GestureClassifier` through a Riverpod provider

#### Scenario: Classifier uses injected config
- **WHEN** a `GestureClassifier` is created with a custom `GestureTimingConfig`
- **THEN** it uses the custom thresholds for all classification decisions

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
