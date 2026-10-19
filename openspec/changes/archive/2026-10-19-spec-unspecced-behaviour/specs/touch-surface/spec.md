## ADDED Requirements

### Requirement: Double shake returns to the language picker
While the teaching loop is running, a `ChangeLanguage` from the shake detector SHALL stop the loop at once, so nothing vibrates during the route transition, and replace the lesson surface with the language picker. The first shake of the pair has already gone home (see `shake-gesture`). The event SHALL be ignored while the loop is stopped, and once the surface is leaving: neither further shakes nor a resume during the transition SHALL start the loop again.

#### Scenario: Double shake during a lesson
- **WHEN** the teaching loop plays letter "K" and the user double-shakes
- **THEN** the first shake SHALL take the session home, to digit "0", and restart the loop there
- **AND** the second SHALL stop the loop and replace the lesson surface with the language picker
- **AND** the picker SHALL highlight the current language and vibrate its identifier

#### Scenario: Double shake in the background
- **WHEN** the lesson is suspended in the background and a `ChangeLanguage` arrives
- **THEN** the lesson surface SHALL stay, and the loop SHALL stay stopped

#### Scenario: Shakes during the transition
- **WHEN** more shakes arrive while the picker is replacing the lesson surface
- **THEN** the loop SHALL NOT start again, and only one picker SHALL open

#### Scenario: Shaking in the picker
- **WHEN** the picker has replaced the lesson surface and the user shakes
- **THEN** nothing SHALL happen, as shake detection stays paused until a lesson starts

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
