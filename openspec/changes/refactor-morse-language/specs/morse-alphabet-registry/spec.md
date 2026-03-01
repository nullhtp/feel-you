## ADDED Requirements

### Requirement: MorseAlphabet data class
The system SHALL define a `MorseAlphabet` class containing:
- `language`: A `MorseLanguage?` field. When `null`, the alphabet is universal (included for all languages, e.g., digits).
- `characters`: A `Map<String, List<MorseSignal>>` mapping each character to its Morse signal pattern.
- `characterOrder`: A `List<String>` defining the learning sequence for the characters.
- `wordList`: An optional `List<String>?` of words for the word-level, or `null` if this alphabet has no word level.
- `wordPatterns`: An optional `Map<String, List<MorseToken>>?` mapping words to their token patterns, or `null` if no word level.
- `levels`: A `List<Level>` of levels defined by this alphabet.

#### Scenario: Universal alphabet has null language
- **WHEN** the digits `MorseAlphabet` is inspected
- **THEN** its `language` field SHALL be `null`

#### Scenario: Language-specific alphabet has language set
- **WHEN** the English `MorseAlphabet` is inspected
- **THEN** its `language` field SHALL be `MorseLanguage.english`

#### Scenario: Alphabet characters map is accessible
- **WHEN** the English alphabet's `characters` map is queried for 'A'
- **THEN** it SHALL return `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Character order defines learning sequence
- **WHEN** the English alphabet's `characterOrder` is inspected
- **THEN** it SHALL start with 'A' and end with 'Z' with all 26 letters in order

#### Scenario: Alphabet with words has wordList and wordPatterns
- **WHEN** the English alphabet is inspected
- **THEN** `wordList` SHALL be a list of 20 words and `wordPatterns` SHALL map each word to its token pattern

#### Scenario: Alphabet without words has null wordList
- **WHEN** the digits alphabet is inspected
- **THEN** `wordList` SHALL be `null` and `wordPatterns` SHALL be `null`

### Requirement: MorseAlphabetRegistry
The system SHALL define a `MorseAlphabetRegistry` that holds all registered `MorseAlphabet` instances and provides lookup methods. The registry SHALL be populated at module initialization time.

#### Scenario: Registry contains all registered alphabets
- **WHEN** `registry.all` is accessed
- **THEN** it SHALL return a list containing the digits, English, and Arabic alphabets

#### Scenario: Lookup by language
- **WHEN** `registry.forLanguage(MorseLanguage.english)` is called
- **THEN** it SHALL return the English `MorseAlphabet`

#### Scenario: Lookup universal alphabet
- **WHEN** `registry.universal` is accessed
- **THEN** it SHALL return the digits `MorseAlphabet` (where `language` is `null`)

#### Scenario: Registry returns null for unregistered language
- **WHEN** `registry.forLanguage` is called with a language that has no registered alphabet
- **THEN** it SHALL return `null`

### Requirement: Registry provides levels for language
The registry SHALL provide a `levelsForLanguage(MorseLanguage language)` method that returns an ordered, unmodifiable list of levels. The list SHALL include levels from universal alphabets first, followed by levels from the language-specific alphabet.

#### Scenario: English levels from registry
- **WHEN** `registry.levelsForLanguage(MorseLanguage.english)` is called
- **THEN** it SHALL return a list containing the digits level, English letters level, and English words level, in that order

#### Scenario: Arabic levels from registry
- **WHEN** `registry.levelsForLanguage(MorseLanguage.arabic)` is called
- **THEN** it SHALL return a list containing the digits level, Arabic letters level, and Arabic words level, in that order

#### Scenario: Levels list is unmodifiable
- **WHEN** a consumer attempts to add or remove items from the list returned by `levelsForLanguage`
- **THEN** it SHALL throw an `UnsupportedError`

### Requirement: Registry provides encode and decode
The registry SHALL provide `encodeLetter(String letter, MorseLanguage language)` and `decodePattern(List<MorseSignal> pattern, MorseLanguage language)` methods that delegate to the appropriate alphabet(s). Both methods SHALL check the universal alphabet (digits) and the language-specific alphabet.

#### Scenario: Encode English letter via registry
- **WHEN** `registry.encodeLetter('A', MorseLanguage.english)` is called
- **THEN** it SHALL return `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Encode digit via registry for any language
- **WHEN** `registry.encodeLetter('5', MorseLanguage.english)` is called
- **THEN** it SHALL return `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Decode English pattern via registry
- **WHEN** `registry.decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.english)` is called
- **THEN** it SHALL return 'A'

#### Scenario: Decode Arabic pattern via registry
- **WHEN** `registry.decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.arabic)` is called
- **THEN** it SHALL return 'ا' (Alif)

#### Scenario: Encode unknown character returns null
- **WHEN** `registry.encodeLetter('ا', MorseLanguage.english)` is called (Arabic letter with English language)
- **THEN** it SHALL return `null`

### Requirement: Alphabet data files are self-contained
Each language's alphabet data SHALL be defined in a single file that constructs a `MorseAlphabet` instance. Adding a new language SHALL require only creating one new data file and registering its alphabet in the registry.

#### Scenario: English alphabet defined in one file
- **WHEN** a developer inspects the English alphabet data file
- **THEN** it SHALL contain the character map, character order, word list, word patterns, and level definitions for English

#### Scenario: Adding a new language requires one file
- **WHEN** a developer wants to add a new language (e.g., Russian)
- **THEN** they SHALL only need to create one data file with a `MorseAlphabet` and register it in the registry
