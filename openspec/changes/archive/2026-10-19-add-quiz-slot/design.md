## Context

See proposal.md for why. The relevant current state:

- `SessionState` holds language, level, position and phase. `currentCharacter` is the item at the position, and the orchestrator, the overlay and its screen-reader summary all read it.
- `TeachingOrchestrator._onNavigate` treats every navigation as a plain `SessionNotifier` transition. It compares the state before and after to spot a boundary no-op, then restarts the loop with `spellWord: true`. `_handleFeedback` resumes the loop on the same item.
- The language is saved by `LanguagePreferenceStore` (a `SharedPreferences` implementation and an in-memory fallback), loaded in `main` before `runApp` and injected with a provider override. Nothing else is saved.
- The gesture classifier, vibration service and shake detector need no change: the quiz uses existing gestures and plays through `playMorsePattern`.

## Goals / Non-Goals

**Goals:**
- Put the quiz into the session model, so navigation, the overlay and the summary see it without special cases spread across the code.
- Keep the orchestrator's navigation handling as it is: entering, skipping and leaving the quiz are session transitions like any other.
- Make learned items observable (the overlay's count updates at once) and readable synchronously on hot paths (drawing a quiz item, building the overlay).

**Non-Goals:**
- A general settings or persistence layer. The language store stays as it is; learned items get their own store beside it.
- Any change to the gesture classifier, the vibration service or the success and error signals.

## Decisions

### 1. The quiz is a nullable quiz item in `SessionState`

`SessionState` gains `quizItem` (`String?`). The session is in the quiz when it is non-null (`isInQuiz`). `positionIndex` stays on the last item, and `currentCharacter` returns `quizItem ?? characters[positionIndex]`. The loop, answer checking and the wrong-answer replay all read `currentCharacter`, so they work in the quiz unchanged. Leaving the quiz to the left is just clearing `quizItem`. `copyWith` cannot set a nullable field back to null, so leaving the quiz needs an explicit way to clear it (a `leaveQuiz` flag or a dedicated constructor path).

Alternatives:
- *A sentinel position (`positionIndex == characters.length`).* Rejected: every `characters[positionIndex]` read, the overlay's `n/total` and the boundary checks would each need a guard.
- *A quiz flag held by the orchestrator.* Rejected: the overlay and the summary need it too, and they read the session.

### 2. `SessionNotifier` draws quiz items through an injected `QuizItemPicker`

`nextPosition()` enters the quiz on the last item and draws a new item when already in it. `previousPosition()` in the quiz clears `quizItem`. `reset`, `nextLevel`/`previousLevel` (when they move), `home` and `selectLanguage` build states without a quiz item. A new `nextQuizItem()` is used after a correct quiz answer.

`QuizItemPicker.pick(language, level, {previous})` builds the pool from the learned items of the level, in level order. If fewer than two are learned, the pool is the whole level. It removes `previous` and picks with an injected `Random`. It reads learned items when it picks, so an item learned a moment ago counts at once. Every level has at least two items and `previous` is never the only item left, so the pool is never empty.

The picker is a constructor dependency of `SessionNotifier`, defaulting to the whole level with `Random()`, and is wired in `sessionNotifierProvider` from `learnedItemsProvider` and a `quizRandomProvider` that tests override with a seeded `Random`.

Alternative: *the orchestrator draws the item and calls `enterQuiz(item)`.* Rejected: `_onNavigate` would need quiz cases for swipe right, and its "did the state change" boundary check would no longer be the whole story.

### 3. Learned items: a store plus a notifier

- **`LearnedItemsStore`** (`settings/learned_items.dart`): interface, `SharedPreferences` implementation and in-memory fallback, the same shape as `LanguagePreferenceStore`. It reads and writes one string list per language and level, key `learned_items.<language.name>.<level.name>`. A value of another type reads as empty. `loadLearnedItemsStore()` runs in `main` next to `loadLanguagePreferenceStore()` (`SharedPreferences.getInstance()` is a cached singleton) and overrides `learnedItemsStoreProvider`.
- **`LearnedItemsNotifier`** (`StateNotifier<LearnedItems>`): on creation it reads every level of every language from the registry (9 short lists) and drops items that are not in their level. `add(language, level, item)` does nothing for an item already learned. Otherwise it updates the state, so the overlay re-renders, and writes the level's whole list, unawaited. A failed write is logged, never thrown. `LearnedItems` is an immutable value with `of(language, level)`.

Level names (`digits`, `russian-letters`, `words`, …) become storage keys. A future rename of a level must migrate its key, which the store's doc comment says.

Alternative: *the overlay reads the store on every build.* Rejected: nothing would rebuild the overlay when an item is learned.

### 4. The orchestrator records learned items when it checks an answer

In `_onInputComplete`, a correct answer outside the quiz calls `learnedItems.add(language, currentLevel, currentCharacter)` before the feedback starts, so a swipe during the success signal cannot lose it. The orchestrator gets the notifier as a new constructor dependency through `teachingOrchestratorProvider`.

### 5. Loop changes: the `?` marker, no spelling, a new item after success

- `_runLoop({spellWord, announceQuiz})`. In the quiz it never spells. With `announceQuiz` it first plays `questionMarkPattern`, then `_pause(config.quizMarkerGap)`. Both are interruptible exactly like the spelling: a tap ends them and the app listens, and the answer is checked against the quiz item.
- `start()` passes `announceQuiz: true`, which only has an effect in the quiz. `_onNavigate` passes `announceQuiz: !before.isInQuiz && after.isInQuiz`, so entering announces, while a skip or a restart in place does not.
- `_handleFeedback` learns whether the answer was correct. After the post-feedback pause, a correct answer in the quiz calls `sessionNotifier.nextQuizItem()` before resuming the loop (no marker). A wrong answer resumes on the same item, as in the lessons.
- `TeachingTimingConfig.quizMarkerGap`, default 1000 ms: the same value as `spellingLetterGap`, kept separate because the two mean different things.

### 6. The marker is Morse `?` defined in the Morse data

`questionMarkPattern = [dot, dot, dash, dash, dot, dot]` lives in `morse/` (e.g. `morse_punctuation.dart`, exported from `morse.dart`). It is not part of any level. Playing it through `playMorsePattern` means it follows `MorseTimingConfig` and the existing Android and iOS paths, including the fixed-buzz fallback on iPhones without Core Haptics.

### 7. Overlay and summary

`hideItem = session.isInQuiz && session.phase != SessionPhase.feedback`. When it is set, the centre shows `?` and the pattern line is empty. The top-right shows `QUIZ` instead of `n/total`, and a new line below it shows `learned N/total`, from `learnedItemsProvider`, in the lessons and the quiz. `companionOverlaySummary` gains `isQuiz`, `hideItem` and `learnedCount`. The touch surface's semantics hint adds that swiping right past the last item opens the quiz.

### Vibration sequences

| Moment | Vibration | Duration (default timing) |
|---|---|---|
| Entering the quiz / lessons starting in it | `?` `··−−··` | 4×100 + 2×300 + 5×100 (gaps) = 1500 ms |
| After the marker | silence (`quizMarkerGap`) | 1000 ms |
| Quiz item | its Morse pattern, then silence (`repeatPause`) | pattern + 3000 ms, repeating |
| Correct answer | success signal, silence (`postFeedbackPause`), new item | 410 ms (490 ms duration-only) + 500 ms |
| Wrong answer | error signal, silence, same item | 500 ms (700 ms duration-only) + 500 ms |

```
swipe right on "9":
  ··−−··  ...1 s...  ····−  ...3 s...  ····−  ...
  (?)                (4)               (4)
user taps ····− , 1 s of silence:
  ·····  ...0.5 s...  −−···  ...3 s...  −−···  ...
  (correct)           (7, a new item, no marker)
```

## Risks / Trade-offs

- [Over-swiping right on the last item lands in the quiz] → `?` says so at once. One swipe left returns to the last item, and hold and shake still re-anchor.
- [The habit "swipe right to the wall to reach the last item" changes] → the wall is now the quiz, one step further. The README's gestures table and screen map explain it.
- [With two learned items the quiz alternates A, B, A, B] → a consequence of "no immediate repeat". It goes away as more items are learned.
- [Echo proves the item was felt, not named] → known and accepted for now. Answering with the next letter is a non-goal for later.
- [During feedback after a wrong answer, a user with residual sight can read the item before trying again] → accepted. It is a coaching moment, like the lesson replaying the item.
- [A future level rename orphans its stored list] → documented on the store. A rename must migrate the key.
- [Existing tests assert the clamp at the last item] → session, orchestrator and integration tests that swipe past the last item are updated to expect the quiz (see tasks).

## Migration Plan

No migration. Learned items use new keys, so existing installs start with none. Rolling back to an older version leaves the keys unread.
