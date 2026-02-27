## 1. Vibration Service: Add Cancel Support

- [x] 1.1 Add `Future<void> cancel()` to the `VibrationService` abstract class in `app/lib/vibration/vibration_service.dart`
- [x] 1.2 Implement `cancel()` in `DeviceVibrationService` using `Vibration.cancel()`
- [x] 1.3 Write unit tests for `cancel()`: cancel during no-op, verify mock cancel is callable

## 2. Teaching Timing Config

- [x] 2.1 Create `app/lib/teaching/teaching_timing_config.dart` with `TeachingTimingConfig` class containing `repeatPause` (default: 3000ms Duration)
- [x] 2.2 Write unit tests: default value is 3000ms, custom value accepted

## 3. Teaching Orchestrator Core

- [x] 3.1 Create `app/lib/teaching/teaching_orchestrator.dart` with `TeachingOrchestratorState` (immutable class: `isRunning`, `isInterrupted` booleans) and `TeachingOrchestrator` extending `StateNotifier<TeachingOrchestratorState>`
- [x] 3.2 Constructor accepts `GestureClassifier`, `VibrationService`, `SessionNotifier`, and `TeachingTimingConfig`. Subscribe to gesture classifier's event stream. Store subscription for disposal.
- [x] 3.3 Implement `start()` method: set `isRunning = true`, begin the play-wait-repeat async loop
- [x] 3.4 Implement `stop()` method: cancel ongoing vibration, break the loop, set `isRunning = false`
- [x] 3.5 Implement `dispose()`: cancel stream subscription, call `stop()`, call `super.dispose()`

## 4. Play-Wait-Repeat Loop

- [x] 4.1 Implement the async loop: look up current letter's pattern via `encodeLetter`, call `vibrationService.playMorsePattern()`, wait `repeatPause` duration (using `Future.delayed` with Completer-based cancellation), repeat
- [x] 4.2 Set session phase to `playing` at loop start via `sessionNotifier.setPhase(SessionPhase.playing)`
- [x] 4.3 Handle loop cancellation: completing the Completer breaks the delay early, `isInterrupted` flag prevents next iteration
- [x] 4.4 Write unit tests: loop calls `playMorsePattern` with correct symbols for current letter, loop repeats after pause, loop stops when `stop()` called

## 5. Interrupt Handling

- [x] 5.1 Handle `MorseInput` events during `playing` phase: call `vibrationService.cancel()`, set `isInterrupted = true`, transition session phase to `listening`, complete the delay Completer to break the loop
- [x] 5.2 Ignore `MorseInput` events during `listening` phase (no duplicate cancel calls) and during `feedback` phase
- [x] 5.3 Write unit tests: first tap during playing calls cancel and transitions to listening, subsequent taps during listening are no-ops, taps during feedback are ignored

## 6. Input Evaluation and Feedback

- [x] 6.1 Handle `InputComplete` events during `listening` phase: compare `symbols` against current letter's pattern using `patternsEqual(symbols, encodeLetter(currentLetter))`
- [x] 6.2 Correct answer path: transition to `feedback` phase, call `vibrationService.playSuccess()`, then transition to `playing` and restart the loop
- [x] 6.3 Wrong answer path: transition to `feedback` phase, call `vibrationService.playError()`, then call `vibrationService.playMorsePattern()` with the correct pattern, then transition to `playing` and restart the loop
- [x] 6.4 Handle empty input list as incorrect answer
- [x] 6.5 Ignore `InputComplete` events during `playing` and `feedback` phases
- [x] 6.6 Write unit tests: correct input triggers success + resume, wrong input triggers error + replay + resume, empty input treated as wrong, InputComplete during feedback is ignored

## 7. Navigation Integration

- [x] 7.1 Handle `NavigateNext` events in any phase: cancel ongoing vibration, call `sessionNotifier.nextLetter()`, restart the loop
- [x] 7.2 Handle `NavigatePrevious` events in any phase: cancel ongoing vibration, call `sessionNotifier.previousLetter()`, restart the loop
- [x] 7.3 Handle `Reset` events in any phase: cancel ongoing vibration, call `sessionNotifier.reset()`, restart the loop
- [x] 7.4 Write unit tests: navigation during playing cancels vibration and restarts loop for new letter, navigation during feedback cancels feedback and restarts, navigation during listening cancels and restarts

## 8. Riverpod Providers

- [x] 8.1 Create `app/lib/teaching/teaching_providers.dart` with `teachingTimingConfigProvider` (Provider<TeachingTimingConfig>, default config, overridable)
- [x] 8.2 Create `teachingOrchestratorProvider` (StateNotifierProvider) that watches gesture classifier, vibration service, session notifier, and timing config providers. Register `ref.onDispose` to dispose the orchestrator.
- [x] 8.3 Write unit tests: provider creates orchestrator with correct dependencies, provider disposes orchestrator on scope disposal

## 9. Verification

- [x] 9.1 Run all existing tests to confirm no regressions (`flutter test` in app/)
- [x] 9.2 Run static analysis (`dart analyze` in app/) and fix any warnings
