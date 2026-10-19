## MODIFIED Requirements

### Requirement: Russian word list ordering
The Russian `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 Russian words chosen for the daily needs of deaf-blind users, in uppercase Cyrillic, grouped by length, shortest first: five each of 2, 3, 4 and 5 letters. Within a length the order is the learning order of the list; it is not sorted by usage frequency.

#### Scenario: Russian word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Russian word list starts with shortest words
- **WHEN** the first 5 entries of `wordList` are inspected
- **THEN** they SHALL all be 2-letter words

#### Scenario: Russian words are grouped by length
- **WHEN** the entries of `wordList` are inspected in order
- **THEN** entries 6 to 10 SHALL be 3-letter words, entries 11 to 15 4-letter words, and entries 16 to 20 5-letter words

#### Scenario: Russian word list content
- **WHEN** `wordList` is inspected
- **THEN** it SHALL equal:
  - 2 letters: ДА, НЕ, ОН, НУ, УЖ
  - 3 letters: НЕТ, ЕДА, СОН, ДОМ, ПИЛ
  - 4 letters: БОЛЬ, СТОП, ВОДА, ХОЧУ, ЖАРА
  - 5 letters: СПАТЬ, УСТАЛ, ЖАРКО, ХОЛОД, ПУСТЬ

#### Scenario: Every Russian word has a pattern entry
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word

#### Scenario: Words are in uppercase Cyrillic
- **WHEN** any word in `wordList` is inspected
- **THEN** it SHALL consist entirely of uppercase Cyrillic letters
