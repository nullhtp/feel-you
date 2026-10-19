## Context

See proposal.md for why. The relevant current state:

- Each alphabet is one file in `app/lib/morse/` that builds a `MorseAlphabet` (characters, order, words, word patterns, a letters level and a words level). `morseRegistry` lists the alphabets; `levelsForLanguage` puts the shared digits level first.
- `MorseLanguage` has `english`, `arabic`, `russian`. The picker builds one column per value (`MorseLanguage.values`), and keeps three maps keyed by language: identifier letter (encoded with the language's codec, `tactileCodecProvider`), label and screen-reader locale. Its English hint name is derived from the enum name (`spanish` → "Spanish").
- The saved language is the enum value's `name` (`SharedPreferences` key `selected_language`), and learned items are saved under `learned_items.<language name>.<level name>`. An unknown stored name reads as "nothing saved".
- `encodeLetter` upper-cases its input before the lookup and falls back to the input as given; `composeWordPattern` walks a word by UTF-16 code unit, so every letter must be one precomposed code unit (Ñ is U+00D1).
- Tests in `test/ui/language_picker_non_visual_test.dart` assume three columns: the top-right corner is Russian, a swipe left from English lands on Russian, three swipes right wrap to English.

## Goals / Non-Goals

**Goals:**
- Spanish as data plus three picker entries, following `add-russian-morse`.
- Keep the A–Z patterns in one place, so Spanish (and later French and German) cannot drift from English.
- Make the picker tests and the language specs list-driven, so French and German each add one row.

**Non-Goals:**
- Changing the picker layout, the teaching loop, the gesture classifier or the vibration engine.
- Any migration of saved data: appending an enum value changes no stored key.

## Decisions

### 1. A–Z come from the English alphabet; Ñ is the only Spanish entry

`spanish_alphabet.dart` builds its map as `{...englishAlphabet.characters, 'Ñ': [dash, dash, dot, dash, dash]}`, wrapped unmodifiable. Ñ (`−−·−−`) is the code listed for Ñ in the non-ITU Latin extensions of International Morse (shared with Polish Ń); it matches no English letter and no digit. All 27 patterns were checked against Wikipedia's "Morse code" tables and the existing English table.

The map is therefore `final`, not `const`, and the letters `Level` is built at runtime like the words level. The order list stays a `const` list written out in full, so the learning sequence is visible in one place.

Alternatives:
- *Copy the 26 English entries into the Spanish file.* Rejected: three copies (Spanish, French, German) of the same table are three chances for a typo that no reviewer would spot.
- *Move A–Z into a shared `latin_letters.dart` used by English too.* Rejected for now: it touches `english_alphabet.dart`, which a parallel refactor (#40) also reshapes. Reading `englishAlphabet.characters` gives the same single source with no change to the English file.

### 2. Letter order: the language's own alphabet

Rule for every language (recorded here, applied again by French and German): letters follow the alphabet as its speakers learn it, because the user counts swipes from A. A letter that the language counts as a letter of its own alphabet keeps its place in it; letters outside the 26-letter alphabet come after Z, so A=1 … Z=26 still holds. Spanish counts Ñ as its 15th letter (Real Academia Española, 27 letters), so Ñ sits between N and O and O–Z shift by one, as they do in the Spanish alphabet.

Alternative: *Ñ after Z, so A–Z keep the English positions.* Rejected: a Spanish speaker counts O as the 16th letter.

### 3. Words: everyday needs, no accented vowels

Five each of 2, 3, 4 and 5 letters, mirroring the needs behind the English list (greeting, yes/no, help, pain, water, food, toilet, sleep, temperature, feelings), not translating it word for word:

| Length | Words (English gloss) |
|---|---|
| 2 | NO (no), YA (enough / done), YO (me), VE (go!), AY (ouch) |
| 3 | VEN (come!), SED (thirst), MAL (bad, unwell), PAN (bread), VOY (I'm coming) |
| 4 | HOLA (hello), AGUA (water), BAÑO (toilet), BIEN (well, good), ALTO (stop!) |
| 5 | AYUDA (help), DOLOR (pain), CALOR (heat, hot), SUEÑO (sleepy), FELIZ (happy) |

Words that need an accented vowel are left out (SÍ, FRÍO, PERDÓN, GRACIAS is too long), because the letters level has no accented vowels and a misspelled word would teach the wrong spelling to the helper reading the overlay. That is why "yes" and "cold" are missing. GRACIAS (7) and CANSADO (7) do not fit the length groups. The list is marked for a native-speaker review in the PR.

### 4. Picker identifier: Ñ

Ñ (`−−·−−`, 1700 ms with the default 100/300 ms timing and 100 ms gaps) is the letter that marks Spanish, and its rhythm (two dashes, a dot, two dashes) is unlike E (`·`, 100 ms), ع (`·−·−`, 1100 ms) and Р (`·−·`, 700 ms). Label "Español", locale `es`. The picker stores the letter Ñ and encodes it with the Spanish Morse codec, like the other identifiers; Spanish needs no alias, since every letter of its words is in the letters level.

### 5. Language specs become per-language lists

The main `language-selection` spec has "Three language buttons displayed" and "Enum has exactly three values". OpenSpec cannot drop or rename a scenario in a MODIFIED block, so this change removes those two requirements and adds "Language identifiers, labels and locales" (one table row per language) and "Supported languages" (the ordered values, and the rule to append, never rename). French and German then modify these with one more row each. For the same reason `level-system`'s "Levels defined within MorseAlphabet" now states the naming rule once ("letters"/"words" for English, `<language>-letters`/`<language>-words` otherwise) instead of one sentence per language, which would pass the 500-character limit with the next language.

### 6. Picker tests derive from the language list

The picker tests that hardcode column positions (top-right corner = Russian, swipe left from English = Russian) are rewritten against `MorseLanguage.values` and a test table of label and identifier per language: the last language is `MorseLanguage.values.last`, a column is found by its label. French and German add a table row only.

### 7. End-to-end test with the real picker

A new `app/integration_test/language_flow_test.dart` runs on the `E2EApp` harness: the whole `FeelYouApp` from its launch screen, with nothing saved, the motor answered at the platform channels (the iOS simulator has none), a recording vibration service and the end-to-end timings. For Spanish it taps Español (identifier played), holds to start (lesson on digit 0, language saved), swipes up to the letters, swipes right to Ñ (its pattern plays), taps it back (success, Ñ learned), swipes up to the words and right to BAÑO (spelled letter by letter, then played as a word) and taps it back with bottom-strip letter gaps (success). The test drives real pointer events on the surface, so the dot/dash halves and the bottom strip are taken from the live layout, whatever the simulator's orientation. It is a table, so French and German add a row.

## Risks / Trade-offs

- [Risk] Four columns are narrower on small phones (iPhone SE landscape: about 167 points each) → The label scales down to fit (`FittedBox`), taps still hit a wide column, and swipes and the hold work anywhere.
- [Risk] A word list chosen without a native speaker may sound odd (VE, VOY) → Marked for review in the PR and the CHANGELOG; changing a word later only drops that word's learned state (stored items not in the level are ignored).
- [Risk] Ñ and Polish Ń share the pattern, and some Spanish operators send N instead → The app teaches the extension code, which is what Spanish Morse tables list; this is a teaching choice, not a decoding one.
- [Trade-off] The Spanish letters map is built at runtime from the English one, so it is not `const` → It is built once at start-up, and tests check it is equal, letter by letter, to English A–Z plus Ñ.

## Migration Plan

None. Existing saved languages and learned items keep their keys. Rollback is removing the enum value: a saved `spanish` then reads as "nothing saved" and the picker appears.
