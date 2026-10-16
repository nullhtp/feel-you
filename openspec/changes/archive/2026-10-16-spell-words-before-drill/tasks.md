## 1. Morse data

- [x] 1.1 Add `splitWordPattern` to `morse_word_builder.dart`: split a word token pattern at its `CharGap`s into the signals of each letter
- [x] 1.2 Test it, including a round trip over every English, Arabic and Russian word

## 2. Timing

- [x] 2.1 Add `spellingLetterGap` (default 1000 ms) to `TeachingTimingConfig`
- [x] 2.2 Test the default, and that it lies between the drilled letter gap and the repeat pause

## 3. Teaching orchestrator

- [x] 3.1 Extract the cancellable repeat pause into `_pause`, clearing `_pauseCompleter` only if it is still its own
- [x] 3.2 Add `_spellWord`: play each letter, with `_pause(spellingLetterGap)` between letters, exiting when the loop is interrupted, stopped or superseded
- [x] 3.3 `_runLoop(spellWord:)`: on a words level, replace the first playback with the spelling
- [x] 3.4 Spell from `start()` and `_onNavigate`; resume without spelling after feedback

## 4. Tests

- [x] 4.1 Give the orchestrator test harnesses that drill words a short `spellingLetterGap`, and update the tests that assert a word's first playback
- [x] 4.2 Spelling tests: start, gap length, pause before the drill, restart after stop, each navigation, the listening boundary restart, no spelling after correct or wrong feedback
- [x] 4.3 Interruption tests: tap, bottom-strip tap, navigation and stop during a letter gap; no spelling on a characters level

## 5. Docs

- [x] 5.1 README: prerequisites, the learning loop and the timing table
- [x] 5.2 ROADMAP: move #8 from Next to done
