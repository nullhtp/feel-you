## Why

The lessons teach the user to copy an item they already know: they reached it by counting swipes, so they know which item plays and can tap it back from memory. To read anything later (text-to-Morse, conversation) the user must recognise a pattern they did not choose, and Phase 1 never asks them to. Recognition by touch is the missing step between learning Morse and using it.

## What Changes

- **A quiz slot at the end of every level.** Swiping right on the last item of a level (digits, letters, words, in every language) enters the quiz instead of doing nothing. It is the level's new right wall: the user reaches it by swiping right until the end, without counting. Swipe left returns to the last item; swipe right in the quiz skips to another item. Hold, swipe up/down, shake and double shake work as everywhere else.
- **The quiz announces itself with Morse `?` (`··−−··`).** It plays when the loop starts in the quiz, then the first quiz item. At 6 elements it is longer than any digit or letter (5 at most), so it cannot be mistaken for one, and it has no letter gaps, so it cannot pass for a word.
- **The quiz plays a random item and repeats it**, with the same 3-second pause as the lessons. Words are not spelled first: finding out which word it is, is the exercise.
- **The user answers by echo:** they tap the pattern they felt, checked exactly as in the lessons (1 s of silence or a bottom-strip tap; letter gaps on words).
- **Correct:** the success signal, then a new random item. **Wrong:** the error signal, then the same item again. The quiz moves on only after the user's correct answer or skip.
- **The quiz draws from learned items.** An item is learned the first time the user answers it correctly in the lessons. The quiz picks from the learned items of its level, or from the whole level while fewer than two are learned, and never plays the same item twice in a row.
- **Learned items are saved on the device, per language,** keyed by the item itself (`К`, `ВОДА`), so the quiz grows from session to session. Quiz answers do not add or remove learned items. Saving is best effort, like the language.
- **Every launch still starts at digit 0.** Level and position are not saved.
- **Companion overlay:** in the quiz it shows `QUIZ`, keeps the item hidden until the user has answered (a user with some sight left must not read the answer), and shows the learned count (e.g. `learned 11/32`). The screen-reader summary follows the overlay.

## Accessibility

- No new gesture and no new mode: the quiz is a place reached with the existing swipes, so the user keeps knowing where they are by counting and by walls. The left wall (first item), hold (first item of the level) and shake (digit 0) stay the anchors.
- The only new vibration is the Morse `?`, a real Morse symbol the user can use later, in line with the language identifiers being Morse letters.
- Hiding the answer on screen only matters to users with residual sight (e.g. Usher syndrome), who may look at the overlay.

## Non-goals

- No saved position or level: every launch starts at digit 0, as now.
- No other answer types, such as answering with the next letter of the alphabet (`К` → `Л`) to prove the item was named, not just felt. Possible later.
- No weighting by errors or spaced repetition: the quiz picks uniformly from learned items.
- No scores, statistics or "level passed" state.
- No way to clear learned items from the app; clearing the app's data (Android) or reinstalling (iOS) does it.
- No sharing of learned items between languages, even for the digits, which are the same in every language.
- No status row (time, date, battery): a separate change, `add-status-row`.

## Capabilities

### New Capabilities

- `quiz`: the quiz slot at the end of each level: entering and leaving it, the `?` marker, random item selection, the echo answer and its feedback.
- `learned-items`: when an item counts as learned, and how learned items are kept per language across launches.

### Modified Capabilities

- `learning-session`: swipe right on the last item enters the quiz instead of being a no-op, swipe left from the quiz returns to the last item, and the session can be in the quiz; learned items join the language as state kept across launches.
- `teaching-loop`: a correct answer in the quiz resumes on a new quiz item, words are not spelled in the quiz, and the timing config gains the gap after the `?` marker.
- `language-selection`: the language is no longer the only thing saved.
- `companion-overlay`: the quiz display, the hidden answer and the learned count.

## Impact

- **Session** (`session_state.dart`, `session_notifier.dart`): a quiz position after the last item, its navigation, and the current quiz item.
- **Teaching orchestrator** (`teaching_orchestrator.dart`): the quiz loop (marker, random item, new item after a correct answer), and recording learned items on a correct lesson answer. Random selection must be injectable for tests.
- **Settings**: a learned-items store next to `language_preference.dart`, backed by `SharedPreferences`, with an in-memory fallback like the language store. No new dependency.
- **Morse data**: the `?` pattern, which is not part of any level.
- **UI**: `companion_overlay.dart` (the display and its screen-reader summary) and the input hint in `touch_surface.dart`.
- **Docs**: README (screen map, gestures table: swipe right on the last item; signals table: `?`; the "Almost no state" principle), CHANGELOG, ROADMAP.
- **Tests**: navigation into and out of the quiz on every level, the marker and feedback sequence with the fake vibration service, selection rules (fallback to the whole level, no immediate repeat), persistence per language, and an integration test of learn → quiz.
