## ADDED Requirements

### Requirement: A cancelled press is not classified
`RawTouchEvent` SHALL have a third subtype, `TouchCancel`, with no position or timestamp, for a press that ended without a real release. On it the classifier SHALL drop the press in progress: it emits no event, its long-hold timer never fires a `Reset`, and a later `TouchUp` for it is ignored. Input already in the buffer SHALL stay, and its silence timer SHALL restart, so it still completes. A cancel with no press in progress SHALL do nothing.

#### Scenario: Cancelled tap
- **WHEN** a press starts on the left or the right half and is cancelled
- **THEN** no `MorseInput` SHALL be emitted

#### Scenario: Cancelled swipe
- **WHEN** a press that has moved far and fast enough for a swipe is cancelled
- **THEN** no navigation event SHALL be emitted

#### Scenario: Cancelled bottom-strip tap
- **WHEN** a press that started in the bottom input zone is cancelled
- **THEN** no `BottomZoneAction` SHALL be emitted

#### Scenario: Cancelled before the reset threshold
- **WHEN** a press is cancelled before it has been held for the reset threshold
- **THEN** no `Reset` SHALL be emitted, then or later

#### Scenario: Cancelled after a reset
- **WHEN** a press has already emitted `Reset` and is then cancelled
- **THEN** the `Reset` SHALL stand, and the cancel SHALL emit nothing more

#### Scenario: Earlier input still completes
- **WHEN** the user has tapped a dot, then starts a press that is cancelled
- **THEN** `InputComplete([dot])` SHALL be emitted one silence timeout after the cancel

#### Scenario: Cancel with no press
- **WHEN** a `TouchCancel` arrives while no press is in progress
- **THEN** nothing SHALL happen

#### Scenario: Next press after a cancel
- **WHEN** a new press follows a cancelled one
- **THEN** it SHALL be classified as usual, as a tap, a swipe or a long hold

## MODIFIED Requirements

### Requirement: Gesture event type hierarchy
The system SHALL define a `GestureEvent` type with the following subtypes: `MorseInput` (contains a `MorseSignal`), `InputComplete` (contains a `List<MorseToken>`), `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, `Home`, `ChangeLanguage` and `BottomZoneAction`. `ChangeLanguage` is emitted by the shake detector for a double shake (see `shake-gesture`). These types SHALL be exhaustively matchable (e.g., via sealed class or equivalent).

#### Scenario: All event types are defined
- **WHEN** a developer inspects the `GestureEvent` type hierarchy
- **THEN** exactly ten subtypes exist: `MorseInput`, `InputComplete`, `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, `Home`, `ChangeLanguage`, `BottomZoneAction`

#### Scenario: MorseInput carries symbol data
- **WHEN** a `MorseInput` event is created
- **THEN** it contains a `MorseSignal` value (dot or dash)

#### Scenario: InputComplete carries accumulated symbols
- **WHEN** an `InputComplete` event is created
- **THEN** it contains a `List<MorseToken>` representing the full input sequence: `Signal` tokens, and on a words level `CharGap` tokens between letters

#### Scenario: ChangeLanguage carries no data
- **WHEN** two `ChangeLanguage` events are compared
- **THEN** they SHALL be equal

#### Scenario: Events are exhaustively matchable
- **WHEN** a developer writes a switch/match on `GestureEvent`
- **THEN** the compiler warns if any subtype is not handled

### Requirement: Configurable gesture timing thresholds
The system SHALL define gesture timing through a configuration object (`GestureTimingConfig`) with the following defaults: reset hold minimum 2000ms, silence timeout 1000ms, minimum swipe distance 50px, minimum swipe velocity 200px/s, bottom zone fraction 0.15. All values SHALL be overridable at construction time. There SHALL be no `dotMaxDuration`, `dashMaxDuration` or `charGapThreshold`: dot and dash are told apart by position, and letter gaps are entered with the bottom input zone.

#### Scenario: Default timing values
- **WHEN** a `GestureTimingConfig` is created with no arguments
- **THEN** reset min is 2000ms, silence timeout is 1000ms, min swipe distance is 50px, min swipe velocity is 200px/s, and the bottom zone fraction is 0.15

#### Scenario: Custom timing values
- **WHEN** a `GestureTimingConfig` is created with silence timeout=1500ms
- **THEN** that custom value is used and all other values remain at defaults

#### Scenario: No dot/dash duration or charGapThreshold parameters exist
- **WHEN** a developer inspects `GestureTimingConfig`
- **THEN** there SHALL be no `dotMaxDuration`, `dashMaxDuration`, or `charGapThreshold` properties
