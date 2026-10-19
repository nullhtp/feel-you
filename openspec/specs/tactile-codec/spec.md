# tactile-codec Specification

## Purpose
The seam between text and vibration: the tactile tokens that every code (Morse today, braille later) produces and the vibration engine plays, the codec interface that turns text into those tokens and into a helper-readable description, and the Morse codec.

## Requirements

### Requirement: Tactile codec interface
The system SHALL define a `TactileCodec` interface with `encode(text)`, which returns the tactile tokens that play the text, and `describe(text)`, which returns the text form of the same pattern for a sighted helper. Code that plays or shows a text SHALL go through this interface, so it does not depend on which code is in use.

#### Scenario: Encode returns tokens
- **WHEN** `encode` is called with a text the codec supports
- **THEN** it SHALL return the list of tactile tokens that plays that text

#### Scenario: Describe returns helper notation
- **WHEN** `describe` is called with the same text
- **THEN** it SHALL return the written form of the pattern `encode` returns, for the companion overlay

### Requirement: Morse codec encodes text per language
The Morse codec SHALL encode a text for one language character by character, looking each up in the language's letters (ignoring case), the language's aliases, the digits and the question mark. Each dot SHALL be a short pulse and each dash a long pulse, and consecutive characters SHALL be separated by exactly one character gap.

#### Scenario: English letter
- **WHEN** the English Morse codec encodes "A"
- **THEN** it SHALL return a short pulse and a long pulse

#### Scenario: Case is ignored
- **WHEN** the English Morse codec encodes "a"
- **THEN** it SHALL return the same tokens as for "A"

#### Scenario: Digits in every language
- **WHEN** the Arabic Morse codec encodes "5"
- **THEN** it SHALL return five short pulses

#### Scenario: Word with character gaps
- **WHEN** the English Morse codec encodes "IT"
- **THEN** it SHALL return two short pulses, a character gap and a long pulse

#### Scenario: Arabic alias uses Alif's pattern
- **WHEN** the Arabic Morse codec encodes "ألم"
- **THEN** its tokens SHALL start with Alif's short and long pulse, followed by a character gap

#### Scenario: Russian alias uses Е's pattern
- **WHEN** the Russian Morse codec encodes "Ё"
- **THEN** it SHALL return a single short pulse

#### Scenario: Question mark in every language
- **WHEN** any language's Morse codec encodes "?"
- **THEN** it SHALL return the pulses of Morse `··−−··` with no character gap

#### Scenario: Another language's letter
- **WHEN** the English Morse codec encodes the Arabic letter "ا"
- **THEN** it SHALL throw an `ArgumentError`: a codec knows its own language's letters and the shared digits only

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

### Requirement: Morse codec describes text
The Morse codec's description SHALL write each dot as `·`, each dash as `—` and each character gap as `/`, separated by single spaces, for exactly the characters it encodes, and SHALL throw an `ArgumentError` for the characters it cannot encode.

#### Scenario: Letter description
- **WHEN** the English Morse codec describes "A"
- **THEN** it SHALL return "· —"

#### Scenario: Digit description
- **WHEN** the English Morse codec describes "5"
- **THEN** it SHALL return "· · · · ·"

#### Scenario: Word description
- **WHEN** the English Morse codec describes "IT"
- **THEN** it SHALL return "· · / —"

#### Scenario: Unknown character description
- **WHEN** the English Morse codec describes "A!"
- **THEN** it SHALL throw an `ArgumentError`

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

### Requirement: Codec per language through a provider
The system SHALL provide the codec of each language through a Riverpod provider keyed by the language, which tests can override. The default SHALL be the Morse codec of that language, looking characters up in the registry given by the Morse registry provider.

#### Scenario: Default codec is Morse
- **WHEN** the codec provider is read for `MorseLanguage.russian`
- **THEN** it SHALL return a Morse codec that encodes "А" as a short and a long pulse

#### Scenario: Provider can be overridden
- **WHEN** a test overrides the codec provider for a language
- **THEN** every playback and description for that language SHALL use the overriding codec

### Requirement: Codec encodes and describes prosigns
Besides texts, the `TactileCodec` interface SHALL encode a named prosign (see `morse-prosigns`) into tactile tokens and describe it in the helper's notation. The tokens SHALL be one character: pulses only, with no character gap. The Morse codec SHALL do this the same way for every language, without looking at the language's alphabet, and its description SHALL use the notation of `describe`.

#### Scenario: Encode a prosign
- **WHEN** the Morse codec of any language encodes the end-of-message prosign
- **THEN** it SHALL return a short, a long, a short, a long and a short pulse, and no character gap

#### Scenario: Describe a prosign
- **WHEN** the Morse codec describes the end-of-message, wait, SOS and error prosigns
- **THEN** it SHALL return "· — · — ·", "· — · · ·", "· · · — — — · · ·" and "· · · · · · · ·"

#### Scenario: A prosign splits as one character
- **WHEN** the tokens of any prosign are split at their character gaps
- **THEN** the result SHALL be a single character

#### Scenario: Through the provider
- **WHEN** the codec provider is read for a language and asked for the SOS prosign
- **THEN** it SHALL return the same tokens as the Morse codec of any other language

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
