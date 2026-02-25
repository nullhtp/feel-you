## ADDED Requirements

### Requirement: Configurable gesture timing thresholds
The system SHALL define gesture timing through a configuration object (`GestureTimingConfig`) with the following defaults: dot tap maximum 150ms, dash tap maximum 500ms, reset hold minimum 2000ms, silence timeout 1000ms, minimum swipe distance 50px, minimum swipe velocity 200px/s. All values SHALL be overridable at construction time.

#### Scenario: Default timing values
- **WHEN** a `GestureTimingConfig` is created with no arguments
- **THEN** dot max is 150ms, dash max is 500ms, reset min is 2000ms, silence timeout is 1000ms, min swipe distance is 50px, and min swipe velocity is 200px/s

#### Scenario: Custom timing values
- **WHEN** a `GestureTimingConfig` is created with dot max=200ms and silence timeout=1500ms
- **THEN** those custom values are used and all other values remain at defaults

### Requirement: Classify tap as dot
The system SHALL classify a tap-and-release where the press duration is less than the configured dot threshold (default: 150ms) as a `dot` Morse input.

#### Scenario: Quick tap produces dot
- **WHEN** a user presses and releases within 100ms
- **THEN** the system emits a `MorseInput(dot)` event

#### Scenario: Tap at exact threshold boundary
- **WHEN** a user presses and releases at exactly 150ms
- **THEN** the system emits a `MorseInput(dash)` event (boundary is exclusive for dot, inclusive for dash)

### Requirement: Classify tap as dash
The system SHALL classify a tap-and-release where the press duration is between the configured dot threshold (inclusive) and dash threshold (inclusive) as a `dash` Morse input.

#### Scenario: Medium press produces dash
- **WHEN** a user presses and releases after 300ms
- **THEN** the system emits a `MorseInput(dash)` event

#### Scenario: Press at dash maximum boundary
- **WHEN** a user presses and releases at exactly 500ms
- **THEN** the system emits a `MorseInput(dash)` event

### Requirement: Classify long hold as reset
The system SHALL classify a press held longer than the configured reset threshold (default: 2000ms) as a `Reset` event. The reset event SHALL be emitted when the threshold is crossed, not when the user releases.

#### Scenario: Long hold triggers reset
- **WHEN** a user presses and holds for more than 2000ms
- **THEN** the system emits a `Reset` event at the 2000ms mark

#### Scenario: Press between dash and reset is ignored
- **WHEN** a user presses for 800ms (between dash max 500ms and reset min 2000ms)
- **THEN** the system does NOT emit a MorseInput or Reset event (it falls in the dead zone)

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
The system SHALL define a `GestureEvent` type with the following subtypes: `MorseInput` (contains a `MorseSymbol`), `InputComplete` (contains a `List<MorseSymbol>`), `NavigateNext`, `NavigatePrevious`, and `Reset`. These types SHALL be exhaustively matchable (e.g., via sealed class or equivalent).

#### Scenario: All event types are defined
- **WHEN** a developer inspects the `GestureEvent` type hierarchy
- **THEN** exactly five subtypes exist: `MorseInput`, `InputComplete`, `NavigateNext`, `NavigatePrevious`, `Reset`

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
The accumulated Morse input buffer SHALL be cleared when a `NavigateNext`, `NavigatePrevious`, or `Reset` event occurs. This prevents stale input from carrying over between letters.

#### Scenario: Swipe clears accumulated input
- **WHEN** a user taps dot, then swipes right (before silence timeout)
- **THEN** the accumulated input is cleared and no `InputComplete` is emitted for the partial input

#### Scenario: Reset clears accumulated input
- **WHEN** a user taps dot, then long-holds to reset
- **THEN** the accumulated input is cleared and no `InputComplete` is emitted for the partial input
