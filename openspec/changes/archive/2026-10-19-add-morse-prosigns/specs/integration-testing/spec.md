## ADDED Requirements

### Requirement: Prosigns end-to-end test
An end-to-end test SHALL launch the app once per language, with that language saved, the default Morse timing and the app's own vibration service, and catch what reaches the `vibration` plugin's channel. Through the app's codec for the session's language and its vibration service, it SHALL play each prosign, then `?` and the language's identifier letter, and check each pattern sent.

#### Scenario: Every prosign in every language
- **WHEN** the end-of-message, wait, SOS and error prosigns are played in English, Arabic, Russian, Spanish, French and German
- **THEN** the plugin SHALL be sent, in each language, `[0, 100, 100, 300, 100, 100, 100, 300, 100, 100]`, `[0, 100, 100, 300, 100, 100, 100, 100, 100, 100]`, the 18 segments of SOS and the 16 of the eight dots, with the intensities 0 for every pause and 255 for every vibration
- **AND** no pause inside a prosign SHALL be the 300 ms letter gap

#### Scenario: Characters as before
- **WHEN** `?` and the language's identifier letter (E, ع, Р, Ñ, É, Ü) are played after the prosigns
- **THEN** `?` SHALL be sent as `[0, 100, 100, 100, 100, 300, 100, 300, 100, 100, 100, 100]` and the letter with its own pattern, as before the prosigns existed
- **AND** the home menu SHALL have announced Learn with Morse L on launch, as before
