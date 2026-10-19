## Context

See proposal.md for why. This change follows `add-spanish-morse`, which must be applied (and archived) first:

- `spanish_alphabet.dart` showed the pattern: A–Z read from `englishAlphabet.characters`, the language's own letters added, the order written out in full, levels `<language>-letters` and `<language>-words`.
- `language-selection` lists the identifier, label and locale of every language in one requirement ("Language identifiers, labels and locales") and the enum values in another ("Supported languages"); this change adds a French row to each and Français to the picker's column list.
- The picker stores each language's identifier letter and encodes it with the language's Morse codec (`tactileCodecProvider`). The picker tests and the end-to-end flow test (on the `E2EApp` harness) are tables keyed by language, so French adds rows.
- `composeWordPattern` walks a word by UTF-16 code unit: À (U+00C0), Ç (U+00C7), É (U+00C9) and È (U+00C8) must be precomposed in the source.

## Goals / Non-Goals

**Goals:**
- French as data plus three picker entries, with no change to shared code.

**Non-Goals:**
- Accented letters without a Morse code in common use (Â, Ê, Î, Ô, Û, Ù, Ë, Ï, Ü, Ÿ) and the ligatures Œ, Æ.

## Decisions

### 1. Letters: A–Z from English, plus À, Ç, É, È

Patterns of the International Morse extensions (checked against Wikipedia's "Morse code" tables, "Diacritics and non-Latin extensions"): À `·−−·−` (shared with Å), Ç `−·−··` (shared with Ĉ, Ć), É `··−··` (the only accented letter in ITU-R M.1677-1), È `·−··−` (shared with Ł). None equals an English letter or a digit, and the four differ from each other. A–Z come from `englishAlphabet.characters`, as for Spanish.

### 2. Order: after Z, À Ç É È

The rule from `add-spanish-morse` (a letter of the language's own alphabet keeps its place; letters outside the 26-letter alphabet come after Z) puts all four after Z: French has 26 letters and treats accents as marks. Among themselves they follow their base letter (A, C, E), and for the two E's, French dictionary order: é before è. So the user still counts A=1 … Z=26, and reaches the accented letters by swiping on past Z (À is 27th, È 30th, then the quiz).

Alternatives:
- *After their base letter (À after A, Ç after C, É and È after E).* Rejected: every letter from B on would be off by one to four places from the alphabet French speakers count.
- *À Ç È É (Unicode code point order).* Rejected: French dictionary order puts é before è, and code point order is not a teaching order.

### 3. Words: everyday needs, using every accented letter

| Length | Words (English gloss) |
|---|---|
| 2 | ÇA (that, it; "ça va?": how are you?), VA (go! / OK), LÀ (here, there), OK (OK), HÉ (hey!) |
| 3 | OUI (yes), NON (no), EAU (water), MAL (it hurts, "j'ai mal"), BON (good) |
| 4 | AIDE (help), FAIM (hunger), SOIF (thirst), BIEN (well, good), STOP (stop) |
| 5 | MERCI (thank you), FROID (cold), CHAUD (hot), SALUT (hi, bye), APRÈS (later) |

Words needing letters outside the level are left out (ARRÊTE, TÊTE, DÉSOLÉ is 6 letters, FATIGUÉ 7). STOP and OK are loans in everyday French use. The list is marked for a native-speaker review.

### 4. Picker identifier: É

É (`··−··`, 1300 ms) is the most frequent accented letter in French and the one accented letter the ITU standard lists. Its rhythm (two dots, a dash, two dots) is unlike E (`·`), ع (`·−·−`), Р (`·−·`) and Ñ (`−−·−−`), and it is symmetric like Ñ but made of the opposite elements. Label "Français", locale `fr`.

### 5. End-to-end flow

The flow test gets a French row: tap Français (É vibrates), hold, swipe up, swipe right past Z to É (index 28), tap `··−··` back, swipe up to the words, where ÇA is the first word (spelled Ç, A, then played), and tap it back.

## Risks / Trade-offs

- [Risk] Five columns are narrower (about 133 points each on an iPhone SE in landscape) → "Français" scales down to fit its column; the user does not need to find a column, as swipes and the hold work anywhere.
- [Risk] Users who learned French Morse may expect É before È to sit right after E → The order is recorded in the spec and the README; the quiz and learned items are keyed by letter, not position, so reordering later loses nothing.
- [Trade-off] Several accented French letters cannot be taught → They have no Morse code in common use; adding invented codes would teach patterns no other operator knows.

## Migration Plan

None. Appending `french` changes no stored key.
