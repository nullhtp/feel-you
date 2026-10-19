## ADDED Requirements

### Requirement: Reading speed end-to-end test
An end-to-end test SHALL run the app with its own vibration service and the default Morse timing, record what reaches the `vibration` plugin's channel, and check `reading-speed` for English and Russian: each speed changed through the app's API plays the language's sample word with its exact milliseconds, the speed survives a restart through the real preferences, and a lesson word at a slow speed keeps its 300 ms letter gaps.

#### Scenario: Every speed plays the sample word
- **WHEN** the speed is changed to 10, 8, 6, 5 and 12 wpm in turn, in English and then in Russian
- **THEN** each change SHALL send one pattern: the sample word (GOOD, ВОДА) with 100 ms dots, 300 ms dashes, 100 ms gaps inside each letter and the speed's character gap between its letters (458, 695, 1089, 1405 and 300 ms), with the intensities 0 and 255
- **AND** the speed SHALL be saved

#### Scenario: The speed survives a restart
- **WHEN** the speed is changed to 6 wpm and the app is closed and launched again on the same preferences
- **THEN** the stored value SHALL be 6, and the relaunched app's speed SHALL be 6 wpm, with a 1089 ms character gap and a 2542 ms word gap

#### Scenario: A lesson word at 5 wpm
- **WHEN** the speed is 5 wpm and the lessons are opened from the home menu and swiped up to the words level
- **THEN** the first word (HI, ДА) SHALL be sent with 300 ms between its letters, and no lesson pattern SHALL contain a 1405 ms gap
