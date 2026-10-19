## MODIFIED Requirements

### Requirement: Lesson items encode to their level patterns
For every item of every level of every language, the language's Morse codec SHALL encode the item to its level pattern: the signals of a characters level item as pulses, and the token pattern of a words level item with each `CharGap` as a character gap. Played with the default timing, the result SHALL be the millisecond pattern the item had before the codec existed.

#### Scenario: Every digit and letter
- **WHEN** each digit and letter of the English, Arabic, Russian, Spanish, French and German levels is encoded with its language's codec
- **THEN** each dot of its level pattern SHALL be a short pulse, each dash a long pulse, with no character gap

#### Scenario: Every word, including aliases
- **WHEN** each of the 120 words of the six words levels is encoded with its language's codec
- **THEN** the tokens SHALL match its level token pattern, with each `CharGap` as a character gap, including the words written with أ

#### Scenario: Descriptions match the overlay notation
- **WHEN** any lesson item is described with its language's codec
- **THEN** the description SHALL be the item's level pattern written with `·`, `—` and `/`
