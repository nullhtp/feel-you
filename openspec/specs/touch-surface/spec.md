# touch-surface Specification

## Purpose

The full-screen black lesson screen that captures touches, runs the teaching loop and keeps the screen on.

## Requirements

### Requirement: Full-screen touch capture
The lesson screen SHALL capture pointer events over the whole screen with a `Listener` and forward the first finger's down, up and cancel to `GestureClassifier.handleTouch` as `TouchDown`, `TouchUp` and `TouchCancel`, down and up with timestamp, x and y. Other fingers touching meanwhile SHALL be ignored. Before each touch down it SHALL give the classifier the live screen size. The classifier decides what each press means, including a `BottomZoneAction` for a bottom-strip tap.

#### Scenario: Touch down event is forwarded to classifier
- **WHEN** the user touches the screen
- **THEN** the system SHALL create a `TouchDown` event with the pointer's timestamp, x-position and y-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Touch up event in upper zone is forwarded to classifier
- **WHEN** the user lifts their finger from the upper 85% of the screen
- **THEN** the system SHALL create a `TouchUp` event with the pointer's timestamp, x-position and y-position and call `gestureClassifier.handleTouch` with it

#### Scenario: Touch up event in bottom zone is forwarded too
- **WHEN** the user lifts their finger from the bottom 15% of the screen
- **THEN** the system SHALL forward the `TouchUp` to `gestureClassifier.handleTouch` in the same way

#### Scenario: Short tap in bottom zone triggers bottom-zone action
- **WHEN** the user taps and releases in the bottom 15% of the screen
- **AND** the touch does not qualify as a swipe (distance < 50px or velocity < 200px/s)
- **AND** a reset was not emitted during this press
- **THEN** the classifier SHALL emit a `BottomZoneAction` event and no dot or dash

#### Scenario: Swipe starting in bottom zone is forwarded normally
- **WHEN** the user touches in the bottom zone and swipes with sufficient distance and velocity
- **THEN** the system SHALL forward the `TouchUp` to the classifier, which SHALL emit the swipe's navigation event

#### Scenario: Second finger is ignored
- **WHEN** a second finger touches the screen while the first is still down
- **THEN** none of the second finger's events SHALL be forwarded to the classifier

#### Scenario: Press taken over by the system
- **WHEN** the system cancels the first finger's pointer (edge back gesture, notification shade, incoming call)
- **THEN** the system SHALL forward a `TouchCancel`, which produces no dot, dash, swipe or reset

#### Scenario: Entire screen area is touch-sensitive
- **WHEN** the widget is displayed
- **THEN** the touch-sensitive area SHALL cover the entire screen with no dead zones

#### Scenario: Screen width and height provided to classifier routing
- **WHEN** the first finger touches down
- **THEN** the system SHALL set the classifier's screen width and height from `MediaQuery` before forwarding the `TouchDown`, for position-based classification and bottom-zone detection

### Requirement: Solid black background
The lesson screen SHALL render a solid black background, with a `CompanionOverlay` stacked above the `Listener` that shows a sighted helper the zones and the state of the lesson (see `companion-overlay`). The overlay SHALL be wrapped in `IgnorePointer`, so every touch, including one on overlay text or lines, reaches the `Listener`.

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
The touch surface SHALL be the lesson screen, opened by entering Learn on the home menu. A double shake during a lesson SHALL replace it with the home menu, with Learn highlighted. Each switch SHALL replace the route rather than push on top of it, so there is only ever one screen: the language picker, the home menu or the lessons.

#### Scenario: App startup
- **WHEN** the app is launched and a language is saved
- **THEN** the home menu SHALL be displayed, and entering Learn SHALL display the touch surface, in that language

#### Scenario: App startup without a saved language
- **WHEN** the app is launched with no saved language and the user starts a language in the picker
- **THEN** the home menu SHALL replace the picker, and entering Learn SHALL display the touch surface, in that language

#### Scenario: Double shake leaves the lesson
- **WHEN** the user double-shakes while the teaching loop is running
- **THEN** the teaching loop SHALL stop and the home menu SHALL replace the touch surface, with Learn highlighted

### Requirement: Screen-reader description of the lesson surface
The touch area SHALL be one semantics node labelled "Morse input surface" that names the route, so screen readers announce the lesson screen when it opens. Its hint SHALL explain the input: the halves for dot and dash, the bottom strip to submit or add a letter gap, swipes to change character and level, and the quiz past the last character. It SHALL have no semantic tap action, and touches SHALL reach the classifier with semantics on.

#### Scenario: Label, hint and route name
- **WHEN** a screen reader is on and the lesson surface is shown
- **THEN** the touch area SHALL be a node labelled "Morse input surface" that names the route
- **AND** its hint SHALL be "Tap the left half for a dot and the right half for a dash. Tap the bottom strip to submit, or to add a letter gap on word levels. Swipe left or right to change character, up or down to change level. Swipe right past the last character for a quiz."

#### Scenario: Touches with semantics on
- **WHEN** semantics are enabled and the user taps the lesson surface
- **THEN** the touch down and touch up SHALL still be forwarded to the classifier

#### Scenario: Screen reader exploration
- **WHEN** TalkBack or VoiceOver is on
- **THEN** the screen reader SHALL take single taps and swipes for exploration, so they do not reach the lesson surface: there is no app setting that opts the surface out (VoiceOver Direct Touch is not exposed by Flutter, and Android has no equivalent)
- **AND** the user SHALL need the screen reader's pass-through gesture (double tap and hold, then gesture) or turn the screen reader off to enter Morse

### Requirement: Double shake returns to the home menu
While the teaching loop is running, a `ChangeLanguage` from the shake detector SHALL stop the loop at once, so nothing vibrates during the route transition, and replace the lesson surface with the home menu, with Learn highlighted. The first shake of the pair has already gone home (see `shake-gesture`). The event SHALL be ignored while the loop is stopped, and once the surface is leaving: neither further shakes nor a resume during the transition SHALL start the loop again.

#### Scenario: Double shake during a lesson
- **WHEN** the teaching loop plays letter "K" and the user double-shakes
- **THEN** the first shake SHALL take the session home, to digit "0", and restart the loop there
- **AND** the second SHALL stop the loop and replace the lesson surface with the home menu
- **AND** the menu SHALL highlight Learn and vibrate its identifier, Morse L

#### Scenario: Double shake in the background
- **WHEN** the lesson is suspended in the background and a `ChangeLanguage` arrives
- **THEN** the lesson surface SHALL stay, and the loop SHALL stay stopped

#### Scenario: Shakes during the transition
- **WHEN** more shakes arrive while the home menu is replacing the lesson surface
- **THEN** the loop SHALL NOT start again, and only one menu SHALL open

#### Scenario: Shaking on the menu
- **WHEN** the home menu has replaced the lesson surface and the user shakes
- **THEN** no lesson SHALL start: a single shake SHALL do nothing and a double shake SHALL replay Morse L (see `home-menu`)
