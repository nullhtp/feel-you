## Why

Spanish is the first language of nearly 500 million people, more than any language Feel You teaches today, and its alphabet is the Latin one with Ñ. The alphabet registry already takes new languages as data (see the archived `add-russian-morse`), so Spanish needs its letters, its words and an identifier in the picker (issue #91, the first of Spanish, French and German).

## What Changes

- A new `spanish` value at the end of `MorseLanguage`, so the saved names of the existing languages do not change.
- A Spanish alphabet: the 26 letters A–Z with their International Morse patterns (the English ones) plus Ñ (`−−·−−`), 27 letters in Spanish alphabetical order with Ñ after N. The digits level is the shared one.
- A Spanish words level: 20 everyday words for a deaf-blind user (five each of 2, 3, 4 and 5 letters), written only with letters of the Spanish letters level, so no accented vowels. Two words use Ñ (BAÑO, SUEÑO). The list needs a native-speaker review.
- Levels `spanish-letters` and `spanish-words`, registered after Russian.
- A fourth column in the language picker, **Español**, spoken with the `es` locale by screen readers, with Ñ (`−−·−−`) as its identifier vibration.
- The picker's identifier requirement is rewritten as one table of identifier, label and locale per language, and the `MorseLanguage` requirement as an ordered list of languages, so later languages add a row instead of renaming scenarios (`Three language buttons displayed`, `Enum has exactly three values`).
- Learned items and the saved language work for Spanish with no code change: both are keyed by the language's value name.
- Docs: README (languages, letters, words, picker columns, identifiers), store listing, CHANGELOG.

## Accessibility

- The user counts swipes to know where they are, so the letters follow the alphabet Spanish speakers learn at school: Ñ is the 15th letter, between N and O.
- The identifier Ñ (`−−·−−`, 1.7 s with the default timing) differs from E (`·`), ع (`·−·−`) and Р (`·−·`) in length and rhythm, and it is the letter that sets Spanish apart.
- Ñ has 5 elements, so the quiz marker `?` (6 elements) stays longer than every item.
- Four columns in landscape stay wide enough to tap (about 200 points on a 6.1-inch iPhone); swipes and the hold work anywhere, so a user without sight never needs to find a column.

## Non-goals

- Accented vowels (Á, É, Í, Ó, Ú, Ü): they have no Morse codes in common use and Spanish Morse practice sends the plain vowel. Words that need them (SÍ, FRÍO, PERDÓN) are left out rather than misspelled.
- The former digraph letters CH and LL, which the Real Academia Española dropped from the alphabet in 2010.
- UI localisation: the helper hint, overlay and screen-reader hints stay in English.
- A Spanish store description; only the store's list of taught languages changes.
- French and German, which follow in `add-french-morse` and `add-german-morse`.

## Capabilities

### New Capabilities

- `spanish-morse-data`: the Spanish alphabet (A–Z and Ñ), its learning order and the data of the Spanish words level.

### Modified Capabilities

- `language-selection`: Spanish joins the picker with its label, locale and identifier; the identifier and enum requirements become per-language lists.
- `level-system`: the Spanish letters and words levels, and the level naming rule for every language.
- `morse-alphabet-registry`: the registry holds the Spanish alphabet (and the list of registered alphabets is brought up to date, it lacked Russian); Spanish has no aliases.
- `store-metadata`: Spanish in the store's list of taught languages.
- `tactile-codec`: the lesson items the codec is checked against include Spanish.
- `integration-testing`: an end-to-end test of the flows of the new languages, starting with Spanish.

## Impact

- **Morse data**: new `app/lib/morse/spanish_alphabet.dart`; `morse_language.dart` (enum value), `morse_alphabet_registry.dart` (registration), `morse.dart` (export).
- **UI**: `language_picker_surface.dart` (identifier letter, label, locale). The identifier is encoded with the Spanish Morse codec like the others; the picker builds one column per enum value, so the layout needs no change.
- **Settings**: none. `selected_language` stores `spanish`; learned items use `learned_items.spanish.<level>`.
- **Tests**: Spanish data and utility tests, registry and level tests, picker tests made independent of the number of languages, and an integration test of the Spanish flow from the picker to a word.
- **Docs**: README, `store/store-info.md`, `store/description-en.md`, `store/privacy-policy.md`, CHANGELOG.
