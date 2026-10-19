## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: Double shake returns to the language picker
**Reason**: A double shake now returns to the home menu, not the language picker, so the requirement's name and its "Shaking in the picker" scenario no longer hold.
**Migration**: Replaced by "Double shake returns to the home menu" below; the picker is reached from the menu's Settings (see `home-menu` and `language-selection`).

## ADDED Requirements

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
