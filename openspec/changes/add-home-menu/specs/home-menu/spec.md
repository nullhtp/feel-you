## Purpose

The home menu: the screen that lists the modes (Learn, Settings, and the modes later phases add), lets the user choose one by touch and Morse vibration alone, and is where a double shake returns to.

## ADDED Requirements

### Requirement: Home menu modes and identifiers
The home menu SHALL offer these modes, left to right: Learn, letter L, which opens the lessons, and Settings, letter S, which opens the language picker until a settings list exists. Each mode SHALL be identified by its letter encoded with the International Morse (English) codec rather than a hardcoded pattern, the same whatever language the lessons are in. Adding a mode SHALL only take a new entry: its letter, its name and the screen it opens.

#### Scenario: Two modes in order
- **WHEN** the home menu is shown
- **THEN** it SHALL show two columns, Learn on the left and Settings on the right

#### Scenario: Learn identifier
- **WHEN** Learn is the highlighted mode
- **THEN** its identifier SHALL be Morse L, `· − · ·`: a 100 ms dot, a 300 ms dash and two 100 ms dots, 100 ms apart, 900 ms in all

#### Scenario: Settings identifier
- **WHEN** Settings is the highlighted mode
- **THEN** its identifier SHALL be Morse S, `· · ·`: three 100 ms dots, 100 ms apart, 500 ms in all

#### Scenario: Identifiers do not depend on the lesson language
- **WHEN** the lessons are in any other language
- **THEN** the identifiers SHALL still be Morse L and S, which are also the patterns of ل and Л (L) and of س and С (S), and letters of the Spanish, French and German alphabets

#### Scenario: Identifiers are distinct
- **WHEN** the identifiers of any two modes are compared
- **THEN** they SHALL differ

### Requirement: Home menu screen
The system SHALL show a full-screen home menu on launch when a language is saved, after a language is chosen in the picker, and after a double shake in a mode. Exactly one mode SHALL be highlighted: Learn on launch and after the first-launch picker, otherwise the mode the user came back from. The menu SHALL replace the previous screen rather than open on top of it.

#### Scenario: Launch with a saved language
- **WHEN** the app is launched with a saved language
- **THEN** the home menu SHALL be shown with Learn highlighted

#### Scenario: Back from a mode
- **WHEN** the user comes back to the menu from Settings, by choosing a language or by a double shake
- **THEN** Settings SHALL be highlighted

#### Scenario: Menu announces where the user is
- **WHEN** the home menu appears on a device that can vibrate
- **THEN** the highlighted mode's identifier SHALL vibrate once, after vibration detection has finished

#### Scenario: Nothing vibrates without a motor
- **WHEN** vibration detection finds no motor while the menu is shown
- **THEN** no identifier SHALL vibrate, and the no-vibration screen SHALL replace the menu

### Requirement: Touch navigation on the home menu
Every touch gesture on the home menu SHALL be answered with the identifier of the mode it leaves highlighted, as in the language picker. A tap SHALL highlight the mode under the finger, a horizontal swipe SHALL move the highlight, and a shorter horizontal drag SHALL replay the highlighted identifier. No touch other than the hold SHALL open a mode.

#### Scenario: Tap highlights a mode
- **WHEN** the user taps a column, anywhere in it
- **THEN** that mode SHALL be highlighted and its identifier SHALL vibrate

#### Scenario: Swipe moves the highlight
- **WHEN** the user swipes right (or left) at least 50 logical pixels anywhere on the menu
- **THEN** the next (or previous) mode SHALL be highlighted, wrapping around, and its identifier SHALL vibrate

#### Scenario: Short drag replays the identifier
- **WHEN** a horizontal drag covers less than 50 logical pixels
- **THEN** the highlight SHALL stay and its identifier SHALL vibrate again

#### Scenario: A press shorter than the hold is a tap
- **WHEN** the user presses a column for less than 1 second
- **THEN** it SHALL count as a tap on that column, and no mode SHALL open

### Requirement: Hold enters the highlighted mode
A 1-second hold anywhere on the home menu SHALL enter the highlighted mode, the last identifier felt. Its identifier SHALL vibrate, and the mode's screen SHALL replace the menu only once the identifier has finished and the post-feedback pause (0.5 s) has passed, so the mode's first vibration never cuts it short or runs into it. Until then every gesture SHALL be ignored.

#### Scenario: Hold enters the highlighted mode
- **WHEN** the user holds anywhere on the menu for 1 second
- **THEN** the highlighted mode's identifier SHALL vibrate
- **AND** once it has finished and 0.5 s of silence has passed, the mode's screen SHALL replace the menu

#### Scenario: Gestures are ignored while a mode opens
- **WHEN** a mode has been entered and its screen has not replaced the menu yet
- **THEN** further touches and shakes SHALL neither vibrate nor enter another mode

#### Scenario: Learn opens the lessons
- **WHEN** the user enters Learn
- **THEN** the lesson surface SHALL replace the menu, in the session's language
- **AND** after a launch, a language choice or a double shake back from the lessons, the lessons SHALL start at the digits level on 0

#### Scenario: Settings opens the language picker
- **WHEN** the user enters Settings
- **THEN** the language picker SHALL replace the menu, as opened from Settings, with the saved language highlighted

#### Scenario: Screen readers open a mode directly
- **WHEN** a screen reader activates one of the per-mode buttons
- **THEN** that mode SHALL open as if it had been highlighted and held

### Requirement: Shakes on the home menu
A double shake on the home menu SHALL replay the highlighted identifier, so a user who double-shakes to find the menu feels that they are on it, and on which mode. A single shake SHALL do nothing on the menu: it is the lessons' way home. Shakes SHALL be ignored while a mode opens and while the app is not in the foreground.

#### Scenario: Double shake replays the identifier
- **WHEN** the user double-shakes on the menu
- **THEN** the highlighted mode's identifier SHALL vibrate once, and the highlight SHALL stay

#### Scenario: Single shake does nothing
- **WHEN** the user shakes the phone once on the menu
- **THEN** nothing SHALL vibrate and the highlight SHALL stay

### Requirement: Double shake returns to the home menu
From any mode, a double shake SHALL replace the mode's screen with the home menu, with that mode highlighted, and the menu SHALL announce it. This replaces the double shake to the language picker. The language picker shown on the first launch is not a mode: no language is chosen yet, so a double shake there SHALL do nothing.

#### Scenario: From the lessons
- **WHEN** the user double-shakes while the teaching loop is running
- **THEN** the loop SHALL stop at once, the home menu SHALL replace the lesson surface with Learn highlighted, and Morse L SHALL vibrate

#### Scenario: From the picker opened from Settings
- **WHEN** the user double-shakes in the language picker opened from Settings
- **THEN** the home menu SHALL replace the picker with Settings highlighted, Morse S SHALL vibrate, and the language SHALL neither change nor be saved

#### Scenario: Not from the first-launch picker
- **WHEN** the user double-shakes in the language picker shown on the first launch
- **THEN** the picker SHALL stay and nothing SHALL vibrate

### Requirement: Home menu in the background
While the app is not in the foreground, the home menu SHALL NOT vibrate or act on shakes: leaving the foreground SHALL cancel an identifier in progress and pause shake detection. Coming back to the foreground SHALL resume shake detection and replay the highlighted identifier. Like the language picker, the menu SHALL NOT keep the screen on.

#### Scenario: Leaving the foreground
- **WHEN** the app leaves the foreground while the menu is shown
- **THEN** any vibration in progress SHALL be cancelled, shake detection SHALL be paused, and a double shake SHALL do nothing

#### Scenario: Coming back
- **WHEN** the app returns to the foreground on the menu
- **THEN** shake detection SHALL resume and the highlighted identifier SHALL vibrate once

#### Scenario: The screen may sleep
- **WHEN** the menu is shown and nothing is touched for the system's screen timeout
- **THEN** the system MAY turn the screen off, and the menu SHALL announce itself when the app comes back

### Requirement: Visual cue for a sighted helper on the home menu
For a sighted helper, each mode SHALL be drawn as a column with its letter in large type, its name and its Morse pattern (`·` for a dot, `—` for a dash). The highlighted column SHALL be drawn inverted. A line at the bottom SHALL read "Tap or swipe to a mode, then hold anywhere for 1 second to open it". None of it SHALL intercept touches.

#### Scenario: Helper sees the modes
- **WHEN** the menu is shown
- **THEN** the Learn column SHALL show `L`, `Learn` and `· — · ·`, and the Settings column `S`, `Settings` and `· · ·`

#### Scenario: Helper sees the highlight and the hint
- **WHEN** the menu is shown with Learn highlighted
- **THEN** the Learn column SHALL be drawn inverted, the Settings column SHALL not, and the hint line SHALL be shown

### Requirement: Screen-reader semantics of the home menu
Screen readers SHALL see the menu as a route named "Home menu" with one button per mode. Each button SHALL be labelled with the mode's name, carry a hint saying what it opens ("Opens the Morse lessons", "Opens the language choice") and be marked selected while its mode is highlighted. The visible texts SHALL not be announced a second time.

#### Scenario: One button per mode
- **WHEN** a screen reader explores the menu
- **THEN** it SHALL find exactly one button labelled "Learn" with the hint "Opens the Morse lessons" and one labelled "Settings" with the hint "Opens the language choice"

#### Scenario: Highlighted mode is selected
- **WHEN** a mode is highlighted by touch
- **THEN** its button SHALL be marked selected and the other mode's button SHALL not
