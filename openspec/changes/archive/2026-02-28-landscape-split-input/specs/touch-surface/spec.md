## MODIFIED Requirements

### Requirement: Full-screen touch capture
The app SHALL present a full-screen touch surface that captures all pointer events (touch down, touch up) and converts them into `RawTouchEvent` objects (`TouchDown`, `TouchUp`) fed to the `GestureClassifier` via `handleTouch`. The touch surface SHALL provide the screen width to the `GestureClassifier` so it can perform position-based dot/dash classification.

#### Scenario: Touch down event is forwarded to classifier
- **WHEN** the user touches the screen
- **THEN** the system SHALL create a `TouchDown` event with the pointer's timestamp and x-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Touch up event is forwarded to classifier
- **WHEN** the user lifts their finger from the screen
- **THEN** the system SHALL create a `TouchUp` event with the pointer's timestamp and x-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Entire screen area is touch-sensitive
- **WHEN** the widget is displayed
- **THEN** the touch-sensitive area SHALL cover the entire screen with no dead zones

#### Scenario: Screen width provided to classifier
- **WHEN** the touch surface widget is built
- **THEN** it SHALL obtain the screen width from `MediaQuery` and ensure the `GestureClassifier` has access to this value for position-based classification
