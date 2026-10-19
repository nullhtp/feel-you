## ADDED Requirements

### Requirement: Tactile tokens
The system SHALL define the tactile tokens that codecs produce and the vibration engine plays: a short pulse, a long pulse, an empty slot (a pulse-length silence), a character gap and a word gap. Tokens SHALL carry no duration and no amplitude: the engine's timing configuration decides how long each one lasts, so a codec decides only what is felt, in which order, and a reading speed never re-encodes a text.

#### Scenario: Five token kinds
- **WHEN** a developer lists the tactile tokens
- **THEN** there SHALL be exactly five: short pulse, long pulse, empty slot, character gap and word gap

#### Scenario: Same tokens feel the same
- **WHEN** two codecs produce the same list of tokens
- **THEN** the vibration engine SHALL play them identically

#### Scenario: A prosign fits as one character
- **WHEN** a codec encodes a sign as a run of pulses with no character gap inside, such as SOS as three short, three long and three short pulses
- **THEN** the tokens SHALL be a valid pattern that plays as a single character, with no other token kind needed

#### Scenario: A braille cell fits as six slots
- **WHEN** a codec encodes a braille cell as six slots, each a short pulse (raised dot) or an empty slot (flat dot)
- **THEN** the tokens SHALL be a valid pattern, with no other token kind needed

#### Scenario: Words are separated by a word gap
- **WHEN** a codec encodes a text of two words
- **THEN** a single word gap SHALL separate the tokens of the first word from those of the second, with no character gap next to it

### Requirement: Morse codec separates words with a word gap
The Morse codec SHALL encode any run of whitespace (spaces, tabs, line breaks) between two words as one word gap, in place of the character gap, and SHALL ignore whitespace before the first word and after the last. Its description SHALL write a word gap as `//`. A text of whitespace only SHALL give no tokens and an empty description. Every word SHALL be encoded as it is on its own.

#### Scenario: Two words
- **WHEN** the English Morse codec encodes "HI OK"
- **THEN** it SHALL return the tokens of "HI", a word gap, then the tokens of "OK"

#### Scenario: A run of whitespace is one word gap
- **WHEN** the English Morse codec encodes "HI   OK", "HI\tOK" or "HI" and "OK" on two lines
- **THEN** each SHALL return the same tokens as "HI OK"

#### Scenario: Whitespace around the text
- **WHEN** the English Morse codec encodes " HI " or "HI\n"
- **THEN** it SHALL return the tokens of "HI", with no gap before or after

#### Scenario: Description of two words
- **WHEN** the English Morse codec describes "HI OK"
- **THEN** it SHALL return "· · · · / · · // — — — / — · —"

#### Scenario: Words of another language
- **WHEN** the Russian Morse codec encodes "ДА НЕТ"
- **THEN** it SHALL return the tokens of "ДА", a word gap, then the tokens of "НЕТ"

#### Scenario: An unknown character in a later word
- **WHEN** the English Morse codec encodes or describes "HI A!"
- **THEN** it SHALL throw an `ArgumentError` that names "!"

## MODIFIED Requirements

### Requirement: Morse codec rejects what it cannot encode
The Morse codec SHALL throw an `ArgumentError` naming the character when the text contains a character it cannot encode for its language, including any punctuation other than `?`. Whitespace is not a character it encodes: it only separates words (see *Morse codec separates words with a word gap*). It SHALL return no tokens for an empty text.

#### Scenario: Unknown character
- **WHEN** the English Morse codec encodes "A!"
- **THEN** it SHALL throw an `ArgumentError` that names "!"

#### Scenario: Space is not encoded
- **WHEN** the English Morse codec encodes " " or "HI OK"
- **THEN** it SHALL not throw, and no space SHALL give a pulse: " " SHALL return no tokens, and "HI OK" only the pulses of H, I, O and K with a word gap between the two words

#### Scenario: Empty text
- **WHEN** the Morse codec encodes or describes an empty text
- **THEN** it SHALL return no tokens and an empty description

### Requirement: Splitting tokens into characters
The system SHALL split a token pattern at its character gaps and word gaps into the tokens of each character, in order, so a caller can play a text one character at a time without knowing the codec. A pattern without a gap SHALL be one character, and an empty pattern SHALL have none.

#### Scenario: A word splits into its letters
- **WHEN** the tokens of the English word "HI" are split
- **THEN** the result SHALL be the tokens of "H" followed by the tokens of "I"

#### Scenario: A run of pulses stays whole
- **WHEN** a pattern with no character gap, such as the tokens of "?", is split
- **THEN** the result SHALL be that pattern as a single character

#### Scenario: Empty pattern
- **WHEN** an empty pattern is split
- **THEN** the result SHALL be empty

#### Scenario: Two words split into their letters
- **WHEN** the tokens of the English text "HI OK" are split
- **THEN** the result SHALL be the tokens of "H", "I", "O" and "K", none of them containing a gap

## REMOVED Requirements

### Requirement: Tactile token vocabulary
**Reason**: The vocabulary gains a fifth token, the word gap, so its "Four token kinds" scenario no longer holds and has to be renamed, which a modified requirement cannot do.
**Migration**: See *Tactile tokens*, which keeps every other scenario and adds the word gap.
