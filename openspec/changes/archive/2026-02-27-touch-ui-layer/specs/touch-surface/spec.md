## ADDED Requirements

### Requirement: Full-screen touch capture
The app SHALL present a full-screen touch surface that captures all pointer events (touch down, touch up) and converts them into `RawTouchEvent` objects (`TouchDown`, `TouchUp`) fed to the `GestureClassifier` via `handleTouch`.

#### Scenario: Touch down event is forwarded to classifier
- **WHEN** the user touches the screen
- **THEN** the system SHALL create a `TouchDown` event with the pointer's timestamp and x-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Touch up event is forwarded to classifier
- **WHEN** the user lifts their finger from the screen
- **THEN** the system SHALL create a `TouchUp` event with the pointer's timestamp and x-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Entire screen area is touch-sensitive
- **WHEN** the widget is displayed
- **THEN** the touch-sensitive area SHALL cover the entire screen with no dead zones

### Requirement: Solid black background
The touch surface SHALL render a solid black background with no visual elements, text, or decorations.

#### Scenario: Screen appearance
- **WHEN** the touch surface is displayed
- **THEN** the screen SHALL be entirely black with no visible UI elements

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
