## ADDED Requirements

### Requirement: A swipe past the first or last item or level
A swipe that cannot move the session (previous on the first item, level down on the first level, level up on the last level) SHALL NOT interrupt anything that resumes the loop by itself. While the item plays it SHALL keep repeating, with no cancel. During feedback the feedback SHALL finish and resume the loop as usual. While listening, the classifier has already discarded the pending input for the swipe, so the loop SHALL restart on the same item.

#### Scenario: Swipe left on the first item while it plays
- **WHEN** the loop plays digit "0" and the user swipes left
- **THEN** no vibration SHALL be cancelled
- **AND** "0" SHALL keep repeating after each repeat pause, as before

#### Scenario: Swipe down on the first level during feedback
- **WHEN** the success signal for digit "0" plays and the user swipes down
- **THEN** the success signal SHALL NOT be cancelled
- **AND** after the post-feedback pause the loop SHALL resume on "0"

#### Scenario: Swipe left on the first item while listening
- **WHEN** the user has tapped a dot on digit "0" and swipes left
- **THEN** the dot SHALL be discarded without being checked
- **AND** the loop SHALL restart on "0" in the `playing` phase

#### Scenario: Swipe up on the last level while it plays
- **WHEN** the loop plays a word of the last level and the user swipes up
- **THEN** the word SHALL keep repeating, with no cancel

### Requirement: Input is discarded when the loop starts over
Whenever the loop starts over, on `start()`, on a navigation and on the resume after feedback, the orchestrator SHALL discard the input the classifier has buffered, without checking it. Taps made while the loop was stopped, or ignored during feedback, SHALL never become the start of the next answer. A shake (`Home`) SHALL discard it too, although the shake detector, not the classifier, emits it.

#### Scenario: Taps during feedback
- **WHEN** the user taps a dot while the success or error signal plays
- **THEN** the loop SHALL resume after the feedback with an empty input buffer
- **AND** that dot SHALL NOT be part of the next answer

#### Scenario: Shake with a half-entered answer
- **WHEN** the user has tapped a dot and shakes the phone before the answer is checked
- **THEN** the dot SHALL be discarded without being checked
- **AND** the loop SHALL restart on digit "0"

#### Scenario: Taps while stopped
- **WHEN** the classifier buffered taps while the loop was stopped and `start()` is called
- **THEN** the loop SHALL start with an empty input buffer

## MODIFIED Requirements

### Requirement: Correct answer plays success vibration and resumes loop

On a correct answer, the orchestrator SHALL transition the session phase to `feedback`, play the success vibration signal, wait the post-feedback pause (500 ms by default), then transition back to `playing` and resume the repeat loop: on the same item in the lessons, and on a new quiz item in the quiz (see `quiz`). The resumed loop SHALL NOT spell a word again.

#### Scenario: Correct answer feedback sequence

- **WHEN** the user's input matches the current letter
- **THEN** the session phase transitions to `feedback`
- **AND** the vibration service plays the success signal (five quick taps, see `vibration-engine`)
- **AND** after the success signal completes and the post-feedback pause has passed, the session phase transitions to `playing`
- **AND** the repeat loop resumes from the beginning of a cycle

#### Scenario: Correct answer in the quiz

- **WHEN** the session is in the quiz with quiz item "K" and the user's input matches it
- **THEN** the vibration service plays the success signal
- **AND** after the post-feedback pause the session has a new quiz item other than "K"
- **AND** the repeat loop resumes with the new quiz item, without the `?` marker

### Requirement: Wrong answer plays error vibration, replays pattern, and resumes loop

On a wrong answer, the orchestrator SHALL transition the session phase to `feedback`, play the error vibration signal, wait the post-feedback pause (500 ms by default), then transition back to `playing` and resume the repeat loop on the same item. The resumed loop's first playback is the replay of the correct pattern: nothing else is played during the feedback.

#### Scenario: Wrong answer feedback sequence

- **WHEN** the user's input does not match the current letter
- **THEN** the session phase transitions to `feedback`
- **AND** the vibration service plays the error signal (one long buzz, see `vibration-engine`)
- **AND** after the error signal completes and the post-feedback pause has passed, the session phase transitions to `playing`
- **AND** the vibration service plays the current letter's correct Morse pattern, as the first playback of the resumed loop
- **AND** the repeat loop goes on from there

### Requirement: Navigation events update letter and restart loop

The orchestrator SHALL respond to `NavigateNext`, `NavigatePrevious`, and `Reset` gesture events by calling the corresponding method on `SessionNotifier` and restarting the play-wait-repeat loop for the new character. The orchestrator SHALL also respond to `NavigateUp`, `NavigateDown`, and `Home` gesture events by calling the corresponding level navigation method on `SessionNotifier` and restarting the loop for the new level's character.

#### Scenario: NavigateNext advances to next character

- **WHEN** a `NavigateNext` gesture event is received
- **THEN** `sessionNotifier.nextPosition()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the new character

#### Scenario: NavigatePrevious goes to previous character

- **WHEN** a `NavigatePrevious` gesture event is received
- **THEN** `sessionNotifier.previousPosition()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the new character

#### Scenario: Reset returns to first character in current level

- **WHEN** a `Reset` gesture event is received
- **THEN** `sessionNotifier.reset()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the first character in the current level

#### Scenario: NavigateUp moves to next level

- **WHEN** a `NavigateUp` gesture event is received
- **THEN** `sessionNotifier.nextLevel()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the first character of the new level

#### Scenario: NavigateDown moves to previous level

- **WHEN** a `NavigateDown` gesture event is received
- **THEN** `sessionNotifier.previousLevel()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the first character of the new level

#### Scenario: Home resets to first level, first character

- **WHEN** a `Home` gesture event is received
- **THEN** `sessionNotifier.home()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for digit "0"

#### Scenario: Navigation during feedback interrupts feedback

- **WHEN** the session phase is `feedback` (success or error vibration playing)
- **AND** a navigation event is received that moves the session, or a `Reset` or `Home`
- **THEN** the feedback vibration is cancelled
- **AND** the orchestrator navigates and restarts the loop

#### Scenario: Swipe that cannot move the session

- **WHEN** a swipe arrives that cannot move the session (previous on the first item, level down on the first level, level up on the last level)
- **THEN** it SHALL be handled as in *A swipe past the first or last item or level*

### Requirement: Gesture events are ignored when not applicable

The orchestrator SHALL ignore `MorseInput`, `InputComplete` and `BottomZoneAction` events when the session phase is `feedback`. Navigation events (`NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, `Home`) SHALL be processed in any phase. While the loop is stopped (before `start()`, after `stop()` and after dispose) every event SHALL be ignored. `ChangeLanguage` SHALL never change the session: the lesson surface acts on it (see `touch-surface`).

#### Scenario: Taps during feedback are ignored

- **WHEN** the session phase is `feedback`
- **AND** a `MorseInput` or `InputComplete` event is received
- **THEN** the event is discarded with no effect

#### Scenario: Navigation works during any phase

- **WHEN** the session phase is `playing`, `listening`, or `feedback`
- **AND** a `NavigateUp` event is received
- **THEN** the navigation is processed normally

#### Scenario: Events while the loop is stopped

- **WHEN** the loop is stopped, for example while the app is in the background
- **AND** a swipe, a reset, a shake (`Home`) or an `InputComplete` arrives
- **THEN** the session SHALL NOT change, nothing SHALL vibrate and the loop SHALL stay stopped

#### Scenario: ChangeLanguage leaves the session alone

- **WHEN** the loop is running and a `ChangeLanguage` event arrives
- **THEN** the orchestrator SHALL NOT change the session or restart the loop

### Requirement: Orchestrator can be started and stopped

The orchestrator SHALL provide `start()` and `stop()` methods. `start()` begins the play-wait-repeat loop for the current item in the `playing` phase and resumes shake detection. `stop()` cancels any running loop, pause and vibration, discards a half-entered pattern without checking it, and pauses shake detection. Each SHALL do nothing when the loop is already started or stopped. The orchestrator SHALL not auto-start on creation — it waits for an explicit `start()` call.

#### Scenario: Start begins the loop

- **WHEN** `start()` is called on the orchestrator
- **THEN** the play-wait-repeat loop begins for the current letter

#### Scenario: Stop halts the loop

- **WHEN** `stop()` is called while the loop is running
- **THEN** vibration is cancelled
- **AND** the loop stops
- **AND** no further vibrations occur until `start()` is called again

#### Scenario: Orchestrator does not auto-start

- **WHEN** the orchestrator is created via its provider
- **THEN** no vibration occurs until `start()` is explicitly called

#### Scenario: Stop discards a half-entered pattern

- **WHEN** the user has tapped a dot and `stop()` is called before the answer is checked
- **THEN** the dot SHALL be discarded, and no success or error signal SHALL play, then or after a later `start()`

#### Scenario: Stop and start pause and resume shake detection

- **WHEN** `stop()` is called
- **THEN** shake detection SHALL be paused (see `shake-gesture`)
- **AND** a later `start()` SHALL resume it

#### Scenario: Start after a stop during feedback

- **WHEN** the loop was stopped while a success or error signal played, and `start()` is called
- **THEN** the session phase SHALL be `playing` and the loop SHALL play the current item

## REMOVED Requirements

### Requirement: Gesture classifier emits charGap symbols for inter-character silence
**Reason**: The classifier never inserts a letter gap on its own. A gap is entered with a bottom-strip tap on a words level (see `bottom-input-zone`), and `gesture-recognition` requires that `GestureTimingConfig` has no `charGapThreshold`.
**Migration**: None in code. Letter gaps are in *Level-aware behavior in teaching orchestrator* (`bottom-input-zone`).

### Requirement: Configurable charGap threshold
**Reason**: `GestureTimingConfig` has no `charGapThreshold`, as `gesture-recognition` requires: letter gaps are entered with the bottom strip, not timed.
**Migration**: None in code. See *Configurable gesture timing thresholds* in `gesture-recognition`.
