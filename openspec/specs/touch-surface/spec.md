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

### Requirement: Solid black background
The touch surface SHALL render a solid black background. A visual companion overlay SHALL be rendered on top of the black background, displaying zone boundaries, labels, the current symbol/word, morse pattern, level indicator, position progress, user input buffer, and session phase. The overlay SHALL NOT intercept touch events — all touches SHALL continue to be captured by the underlying `Listener` widget. The overlay is rendered via a `CompanionOverlay` widget wrapped in `IgnorePointer`, placed above the `Listener` in a `Stack`.

#### Scenario: Screen appearance
- **WHEN** the touch surface is displayed
- **THEN** the screen SHALL show a black background with the companion overlay visible on top

#### Scenario: Touch handling preserved with overlay
- **WHEN** the user touches any part of the screen, including areas with overlay text or lines
- **THEN** the touch event SHALL be captured by the `Listener` widget and processed identically to the behavior without the overlay

### Requirement: Auto-start teaching orchestrator
The touch surface SHALL automatically start the `TeachingOrchestrator` when the widget is mounted, so the learning loop begins without any user action.

#### Scenario: App launches into learning mode
- **WHEN** the touch surface widget is first mounted
- **THEN** the system SHALL call `TeachingOrchestrator.start()` after the first frame renders

#### Scenario: Orchestrator is stopped on unmount
- **WHEN** the touch surface widget is disposed
- **THEN** the system SHALL call `TeachingOrchestrator.stop()` to clean up resources

### Requirement: Wakelock during session
The touch surface SHALL keep the device screen on (wakelock enabled) for the entire duration of the learning session.

#### Scenario: Wakelock enabled on mount
- **WHEN** the touch surface widget is mounted
- **THEN** the system SHALL enable the wakelock to prevent the screen from sleeping

#### Scenario: Wakelock disabled on unmount
- **WHEN** the touch surface widget is disposed
- **THEN** the system SHALL disable the wakelock to restore normal screen timeout behavior

### Requirement: Back-navigation prevention
The touch surface SHALL prevent the system back navigation (Android back button, iOS swipe-to-go-back) from exiting the screen.

#### Scenario: Android back button pressed
- **WHEN** the user presses the Android hardware/software back button while on the touch surface
- **THEN** the system SHALL NOT navigate away from the touch surface

#### Scenario: iOS swipe-back gesture
- **WHEN** the user performs an iOS edge swipe-back gesture while on the touch surface
- **THEN** the system SHALL NOT navigate away from the touch surface

### Requirement: App entry point integration
The app's root widget SHALL use the touch surface as its home screen, replacing the placeholder `Scaffold`.

#### Scenario: App startup
- **WHEN** the app is launched
- **THEN** the touch surface widget SHALL be displayed as the main and only screen
