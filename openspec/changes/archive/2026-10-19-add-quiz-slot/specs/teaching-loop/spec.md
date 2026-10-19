## MODIFIED Requirements

### Requirement: Correct answer plays success vibration and resumes loop

On a correct answer, the orchestrator SHALL transition the session phase to `feedback`, play the success vibration signal, then transition back to `playing` and resume the repeat loop: on the same item in the lessons, and on a new quiz item in the quiz (see `quiz`).

#### Scenario: Correct answer feedback sequence

- **WHEN** the user's input matches the current letter
- **THEN** the session phase transitions to `feedback`
- **AND** the vibration service plays the success signal (3 quick pulses)
- **AND** after the success signal completes, the session phase transitions to `playing`
- **AND** the repeat loop resumes from the beginning of a cycle

#### Scenario: Correct answer in the quiz

- **WHEN** the session is in the quiz with quiz item "K" and the user's input matches it
- **THEN** the vibration service plays the success signal
- **AND** after the post-feedback pause the session has a new quiz item other than "K"
- **AND** the repeat loop resumes with the new quiz item, without the `?` marker

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
