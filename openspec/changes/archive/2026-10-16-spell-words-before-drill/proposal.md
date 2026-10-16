## Why

The app's core rule is that a deaf-blind user always knows the current item without outside help: digits and letters are in order, so position *n* is item *n*. The words levels break this ([#8](https://github.com/nullhtp/feel-you/issues/8)). Words are grouped by length and otherwise in no order a user can reconstruct, so after swiping to the seventh word the user cannot know it is `EAT`. They can echo the pattern back, but they cannot tell whether they recognised it. The companion overlay shows the word, but only to a sighted observer.

## What Changes

- When the teaching loop starts on a word, it first **spells** the word: it plays the word's letters one at a time with a 1-second gap between them, then the usual 3-second pause, then the word itself, which repeats as before. The user reads the word with the letters they learned on the letters level.
- The loop starts on a word, and so spells it, after every navigation (swipe, level change, hold, shake) and on every `start()` (the lessons opening, or the app coming back to the foreground).
- After success or error feedback the loop resumes with the word itself, without spelling it again: the user has not moved.
- The spelling is part of the `playing` phase: a tap interrupts it and the app listens, a bottom-strip tap is ignored, and navigation abandons it.
- New `TeachingTimingConfig.spellingLetterGap`, default 1000 ms.

## Non-goals

- No change to the word lists or their order. Sorting them (option 3 in #8) still would not tell the user which word they are on.
- No spelling on the digits and letters levels: there the position already identifies the item, and a single character spelled is the character itself.
- No new session phase or overlay label: the overlay already shows the word to a sighted helper, and the phase stays `playing`.
- No new vibration signal to mark the start or end of the spelling: the 1-second gaps (between the 300 ms letter gap of a drilled word and the 3-second repeat pause) are the cue.
- No spelling after a wrong answer. The user can swipe away and back to hear it again.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `teaching-loop`: the loop spells a word before drilling it; `TeachingTimingConfig` gains `spellingLetterGap`.

## Impact

- **Teaching orchestrator** (`teaching_orchestrator.dart`): `_runLoop` takes `spellWord`, set by `start()` and navigation but not by the feedback resume; new `_spellWord` and an interruptible `_pause` shared with the repeat pause.
- **Timing** (`teaching_timing_config.dart`): `spellingLetterGap`.
- **Morse data** (`morse_word_builder.dart`): `splitWordPattern`, the inverse of `composeWordPattern`, so the spelling uses the same per-letter patterns as the drilled word (including Arabic letter forms such as `أ`).
- **Vibration**: no interface change. Each spelled letter is one `playMorsePattern` call.
- **Accessibility**: words become identifiable without sighted help, at the cost of a few seconds each time the user arrives at a word (a 5-letter word adds four 1-second gaps).
- **Tests**: orchestrator tests that drill words use a short `spellingLetterGap`; new spelling tests.
