## Context

See proposal.md for why. This change follows `add-spanish-morse` and `add-french-morse`, which must be applied (and archived) first; it reuses their pattern: A–Z read from `englishAlphabet.characters`, the order written out, one row more in the `language-selection` tables, the picker test table and the end-to-end flow table.

What matters for German:

- The quiz marker `?` (`··−−··`) works because at 6 elements it is longer than every digit and letter (`quiz` spec, scenario "Marker is longer than any character"; `morse_punctuation_test.dart` checks it for every language). Every German letter must therefore have at most 5 elements.
- `composeWordPattern` walks a word by UTF-16 code unit: Ä (U+00C4), Ö (U+00D6) and Ü (U+00DC) must be precomposed in the source.

## Goals / Non-Goals

**Goals:**
- German as data plus three picker entries, with no change to shared code or to the quiz.

**Non-Goals:**
- ß (decision 2), and the transcriptions AE, OE, UE.

## Decisions

### 1. Letters: A–Z from English, plus Ä, Ö, Ü

Patterns, checked against the English and German Wikipedia Morse tables: Ä `·−·−` (shared with Æ, Ą, and the same as Arabic ع), Ö `−−−·` (shared with Ó, Ø), Ü `··−−` (shared with Ŭ). None equals an English letter or a digit, and all have 4 elements. A–Z come from `englishAlphabet.characters`.

### 2. ß is left out

ß is not in the letters level, so it is neither taught, quizzed nor encodable: `encodeLetter('ß', german)` returns `null` and the German Morse codec rejects it, which tests pin. The user decided this, for these reasons:

- It has no ITU code; the code German tables list for it (`···−−··`, "SZ") is an unofficial extension.
- That code has 7 elements. It would be the only item longer than the quiz marker `?` (6), breaking the quiz rule that the marker is longer than every item.
- It differs from `?` (`··−−··`) by one leading dot, so a user who misses the first dot would feel the marker.
- German writes ß as SS in capitals, and the word list is in capitals, so the words never needed it.

Alternative: *teach ß and relax the quiz rule to "no item equals `?`, only ß is longer".* Rejected for the reasons above; it would also be the only language whose items do not all fit under the marker.

### 3. Order: after Z, Ä Ö Ü

The rule from `add-spanish-morse` (letters outside the 26-letter alphabet come after Z) applies: German schools teach A–Z, then the umlauts in the order Ä, Ö, Ü. The user still counts A=1 … Z=26.

Alternative: *Umlauts after their base letter, as German dictionaries sort them (ä as a).* Rejected: dictionaries sort ä as a, they do not count it as a letter between A and B, and the user's count of B–Z would shift.

### 4. Words: everyday needs

| Length | Words (English gloss) |
|---|---|
| 2 | JA (yes), AU (ouch), DA (here, there), WO (where?), DU (you) |
| 3 | GUT (good), WEH (it hurts, "tut weh"), KLO (toilet), GEH (go!), AUF (up, open) |
| 4 | NEIN (no), HALT (stop!), KALT (cold), WARM (warm), MÜDE (tired) |
| 5 | HILFE (help), DANKE (thank you), BITTE (please), HALLO (hello), ESSEN (food, to eat) |

WASSER (6) and TOILETTE (8) do not fit the length groups. Words with ß (HEISS, FUSS in capitals) are not used. The list is marked for a native-speaker review.

### 5. Picker identifier: Ü

Ü (`··−−`, 1100 ms) is a letter only German has among the six languages, and its rhythm (two dots, two dashes) differs from all other identifiers: E `·`, ع `·−·−`, Р `·−·`, Ñ `−−·−−`, É `··−··`. Ä was not chosen because its pattern is the Arabic identifier ع. Label "Deutsch", locale `de`.

### 6. End-to-end flow

The German row of the flow test: tap Deutsch (Ü vibrates), hold, swipe up, swipe right past Z to Ö (index 27, a different pattern from the identifier Ü), tap `−−−·` back, swipe up to the words and right to MÜDE (index 14), which is spelled M, Ü, D, E and played, and tap it back.

### 7. Docs that count the languages

This is the last of the three changes, so it also updates the `context` in `openspec/config.yaml` ("Three languages (English, Arabic, Russian)" becomes six) and the ROADMAP's language count.

## Risks / Trade-offs

- [Risk] German users expect ß → It is recorded as a non-goal with its reasons; adding it later means revisiting the quiz marker rule.
- [Risk] Six columns are narrow on small phones (about 111 points on an iPhone SE in landscape) → Labels scale down; swipes and the hold work anywhere, and the picker never needs a column to be found.
- [Risk] Two letters on screen look alike for a sighted helper (Ü vs U) → The overlay shows the pattern under the letter.

## Migration Plan

None. Appending `german` changes no stored key.
