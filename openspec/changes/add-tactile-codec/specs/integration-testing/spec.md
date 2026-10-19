## ADDED Requirements

### Requirement: Vibration sequence regression integration test
The system SHALL have an integration test that drives real lesson flows in English, Arabic and Russian (digits, letters and words, with answers, navigation, spelling and the quiz) and checks, step by step, that the vibration service is asked to play the millisecond patterns and signals recorded on the app before the tactile codec was introduced, with the default Morse timing.

#### Scenario: English digits, letters, words and quiz
- **WHEN** the English lessons start on "0", the user answers "0", swipes to "1", up to "A", answers "A" wrong, up to the words, answers "HI" with a bottom-strip letter gap, holds, swipes down twice and right into the digits quiz
- **THEN** each step SHALL play exactly the recorded sequence: for example `[0, 300, 100, 300, 100, 300, 100, 300, 100, 300]` for "0", cancel and the success signal after the answer, the letters H and I then the word for "HI", and `?` before the quiz item

#### Scenario: Arabic letters and a word with an alias
- **WHEN** the Arabic lessons go from "0" up to "ا", right to "ب", up to the words and right to "ألم"
- **THEN** each step SHALL play the recorded sequence, "ألم" being spelled with Alif's pattern for "أ"

#### Scenario: Russian words and a boundary swipe
- **WHEN** the Russian lessons go from "0" up to "А", up to "ДА", swipe left at the first word and right to "НЕ"
- **THEN** each step SHALL play the recorded sequence, and the boundary swipe SHALL leave "ДА" repeating without a cancel
