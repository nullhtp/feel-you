## MODIFIED Requirements

### Requirement: Configurable gesture timing thresholds
The system SHALL define gesture timing through a configuration object (`GestureTimingConfig`) with the following defaults: reset hold minimum 2000ms, silence timeout 1000ms, minimum swipe distance 50px, minimum swipe velocity 200px/s. All values SHALL be overridable at construction time. The `dotMaxDuration`, `dashMaxDuration`, and `charGapThreshold` parameters SHALL be removed since dot/dash classification is now position-based and charGap insertion is now explicit via the bottom input zone.

#### Scenario: Default timing values
- **WHEN** a `GestureTimingConfig` is created with no arguments
- **THEN** reset min is 2000ms, silence timeout is 1000ms, min swipe distance is 50px, and min swipe velocity is 200px/s

#### Scenario: Custom timing values
- **WHEN** a `GestureTimingConfig` is created with silence timeout=1500ms
- **THEN** that custom value is used and all other values remain at defaults

#### Scenario: No dot/dash duration or charGapThreshold parameters exist
- **WHEN** a developer inspects `GestureTimingConfig`
- **THEN** there SHALL be no `dotMaxDuration`, `dashMaxDuration`, or `charGapThreshold` properties

### Requirement: Gesture event type hierarchy
The system SHALL define a `GestureEvent` type with the following subtypes: `MorseInput` (contains a `MorseSymbol`), `InputComplete` (contains a `List<MorseSymbol>`), `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, `Home`, and `BottomZoneAction`. These types SHALL be exhaustively matchable (e.g., via sealed class or equivalent).

#### Scenario: All event types are defined
- **WHEN** a developer inspects the `GestureEvent` type hierarchy
- **THEN** exactly nine subtypes exist: `MorseInput`, `InputComplete`, `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, `Home`, `BottomZoneAction`

#### Scenario: MorseInput carries symbol data
- **WHEN** a `MorseInput` event is created
- **THEN** it contains a `MorseSymbol` value (dot, dash, or charGap)

#### Scenario: InputComplete carries accumulated symbols
- **WHEN** an `InputComplete` event is created
- **THEN** it contains a `List<MorseSymbol>` representing the full input sequence

#### Scenario: Events are exhaustively matchable
- **WHEN** a developer writes a switch/match on `GestureEvent`
- **THEN** the compiler warns if any subtype is not handled

## REMOVED Requirements

### Requirement: Gesture classifier emits charGap symbols for inter-character silence
**Reason**: CharGap insertion is now explicit via the bottom input zone tap rather than automatic via silence timer. The 400ms `charGapThreshold` timer has been removed.
**Migration**: CharGap symbols are inserted into the input buffer via the `GestureClassifier.insertCharGap()` method, called by the `TeachingOrchestrator` in response to `BottomZoneAction` events on the words level.

### Requirement: Configurable charGap threshold
**Reason**: The `charGapThreshold` parameter in `GestureTimingConfig` is no longer used since charGap insertion is explicit.
**Migration**: Remove the `charGapThreshold` field from `GestureTimingConfig`. Any tests or code referencing this threshold should be updated to use the explicit `insertCharGap()` method instead.
