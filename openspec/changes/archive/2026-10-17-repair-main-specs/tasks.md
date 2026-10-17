## 1. Find what was lost

- [x] 1.1 Replay every archived change's deltas in commit order and compare the result with the main specs: which requirements are missing, which were edited in place
- [x] 1.2 Check each missing requirement against the app code and decide: restore it as it holds today, or record it as dropped (table in the proposal)

## 2. Specs

- [x] 2.1 Add `# <name> Specification`, `## Purpose` and `## Requirements` to the 25 main specs without them, and remove the leftover `## ADDED/MODIFIED Requirements` headers
- [x] 2.2 `language-selection`: restore the `MorseLanguage` enum and the picker as it works today; replace the non-persistent picker with *The chosen language is saved*
- [x] 2.3 `learning-session`: restore the phase, item navigation, reset and provider requirements; replace *State is in-memory only*; start in the saved language
- [x] 2.4 `split-input`: restore *Screen width provided to classifier*; bottom-strip taps are the classifier's job
- [x] 2.5 `flutter-app-scaffold`: replace the placeholder screen with *App starts on the language picker or the lessons*
- [x] 2.6 `touch-surface`: what the surface forwards, the overlay, how the lesson screen is reached
- [x] 2.7 `arabic-morse-data`: correct the six wrong letter patterns, the word list and the alias letters
- [x] 2.8 `word-morse-data`: the current English word list
- [x] 2.9 `level-system`: `kind` and `wordPatterns` in the `Level` data model
- [x] 2.10 Shorten every requirement over 500 characters: move the letter tables of `digit-morse-data`, `russian-morse-data` and `arabic-morse-data` into scenarios, and the `MorseAlphabet` fields into one sentence

## 3. OpenSpec config

- [x] 3.1 Rewrite the `context` in `openspec/config.yaml` to describe the shipped app

## 4. Verification

- [x] 4.1 Check the restored and corrected requirements against the code: `MorseLanguage`, `SessionNotifier`, `sessionNotifierProvider`, `LanguagePickerSurface`, `LanguagePreferenceStore`, `GestureClassifier`, `TouchSurface`, `Level`, the alphabets' letter tables and word lists
- [x] 4.2 `openspec validate repair-main-specs --strict`
- [x] 4.3 After archiving, `openspec validate --specs --strict` passes for all 29 specs
