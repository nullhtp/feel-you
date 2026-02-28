## MODIFIED Requirements

### Requirement: Full-screen touch capture
The app SHALL present a full-screen touch surface that captures all pointer events (touch down, touch up) and converts them into `RawTouchEvent` objects (`TouchDown`, `TouchUp`) fed to the `GestureClassifier` via `handleTouch`. The touch surface SHALL provide the screen width to the `GestureClassifier` so it can perform position-based dot/dash classification. On touch-up, the touch surface SHALL check whether the tap occurred in the bottom input zone (lower 15% of screen height) and, if so, emit a `BottomZoneAction` event via the classifier's `emitEvent()` method instead of forwarding the touch to `handleTouch` for dot/dash classification. Swipes and long holds starting in the bottom zone SHALL still be forwarded to the classifier normally.

#### Scenario: Touch down event is forwarded to classifier
- **WHEN** the user touches the screen
- **THEN** the system SHALL create a `TouchDown` event with the pointer's timestamp, x-position, and y-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Touch up event in upper zone is forwarded to classifier
- **WHEN** the user lifts their finger from the upper 85% of the screen
- **THEN** the system SHALL create a `TouchUp` event with the pointer's timestamp, x-position, and y-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Short tap in bottom zone triggers bottom-zone action
- **WHEN** the user taps and releases in the bottom 15% of the screen
- **AND** the touch does not qualify as a swipe (distance < 50px or velocity < 200px/s)
- **AND** a reset was not emitted during this press
- **THEN** the system SHALL trigger haptic feedback and emit a `BottomZoneAction` event via the classifier
- **AND** the touch SHALL NOT be forwarded to `handleTouch` as a `TouchUp`

#### Scenario: Swipe starting in bottom zone is forwarded normally
- **WHEN** the user touches in the bottom zone and swipes with sufficient distance and velocity
- **THEN** the system SHALL forward the `TouchUp` to the classifier for normal swipe classification

#### Scenario: Entire screen area is touch-sensitive
- **WHEN** the widget is displayed
- **THEN** the touch-sensitive area SHALL cover the entire screen with no dead zones

#### Scenario: Screen width and height provided to classifier routing
- **WHEN** the touch surface widget is built
- **THEN** it SHALL obtain the screen width and height from `MediaQuery` for position-based classification and bottom-zone detection
