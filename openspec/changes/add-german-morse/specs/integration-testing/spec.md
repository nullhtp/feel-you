## MODIFIED Requirements

### Requirement: Language flow end-to-end test
An end-to-end test SHALL launch the app with no saved language and, for each language added after English, Arabic and Russian, drive it from the language picker to a learned letter and word: choose the language, start it, learn a letter only that language has, then hear a word spelled and answer it. Vibration SHALL be recorded, and the motor answered at the platform channels.

#### Scenario: One flow per new language
- **WHEN** the flows run
- **THEN** they SHALL cover, with the identifier letter, the letter and the word:
  - Spanish: Ñ, Ñ, BAÑO
  - French: É, É, ÇA
  - German: Ü, Ö, MÜDE

#### Scenario: Choosing the language
- **WHEN** the picker opens and the user taps the language's column
- **THEN** its identifier SHALL be played, encoded with the language's codec
- **AND** after a 1 s hold the lesson SHALL open on digit "0", in that language, which SHALL be saved

#### Scenario: Learning the language's own letter
- **WHEN** the user swipes up to the letters and right to the letter
- **THEN** its pattern SHALL play, and tapping it back SHALL play the success signal and make it a learned item, saved

#### Scenario: Spelling and answering a word
- **WHEN** the user swipes up to the words and right to the word
- **THEN** its letters SHALL be played one at a time, then the word with its letter gaps
- **AND** tapping it back with a bottom-strip tap between letters SHALL play the success signal and make it a learned item
