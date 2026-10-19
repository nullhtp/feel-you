# teaching-loop Specification

## Purpose

The teaching loop connects gesture input, vibration output and the learning session: it plays the current item, waits and repeats it, listens to the user's answer, gives feedback, and follows navigation.

## Requirements

### Requirement: Play-wait-repeat loop vibrates current letter continuously

The orchestrator SHALL continuously vibrate the current character's Morse pattern followed by a configurable pause (default: 3000ms), repeating indefinitely until the user provides input or navigates. The pattern SHALL be the current character from the session state, encoded with the session language's codec.

#### Scenario: Loop starts on orchestrator activation

- **WHEN** the orchestrator is started and the session phase is `playing`
- **THEN** the vibration engine plays the current character's Morse pattern
- **AND** after the pattern completes, waits 3000ms
- **AND** replays the pattern, repeating this cycle indefinitely

#### Scenario: Loop uses correct pattern for current character

- **WHEN** the current level is digits and position is 0 (character "0", pattern dash-dash-dash-dash-dash)
- **THEN** the orchestrator plays `[dash, dash, dash, dash, dash]` (five long pulses) via the vibration service on each repetition

#### Scenario: Loop uses letter pattern when on letters level

- **WHEN** the current level is letters and position is 0 (character "A", pattern dot-dash)
- **THEN** the orchestrator plays `[dot, dash]` (a short and a long pulse) via the vibration service on each repetition

### Requirement: Interrupt playback when user starts tapping

The orchestrator SHALL stop ongoing vibration playback when the first `MorseInput` event is received during the `playing` phase. The session phase SHALL transition to `listening` and the repeat loop SHALL pause until input evaluation completes.

#### Scenario: First tap interrupts playback

- **WHEN** the orchestrator is playing the current letter's pattern
- **AND** the user taps (producing a `MorseInput` event)
- **THEN** the vibration service `cancel()` is called
- **AND** the session phase transitions to `listening`
- **AND** the repeat loop stops

#### Scenario: Subsequent taps during listening do not trigger additional interrupts

- **WHEN** the session phase is already `listening`
- **AND** the user continues tapping (additional `MorseInput` events)
- **THEN** no additional `cancel()` calls are made
- **AND** the orchestrator waits for `InputComplete`

### Requirement: Evaluate user input on InputComplete

The orchestrator SHALL compare the user's input pattern (from `InputComplete`) against the current character's (or word's) expected Morse pattern using `patternsEqual`. The input pattern MAY include `charGap` symbols when the user pauses between letters within a word. The result determines the feedback path.

#### Scenario: Correct input matches current letter

- **WHEN** the current character is "S" (dot-dot-dot)
- **AND** the user taps `[dot, dot, dot]` and `InputComplete` fires
- **THEN** `patternsEqual` returns true
- **AND** the orchestrator enters the correct-answer feedback path

#### Scenario: Incorrect input does not match

- **WHEN** the current character is "S" (dot-dot-dot)
- **AND** the user taps `[dot, dash]` and `InputComplete` fires
- **THEN** `patternsEqual` returns false
- **AND** the orchestrator enters the wrong-answer feedback path

#### Scenario: Empty input is treated as incorrect

- **WHEN** `InputComplete` fires with an empty symbol list
- **THEN** the orchestrator enters the wrong-answer feedback path

#### Scenario: Correct word input with charGaps

- **WHEN** the current word is "IT" with pattern `[dot, dot, charGap, dash]`
- **AND** the user taps `[dot, dot, charGap, dash]` and `InputComplete` fires
- **THEN** `patternsEqual` returns true
- **AND** the orchestrator enters the correct-answer feedback path

#### Scenario: Word input missing charGap is incorrect

- **WHEN** the current word is "IT" with pattern `[dot, dot, charGap, dash]`
- **AND** the user taps `[dot, dot, dash]` (no charGap) and `InputComplete` fires
- **THEN** `patternsEqual` returns false
- **AND** the orchestrator enters the wrong-answer feedback path

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

### Requirement: Configurable teaching loop timing

The orchestrator SHALL use a `TeachingTimingConfig` configuration object with a `repeatPause` duration (default: 3000ms), a `postFeedbackPause` duration (default: 500ms), a `spellingLetterGap` duration (default: 1000ms) and a `quizMarkerGap` duration (default: 1000ms). The `spellingLetterGap` SHALL be longer than the gap between the letters of a drilled word (300ms) and shorter than the `repeatPause`. The config SHALL be overridable via a Riverpod provider.

#### Scenario: Default repeat pause

- **WHEN** a `TeachingTimingConfig` is created with no arguments
- **THEN** the repeat pause is 3000ms

#### Scenario: Custom repeat pause

- **WHEN** a `TeachingTimingConfig` is created with `repeatPause: Duration(milliseconds: 5000)`
- **THEN** the repeat pause is 5000ms

#### Scenario: Default spelling letter gap

- **WHEN** a `TeachingTimingConfig` is created with no arguments
- **THEN** the spelling letter gap is 1000ms

#### Scenario: Default quiz marker gap

- **WHEN** a `TeachingTimingConfig` is created with no arguments
- **THEN** the quiz marker gap, the silence between the `?` marker and the first quiz item, is 1000ms

### Requirement: Orchestrator is exposed via Riverpod provider

The teaching loop orchestrator SHALL be exposed as a `StateNotifierProvider`. It SHALL depend on the gesture classifier, vibration service, and session notifier providers. It SHALL clean up stream subscriptions and cancel any running loops on dispose.

#### Scenario: Provider creates orchestrator with dependencies

- **WHEN** the orchestrator provider is read
- **THEN** it receives the gesture classifier, vibration service, and session notifier from their respective providers

#### Scenario: Provider cleans up on dispose

- **WHEN** the orchestrator provider is disposed
- **THEN** the gesture stream subscription is cancelled
- **AND** any running vibration is cancelled
- **AND** the repeat loop is stopped

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

### Requirement: Orchestrator subscribes to both touch and shake event streams

The orchestrator SHALL subscribe to both the `GestureClassifier.events` stream (touch gestures) and the `ShakeDetector.events` stream (shake gestures). Events from both streams SHALL be handled identically through the same event processing logic.

#### Scenario: Touch gesture events are processed

- **WHEN** the `GestureClassifier` emits a `NavigateNext` event
- **THEN** the orchestrator processes it as a navigation event

#### Scenario: Shake gesture events are processed

- **WHEN** the `ShakeDetector` emits a `Home` event
- **THEN** the orchestrator processes it as a home navigation event

#### Scenario: Both subscriptions are cleaned up on dispose

- **WHEN** the orchestrator is disposed
- **THEN** both the touch gesture subscription and the shake gesture subscription SHALL be cancelled

### Requirement: Character pattern resolution uses level system

The orchestrator SHALL resolve the current item through the level system (via `SessionState.currentLevel` and position, or the quiz item) rather than directly from `morseLetters`, and SHALL obtain what it plays by encoding that item, a letter of a spelled word, or the quiz marker `?` with the session language's codec. Answers SHALL still be checked against the level's patterns.

#### Scenario: Pattern resolved from digits level

- **WHEN** the current level is digits and position is 5
- **THEN** the orchestrator encodes "5" with the session language's codec
- **AND** plays five short pulses

#### Scenario: Pattern resolved from letters level

- **WHEN** the current level is letters and position is 0
- **THEN** the orchestrator encodes "A" with the session language's codec
- **AND** plays a short and a long pulse

#### Scenario: Word encoded with letter gaps

- **WHEN** the current level is the English words level and the word "HI" is drilled
- **THEN** the orchestrator plays four short pulses, a character gap and two short pulses

#### Scenario: Spelling splits the encoded word

- **WHEN** the orchestrator spells the word "HI"
- **THEN** it plays the tokens of the encoded word up to its first character gap ("H"), then the tokens after it ("I"), each on its own

#### Scenario: Quiz marker encoded as question mark

- **WHEN** the loop announces the quiz
- **THEN** it plays the session language's codec encoding of "?"

#### Scenario: Playback follows the codec

- **WHEN** the codec of the session language is replaced, for example by a test codec
- **THEN** the orchestrator plays exactly the tokens that codec returns for the current item
- **AND** it still checks the user's answer against the level's Morse pattern

### Requirement: Words are spelled before they are drilled

When the play-wait-repeat loop spells a word, the orchestrator SHALL play each letter's Morse pattern on its own, in order, with `spellingLetterGap` of silence between letters. The spelling SHALL replace the loop's first playback: the repeat pause and then the word's token pattern SHALL follow, repeating as before. On a characters level the loop SHALL NOT spell.

#### Scenario: Starting on a word spells it first

- **WHEN** the orchestrator is started on the English words level at "HI"
- **THEN** the vibration service plays H (`[dot, dot, dot, dot]`)
- **AND** after `spellingLetterGap` it plays I (`[dot, dot]`)
- **AND** after the repeat pause it plays the token pattern of "HI"
- **AND** the token pattern then repeats after each repeat pause

#### Scenario: Characters are not spelled

- **WHEN** the orchestrator is started on the letters level at "A"
- **THEN** it plays `[dot, dash]` and repeats it, as before

### Requirement: A word is spelled whenever the loop starts on it

The loop SHALL spell the current word on `start()` and on every navigation that restarts the loop, including a restart for the same word. It SHALL NOT spell the word when it resumes after feedback, nor in the quiz.

#### Scenario: Navigating to a word spells it

- **WHEN** a `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown` or `Home` event moves the session onto a word outside the quiz
- **THEN** the restarted loop spells that word before drilling it

#### Scenario: Restarting on the same word spells it again

- **WHEN** the session phase is `listening` on a word of the last level, outside the quiz
- **AND** a `NavigateUp` event is received
- **THEN** the loop restarts for the same word and spells it first

#### Scenario: No spelling after feedback

- **WHEN** the success or error feedback for a word has played
- **THEN** the loop resumes with the word's token pattern
- **AND** the word is not spelled again

#### Scenario: No spelling in the quiz

- **WHEN** the session is in the quiz of a words level and the loop starts or restarts there
- **THEN** the loop plays the quiz word's token pattern
- **AND** the word's letters are not played on their own first

### Requirement: The spelling is interrupted like the word's playback

The spelling SHALL be part of the `playing` phase. The first `MorseInput`, navigation, `stop()` and dispose SHALL end it, and none of its remaining letters SHALL be played. A `BottomZoneAction` SHALL be ignored, as while the word plays.

#### Scenario: Tap during the spelling

- **WHEN** the orchestrator is spelling a word
- **AND** the user taps (producing a `MorseInput` event)
- **THEN** the vibration service `cancel()` is called
- **AND** the session phase transitions to `listening`
- **AND** none of the remaining letters is played

#### Scenario: Navigation during the spelling

- **WHEN** the orchestrator is spelling a word
- **AND** a navigation event moves the session to another word
- **THEN** none of the remaining letters of the first word is played
- **AND** the new word is spelled

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
