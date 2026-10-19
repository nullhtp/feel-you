# Tasks

## 1. Morse marker and timing

- [x] 1.1 Add `questionMarkPattern` (`[dot, dot, dash, dash, dot, dot]`) in `app/lib/morse/morse_punctuation.dart`, exported from `morse.dart`, with a doc comment saying it marks the quiz and is not part of any level; verify with a test in `test/morse/` that it has 6 elements and that every digit and letter of every language has at most 5
- [x] 1.2 Add `TeachingTimingConfig.quizMarkerGap` (default 1000 ms) with its doc comment; verify in `test/teaching/teaching_timing_config_test.dart` (default and override)

## 2. Learned items

- [x] 2.1 Add `app/lib/settings/learned_items.dart` with the `LearnedItemsStore` interface, a `SharedPreferences` implementation (string list per key `learned_items.<language>.<level name>`, a non-list value reads as empty, failed writes logged and never thrown), an in-memory fallback, `loadLearnedItemsStore()` and `learnedItemsStoreProvider`, mirroring `language_preference.dart` and documenting that a level rename must migrate its key. Android (`SharedPreferences` XML) and iOS (`NSUserDefaults`) both store string lists, so no platform branch. Verify with `test/settings/learned_items_store_test.dart` using `SharedPreferences.setMockInitialValues`: round trip, corrupt value, separate keys per language and level
- [x] 2.2 Add the immutable `LearnedItems` value (`of(language, level)`), `LearnedItemsNotifier` and `learnedItemsProvider`: load every level of every language from the registry on creation and drop items not in their level; `add()` is a no-op for a learned item, otherwise it updates the state and writes the level's list unawaited. Verify with notifier tests: unknown stored items dropped, digits separate per language, `add` updates state and the store, a second `add` of the same item writes nothing
- [x] 2.3 Load the learned-items store in `app/lib/main.dart` before `runApp` and override `learnedItemsStoreProvider`; verify with a launch test that items present in mock preferences are learned after launch and that the session still opens at the digits level on 0
- [x] 2.4 Update the README sentences that say only the language is saved ("Languages and levels", "Design Principles: Almost no state"), the "Data Storage" section of `store/privacy-policy.md` and the `context` in `openspec/config.yaml` to say the language and the learned items are saved, level and position are not; verify `grep -rn "only the language\|Only the chosen language\|only part of the session" README.md openspec/config.yaml` finds nothing stale

## 3. Session: the quiz slot

- [x] 3.1 Add `quizItem` and `isInQuiz` to `SessionState`, make `currentCharacter` return the quiz item in the quiz, add an explicit way to leave the quiz (`copyWith` cannot null a field), and include `quizItem` in `props` and `toString`; verify in `test/session/session_state_test.dart` (current character in the quiz, position stays on the last item, equality with and without a quiz item)
- [x] 3.2 Add `QuizItemPicker` (pool = learned items of the level in level order, or the whole level when fewer than two are learned; `previous` excluded; injected `Random`) and `quizRandomProvider`; verify with tests using a seeded `Random`: draws only learned items, falls back to the whole level, never repeats the previous item over many draws, counts an item learned after the quiz was entered
- [x] 3.3 Implement the transitions in `SessionNotifier`: `nextPosition` enters the quiz on the last item and draws a new item in it; `previousPosition` leaves to the last item; `reset`, level moves, `home` and `selectLanguage` leave the quiz; a level no-op keeps the quiz item; new `nextQuizItem()`. Wire the picker into `sessionNotifierProvider` from `learnedItemsProvider` and `quizRandomProvider`. Verify with notifier tests for every scenario in the `learning-session` delta, and update the tests that expected a clamp at the last item (`session_notifier_test.dart`, `session_edge_cases_test.dart`, `session_registry_test.dart`); `flutter test test/session` passes
- [x] 3.4 Update the README's gestures table and its details (swipe right on the last item opens the quiz, swipe right in the quiz draws another item, swipe left leaves it; the "stops at the first and last item" wording) and the screen description; verify the README describes entering and leaving the quiz and no longer says swipe right stops at the last item

## 4. Teaching loop in the quiz

- [x] 4.1 Record learned items in `_onInputComplete`: a correct answer outside the quiz calls `LearnedItemsNotifier.add` before the feedback starts; add the notifier as an orchestrator dependency and wire it in `teachingOrchestratorProvider`. Verify with orchestrator tests: a correct lesson answer adds the item, a wrong one does not, a correct quiz answer does not, a swipe during the success signal keeps the item learned
- [x] 4.2 Extend `_runLoop` with `announceQuiz`: in the quiz never spell; with `announceQuiz` play `questionMarkPattern`, pause `quizMarkerGap` (interruptible like the spelling), then the item. `start()` passes it; `_onNavigate` passes it only when the session moved into the quiz from outside. Verify with `MockVibrationService` tests: entering plays `?`, then the item after the gap; `start()` in the quiz plays `?`; a skip and a restart in place (listening, swipe up on the last level) play no `?`; a tap during `?` or its gap moves to listening and the answer is checked against the quiz item; a quiz word plays its token pattern without spelling
- [x] 4.3 Make `_handleFeedback` aware of a correct answer: in the quiz, after the post-feedback pause call `sessionNotifier.nextQuizItem()` and resume without `?`; a wrong answer resumes on the same item. Verify with tests asserting vibration calls in order: success signal, then a different item; error signal, then the same item; a swipe right during the success signal cancels it and plays a new item
- [x] 4.4 Update the orchestrator tests that swiped past the last item expecting a clamp (`teaching_orchestrator_boundary_test.dart`; the "restarting on the same word" case in `teaching_orchestrator_spelling_test.dart` now uses `NavigateUp` on the last level; any others `flutter test` reports); verify `flutter test test/teaching` passes
- [x] 4.5 Document the quiz in the README: a quiz section in "How It Works" (entering, the `?` marker, the echo answer, a new item after a correct answer, where the items come from), the `?` row in the signals table with its 1500 ms + 1 s timing, and a CHANGELOG "Unreleased → Added" entry; verify the README timings match `MorseTimingConfig` and `TeachingTimingConfig`

## 5. Companion overlay and screen reader

- [x] 5.1 Update `CompanionOverlay`: while in the quiz and not in feedback show `?` and no pattern; show `QUIZ` instead of `n/total`; add a `learned N/total` line below the position from `learnedItemsProvider`. Verify with widget tests in `test/ui/companion_overlay_test.dart`: item and pattern hidden while playing and listening, shown during feedback, `QUIZ` shown, the count rises after a correct lesson answer
- [x] 5.2 Extend `companionOverlaySummary` with the quiz (`quiz` in place of the position, no item or pattern unless in feedback) and the learned count, and add the quiz to the touch surface's semantics hint; verify in `test/ui/semantics_test.dart`: summary while playing in the quiz omits the item, during feedback names it, always has the learned count
- [x] 5.3 Update the README's "For Sighted Helpers" section (`QUIZ`, the hidden item, `learned N/total`, the spoken summary); verify it matches what the overlay draws

## 6. Integration and device checks

- [x] 6.1 Add an integration test of learn → quiz: answer two letters correctly, swipe right to the end, feel `?`, echo the quiz item, get success and a different learned letter; update `integration_test/edge_cases_test.dart` and `integration_test/level_navigation_test.dart` where they relied on the clamp at the last item. Verify `flutter test integration_test` passes on an Android emulator and on the iOS simulator
- [ ] 6.2 Check on real devices, an Android phone (with amplitude control, and one without if available) and an iPhone with Core Haptics: `?` feels distinct from every item and from the success and error signals, the 1 s gap separates it from the first quiz item, the success signal followed by 0.5 s and a new item is readable, and learned items survive force-quitting the app. Write the results in the pull request
- [x] 6.3 Run `dart format --set-exit-if-changed .`, `flutter analyze` and `flutter test` in `app/`, and `openspec validate add-quiz-slot --strict`; verify all pass
- [x] 6.4 Add the quiz to the ROADMAP's "After Phase 1" list; verify it names the change `add-quiz-slot`

## Workflow follow-up

- Archive the change with `/opsx:archive` after review, then run `openspec validate --specs --strict` to confirm all main specs still pass.
- Next change from the same exploration: `add-status-row` (time, date and battery as digits below the digits level).
