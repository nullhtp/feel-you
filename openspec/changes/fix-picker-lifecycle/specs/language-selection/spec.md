## ADDED Requirements

### Requirement: Language picker in the background
While the app is not in the foreground, the language picker, shown on the first launch or opened from Settings, SHALL NOT vibrate or act on shakes: leaving the foreground (inactive, hidden, paused or detached) SHALL cancel an identifier in progress, once per trip. Coming back SHALL replay the highlighted identifier once, unless a language is starting or the picker is returning to the menu. Like the home menu, the picker SHALL NOT keep the screen on.

#### Scenario: Leaving the foreground
- **WHEN** the app leaves the foreground while the picker is shown and an identifier plays
- **THEN** the vibration SHALL be cancelled, once for the whole trip through inactive, hidden and paused
- **AND** nothing SHALL vibrate until the app is resumed

#### Scenario: App inactive only
- **WHEN** the app becomes inactive without being hidden (an incoming call, Control Center, the app switcher)
- **THEN** the identifier in progress SHALL be cancelled as in the background

#### Scenario: Coming back
- **WHEN** the app returns to the foreground on the picker
- **THEN** the highlighted language's identifier SHALL vibrate once, and the highlight SHALL stay

#### Scenario: Leaving while a language starts
- **WHEN** the app leaves the foreground after a language was started (while its identifier plays or during the silence after it) and comes back
- **THEN** the identifier SHALL be cancelled and the picker SHALL vibrate nothing more
- **AND** the language SHALL still be saved and selected, and the home menu SHALL replace the picker and announce itself as it appears

#### Scenario: Shakes from Settings in the background
- **WHEN** the app is not in the foreground while the picker opened from Settings is shown
- **THEN** shake detection SHALL be paused and a double shake SHALL do nothing, and detection SHALL resume when the app comes back

#### Scenario: The screen may sleep
- **WHEN** the picker is shown and nothing is touched for the system's screen timeout
- **THEN** the system MAY turn the screen off, and the picker SHALL play the highlighted identifier when the app comes back
