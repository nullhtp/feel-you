## Why

German is the most spoken first language in the European Union, about 130 million speakers in all, and German readers write the umlauts Ä, Ö and Ü, which plain A–Z cannot spell (MÜDE). German is the last of the three alphabets asked for in issue #91, after `add-spanish-morse` and `add-french-morse`, built the same way.

## What Changes

- A new `german` value at the end of `MorseLanguage`, after `french`.
- A German alphabet: the 26 letters A–Z with their International Morse patterns (the English ones) plus Ä (`·−·−`), Ö (`−−−·`) and Ü (`··−−`), 29 letters. A–Z keep their places and the umlauts come after Z, in the order Ä, Ö, Ü in which German alphabet lists add them. The digits level is the shared one.
- ß is not taught (see Non-goals).
- A German words level: 20 everyday words for a deaf-blind user (five each of 2, 3, 4 and 5 letters), written only with letters of the German letters level. The list needs a native-speaker review.
- Levels `german-letters` and `german-words`, registered after French.
- A sixth column in the language picker, **Deutsch**, spoken with the `de` locale by screen readers, with Ü (`··−−`) as its identifier vibration.
- `openspec/config.yaml` context, README, store listing, CHANGELOG: six languages.

## Accessibility

- German counts 26 letters, with the umlauts learned after them, so the user's count A=1 … Z=26 still holds and the umlauts are found by swiping on past Z, before the quiz.
- The identifier Ü (`··−−`, 1100 ms with the default timing) differs from E (`·`), ع (`·−·−`), Р (`·−·`), Ñ (`−−·−−`) and É (`··−··`).
- The umlauts have 4 elements, so the quiz marker `?` (6 elements) stays longer than every item, as the `quiz` spec requires.
- Six columns in landscape stay tappable (about 140 points on a 6.1-inch iPhone, 111 on an iPhone SE); swipes and the hold work anywhere.

## Non-goals

- **ß.** It has no ITU code. Its extension code (`···−−··`, "SZ") would be the only item longer than the quiz marker `?` (7 elements against 6) and differs from `?` by one leading dot, so a user could take one for the other. German also writes it SS in capitals, the form the word list uses. The quiz rule stays as it is.
- Sending AE/OE/UE for the umlauts: the app teaches the extension codes German Morse tables list.
- UI localisation and a German store description.

## Capabilities

### New Capabilities

- `german-morse-data`: the German alphabet (A–Z, Ä, Ö, Ü), its learning order and the data of the German words level.

### Modified Capabilities

- `language-selection`: German joins the picker with its label, locale and identifier, and the list of languages.
- `level-system`: the German letters and words levels.
- `morse-alphabet-registry`: the registry holds the German alphabet, which has no aliases.
- `store-metadata`: German in the store's list of taught languages.
- `tactile-codec`: the lesson items the codec is checked against include German.
- `integration-testing`: the language flow end-to-end test gets a German flow.

## Impact

- **Morse data**: new `app/lib/morse/german_alphabet.dart`; `morse_language.dart`, `morse_alphabet_registry.dart`, `morse.dart`.
- **UI**: `language_picker_surface.dart` (identifier, label, locale).
- **Settings**: none. `selected_language` stores `german`; learned items use `learned_items.german.<level>`.
- **Tests**: German data and utility tests (including that ß is not taught), registry and level tests, rows in the picker and integration test tables. `morse_punctuation_test.dart` already checks that `?` is longer than every item of every language and needs no change.
- **Docs**: `openspec/config.yaml`, README, `store/`, `app/README.md`, ROADMAP, CHANGELOG.
