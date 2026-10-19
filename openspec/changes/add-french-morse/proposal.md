## Why

French is spoken by about 300 million people across Europe, Africa and Canada, and French readers write four accented letters that plain A–Z cannot spell (ÇA, LÀ, APRÈS). After Spanish (`add-spanish-morse`), French is the second of the three alphabets asked for in issue #91, built the same way.

## What Changes

- A new `french` value at the end of `MorseLanguage`, after `spanish`.
- A French alphabet: the 26 letters A–Z with their International Morse patterns (the English ones) plus À (`·−−·−`), Ç (`−·−··`), É (`··−··`) and È (`·−··−`), 30 letters. A–Z keep their places and the four accented letters come after Z, in the order À, Ç, É, È. The digits level is the shared one.
- A French words level: 20 everyday words for a deaf-blind user (five each of 2, 3, 4 and 5 letters), written only with letters of the French letters level, so no Ê, Ô, Î, Û, Ù, Â, Ë, Ï or Œ. Each accented letter is used at least once (ÇA, LÀ, HÉ, APRÈS). The list needs a native-speaker review.
- Levels `french-letters` and `french-words`, registered after Spanish.
- A fifth column in the language picker, **Français**, spoken with the `fr` locale by screen readers, with É (`··−··`) as its identifier vibration.
- Docs: README, store listing, CHANGELOG.

## Accessibility

- French has 26 letters; accents are marks on them, not letters of their own. So the user's count A=1 … Z=26 still holds, and the accented letters are found by swiping past Z, before the quiz.
- The identifier É (`··−··`, 1300 ms with the default timing) differs from E (`·`), ع (`·−·−`), Р (`·−·`) and Ñ (`−−·−−`). É is the one accented letter in the ITU International Morse standard, and the most frequent accented letter in French.
- All four accented letters have 5 elements, so the quiz marker `?` (6 elements) stays longer than every item.
- Five columns in landscape stay tappable (about 170 points on a 6.1-inch iPhone, 133 on an iPhone SE); swipes and the hold work anywhere.

## Non-goals

- The other French accented letters (Â, Ê, Î, Ô, Û, Ù, Ë, Ï, Ü, Ÿ) and the ligatures Œ and Æ: they have no Morse codes in common use, and French operators send the plain letter. Words that need them (ARRÊTE, TÊTE) are left out rather than misspelled.
- UI localisation and a French store description.
- German, which follows in `add-german-morse`.

## Capabilities

### New Capabilities

- `french-morse-data`: the French alphabet (A–Z, À, Ç, É, È), its learning order and the data of the French words level.

### Modified Capabilities

- `language-selection`: French joins the picker with its label, locale and identifier, and the list of languages.
- `level-system`: the French letters and words levels.
- `morse-alphabet-registry`: the registry holds the French alphabet, which has no aliases.
- `store-metadata`: French in the store's list of taught languages.
- `tactile-codec`: the lesson items the codec is checked against include French.
- `integration-testing`: the language flow end-to-end test gets a French flow.

## Impact

- **Morse data**: new `app/lib/morse/french_alphabet.dart`; `morse_language.dart`, `morse_alphabet_registry.dart`, `morse.dart`.
- **UI**: `language_picker_surface.dart` (identifier, label, locale).
- **Settings**: none. `selected_language` stores `french`; learned items use `learned_items.french.<level>`.
- **Tests**: French data and utility tests, registry and level tests, one row in the picker and integration test tables.
- **Docs**: README, `store/store-info.md`, `store/description-en.md`, `store/description-ar.md`, `store/privacy-policy.md`, `app/README.md`, ROADMAP, CHANGELOG.
