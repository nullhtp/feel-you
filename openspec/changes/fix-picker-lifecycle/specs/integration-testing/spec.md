## ADDED Requirements

### Requirement: Language picker background end-to-end test
An end-to-end test SHALL send the app to the background and back through the real lifecycle notifications on the first-launch picker, on the picker opened from Settings and, for comparison, on the home menu, with each identifier lasting until it ends or is cancelled, as on a motor. It SHALL check that leaving cancels a playing identifier, that nothing vibrates while away, that the return replays it, and what a trip during the wait after a hold does.

#### Scenario: Leaving while an identifier plays
- **WHEN** Russian (on the menu, Settings) has just been highlighted, its identifier is still playing, and the app goes to the background for 1.5 s
- **THEN** one cancel SHALL be recorded, and nothing else while the app is away
- **WHEN** the app returns to the foreground
- **THEN** that identifier SHALL be played once, and the screen SHALL stay

#### Scenario: Leaving during the wait after a hold
- **WHEN** the user holds on Russian (on the menu, Settings), its identifier ends, and the app goes to the background during the silence before the next screen, for longer than that silence
- **THEN** only the identifier and one cancel SHALL be recorded
- **WHEN** the app returns to the foreground
- **THEN** the next screen SHALL replace it and play only its own identifier: L after the first-launch picker, S after the picker from Settings, with Russian saved and selected, and E (the saved English) after the menu
