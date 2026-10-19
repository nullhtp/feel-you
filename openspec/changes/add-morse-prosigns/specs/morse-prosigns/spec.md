## Purpose

The standard Morse prosigns the app uses as service signals (end of message, wait, SOS, error): their patterns, timing and intended uses, and how they stay distinct from the characters a user learns and from the app's own signals.

## ADDED Requirements

### Requirement: A closed set of four prosigns
The system SHALL define exactly four prosigns, the same in every language: end of message (AR), wait (AS), SOS, and error (eight dots, written HH). Code that plays a prosign SHALL name it rather than spell it, and SHALL encode it with the language's codec and play the tokens like any text.

#### Scenario: Four prosigns
- **WHEN** a developer lists the prosigns
- **THEN** there SHALL be exactly four: end of message, wait, SOS and error

#### Scenario: Played through the codec
- **WHEN** a prosign is played
- **THEN** it SHALL be encoded by the codec of the session's language and played through the vibration service's token playback, like a letter

### Requirement: Prosign patterns
Each prosign SHALL be one character of International Morse: end of message `· − · − ·`, wait `· − · · ·`, SOS `· · · − − − · · ·`, error `· · · · · · · ·`. Its dots and dashes SHALL be separated by the gap between the elements of a character only, never by a letter gap. The Morse codec of every language SHALL encode each prosign identically.

#### Scenario: End of message
- **WHEN** the end-of-message prosign is encoded
- **THEN** it SHALL be a short, a long, a short, a long and a short pulse, with no character gap

#### Scenario: Wait
- **WHEN** the wait prosign is encoded
- **THEN** it SHALL be a short, a long and three short pulses, with no character gap

#### Scenario: SOS
- **WHEN** the SOS prosign is encoded
- **THEN** it SHALL be three short, three long and three short pulses, with no character gap

#### Scenario: Error
- **WHEN** the error prosign is encoded
- **THEN** it SHALL be eight short pulses, with no character gap

#### Scenario: Same in all six languages
- **WHEN** each prosign is encoded with the English, Arabic, Russian, Spanish, French and German Morse codecs
- **THEN** all six SHALL return the same tokens

#### Scenario: Not the word of the same letters
- **WHEN** the text "SOS" is encoded
- **THEN** it SHALL be the letters S, O and S with a character gap between each, unlike the SOS prosign

### Requirement: Prosigns follow the Morse timing
A prosign SHALL be timed like any Morse character, from the Morse timing configuration: a dot vibrates for the dot duration, a dash for the dash duration, with the inter-symbol gap between them. With the default timing, end of message SHALL last 1300 ms, wait 1100 ms, SOS 2300 ms and error 1500 ms. A changed timing (such as a speed setting) SHALL apply to prosigns too.

#### Scenario: End of message at the default timing
- **WHEN** the end-of-message prosign is played with the default timing
- **THEN** the device SHALL be sent `[0, 100, 100, 300, 100, 100, 100, 300, 100, 100]` ms, 1300 ms in all

#### Scenario: Wait at the default timing
- **WHEN** the wait prosign is played with the default timing
- **THEN** the device SHALL be sent `[0, 100, 100, 300, 100, 100, 100, 100, 100, 100]` ms, 1100 ms in all

#### Scenario: SOS at the default timing
- **WHEN** the SOS prosign is played with the default timing
- **THEN** the device SHALL be sent `[0, 100, 100, 100, 100, 100, 100, 300, 100, 300, 100, 300, 100, 100, 100, 100, 100, 100]` ms, 2300 ms in all

#### Scenario: Error at the default timing
- **WHEN** the error prosign is played with the default timing
- **THEN** the device SHALL be sent eight 100 ms vibrations, 100 ms apart, 1500 ms in all

#### Scenario: Other timing
- **WHEN** a prosign is played with a timing whose dot, dash and inter-symbol gap differ from the defaults
- **THEN** its vibrations and gaps SHALL take those durations, and no gap SHALL take the inter-character gap

### Requirement: Prosigns differ from every taught character
No prosign SHALL have the pattern of a digit, of a letter of any language's letters level, or of the quiz marker `?`, so a prosign can never be taken for an item the user has learned in any language. The prosigns SHALL also differ from each other.

#### Scenario: Every language
- **WHEN** the four prosign patterns are compared with the digits, the letters and `?` of English, Arabic, Russian, Spanish, French and German
- **THEN** none SHALL be equal

#### Scenario: Prosigns are distinct
- **WHEN** the four prosign patterns are compared with each other
- **THEN** no two SHALL be equal

### Requirement: Prosigns differ from the app's signals
No prosign SHALL be mistakable for the success, error, tap-feedback or cloud-off signals: every vibration of a prosign SHALL last a Morse dot or dash, and every pause inside it the inter-symbol gap, while each of those signals has a vibration shorter than a dot or longer than a dash.

#### Scenario: Against the signals
- **WHEN** each prosign at the default timing is compared with the success and error signals (both versions), the tap feedback and the cloud-off signal
- **THEN** its vibrations SHALL all be 100 or 300 ms and its pauses 100 ms
- **AND** each of those signals SHALL have a vibration of 50 ms, or of 500 ms or more

### Requirement: Intended uses of the prosigns
Each prosign SHALL keep its standard meaning: end of message marks the end of a text in the reader (#44); wait plays while the app is working on something, such as a cloud request (#64); SOS is reserved for the emergency gesture (#80); error is the sender's "I made a mistake" in Morse input (#53). Until those land, no screen SHALL play a prosign. The quiz marker stays the character `?`, and the success and error signals stay non-Morse.

#### Scenario: Nothing plays a prosign yet
- **WHEN** the user goes through the picker, the home menu, the lessons and the quizzes
- **THEN** no prosign SHALL be played

#### Scenario: The quiz marker is not a prosign
- **WHEN** a level's quiz is entered
- **THEN** it SHALL be announced with the character `?` (`· · − − · ·`), as before

#### Scenario: Wrong is not the error prosign
- **WHEN** the user answers wrongly
- **THEN** the app SHALL play its error signal, one long buzz, and not the error prosign
