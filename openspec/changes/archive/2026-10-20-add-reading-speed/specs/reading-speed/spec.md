## Purpose

How fast reading modes play text: five Farnsworth speeds that stretch only the silences between characters and between words, the speed saved on the phone, the sample word that confirms a change, and the lessons' own timing, which no speed changes.

## ADDED Requirements

### Requirement: Five reading speeds with Farnsworth gaps
The system SHALL offer five reading speeds, in effective words per minute: 12, 10, 8, 6 and 5, in that order, 12 being the default. They SHALL follow the ARRL Farnsworth formula with the character speed fixed at 12 wpm, the speed of the 100 ms dot. Dots, dashes and the gap between the pulses of a character SHALL be the same at every speed; only the gap between characters and the gap between words SHALL stretch, to whole milliseconds.

#### Scenario: Gaps at each speed
- **WHEN** the reading timing of each speed is built from the default timing
- **THEN** its character gap and word gap SHALL be:
  - 12 wpm: 300 ms and 700 ms
  - 10 wpm: 458 ms and 1068 ms
  - 8 wpm: 695 ms and 1621 ms
  - 6 wpm: 1089 ms and 2542 ms
  - 5 wpm: 1405 ms and 3279 ms

#### Scenario: Pulses never change
- **WHEN** the reading timing of any speed is built from the default timing
- **THEN** a dot SHALL last 100 ms, a dash 300 ms, and the gap between the pulses of a character SHALL be 100 ms

#### Scenario: Default is today's timing
- **WHEN** nothing has changed the speed
- **THEN** the speed SHALL be 12 wpm, whose reading timing SHALL be exactly the lesson timing

#### Scenario: Speeds in order
- **WHEN** a developer lists the reading speeds
- **THEN** they SHALL be 12, 10, 8, 6 and 5 wpm, fastest first

#### Scenario: A prosign at every speed
- **WHEN** a prosign (see `morse-prosigns`) is played with the reading timing of any speed
- **THEN** it SHALL last as long as with the lesson timing, SOS 2300 ms, because it has neither a character gap nor a word gap to stretch

### Requirement: Reading timing follows the lesson timing
The reading timing at a speed of s wpm SHALL be the lesson timing with its character gap and its word gap each multiplied by the Farnsworth stretch (60·12 − 37.2·s) / (22.8·s) and rounded to the nearest millisecond, and everything else unchanged. At 12 wpm the stretch SHALL be exactly 1, so the reading timing equals the lesson timing whatever the lesson timing is.

#### Scenario: Tuned lesson timing at the default speed
- **WHEN** the lesson timing has a 400 ms character gap and a 900 ms word gap and the speed is 12 wpm
- **THEN** the reading timing SHALL have a 400 ms character gap and a 900 ms word gap

#### Scenario: Tuned lesson timing at a slower speed
- **WHEN** the lesson timing has a 400 ms character gap and a 900 ms word gap and the speed is 10 wpm
- **THEN** the reading timing SHALL have a 611 ms character gap and a 1374 ms word gap, with the lesson timing's pulses

### Requirement: The reading speed is saved
The reading speed SHALL be saved on the device (`SharedPreferences`, key `reading_speed_wpm`, the speed in words per minute as an integer) whenever it is changed, and read when the app starts. Nothing saved, a value that is not an integer, or an integer that is not one of the five speeds SHALL read as 12 wpm. Saving is best effort: when the storage cannot be loaded or written, the app SHALL still run, at 12 wpm on the next launch.

#### Scenario: The speed survives a restart
- **WHEN** the speed is changed to 6 wpm and the app is restarted
- **THEN** the speed SHALL be 6 wpm, with a 1089 ms character gap and a 2542 ms word gap

#### Scenario: Stored as words per minute
- **WHEN** the speed is changed to 8 wpm
- **THEN** the stored value SHALL be the integer 8

#### Scenario: Nothing saved
- **WHEN** the app starts with no saved speed
- **THEN** the speed SHALL be 12 wpm

#### Scenario: Unknown or corrupt value
- **WHEN** the stored value is 7, 0, the text "12" or the number 12.5
- **THEN** the speed SHALL be 12 wpm

#### Scenario: Storage unavailable
- **WHEN** the platform storage cannot be loaded at launch
- **THEN** a change SHALL last for the current run only

#### Scenario: Backed up like the language
- **WHEN** the app's data is backed up or moved to another phone
- **THEN** the speed SHALL be treated like the language: it is in the same preferences, which the backup rules do not leave out

### Requirement: Changing the speed plays a sample word
Changing the reading speed SHALL save it and play a sample word at the new speed, through the reading timing, as confirmation, even when the speed was already the one set. The sample SHALL be the same four-letter word of the current language's words level at every speed, encoded with that language's codec. A change while a sample plays SHALL cut that sample short. The change SHALL complete once the sample has played.

#### Scenario: Sample word of each language
- **WHEN** the speed is changed while the session's language is each language in turn
- **THEN** the sample word SHALL be:
  - English: GOOD (`−−· −−− −−− −··`)
  - Arabic: سعيد (`··· ·−·− ·· −··`)
  - Russian: ВОДА (`·−− −−− −·· ·−`)
  - Spanish: BIEN (`−··· ·· · −·`)
  - French: BIEN (`−··· ·· · −·`)
  - German: WARM (`·−− ·− ·−· −−`)

#### Scenario: Sample at 5 wpm
- **WHEN** the speed is changed to 5 wpm in English
- **THEN** the device SHALL be sent `[0, 300, 100, 300, 100, 100, 1405, 300, 100, 300, 100, 300, 1405, 300, 100, 300, 100, 300, 1405, 300, 100, 100, 100, 100]` ms with the intensities 0 for every silence and 255 for every vibration, 8015 ms in all

#### Scenario: The same word at every speed
- **WHEN** the speed is changed to each of the five speeds in turn
- **THEN** each sample SHALL have the same pulses, and only its three character gaps SHALL differ, as the speeds' gaps do

#### Scenario: A change during a sample
- **WHEN** the speed is changed while the previous change's sample is still playing
- **THEN** the vibration SHALL be cancelled before the new sample is sent

#### Scenario: Setting the current speed again
- **WHEN** the speed is changed to the speed already set
- **THEN** the sample SHALL be played again and the speed saved

#### Scenario: No screen changes it yet
- **WHEN** the user uses the lessons, the home menu or the language picker
- **THEN** no gesture SHALL change the reading speed

### Requirement: Lessons keep their own timing
The lessons, the spelling of a word, the quiz marker, the home menu and the language picker SHALL play with the lesson timing, whatever reading speed is saved or set: 300 ms between the letters of a word, 1 s between the letters of a spelled word and a 3 s pause before an item repeats. Only reading modes SHALL use the reading timing.

#### Scenario: A lesson word at 5 wpm
- **WHEN** the reading speed is 5 wpm and the lessons play the English word "HI"
- **THEN** the device SHALL be sent `[0, 100, 100, 100, 100, 100, 100, 100, 300, 100, 100, 100]` ms: its letters 300 ms apart, not 1405 ms

#### Scenario: The lesson pauses at 5 wpm
- **WHEN** the reading speed is 5 wpm
- **THEN** the lessons SHALL still pause 3 s before an item repeats and 1 s between spelled letters

#### Scenario: Changing the speed during a run
- **WHEN** the speed is changed after the lessons have started
- **THEN** the lessons' timing SHALL stay the lesson timing
