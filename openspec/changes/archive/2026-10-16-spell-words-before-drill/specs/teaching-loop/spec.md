## ADDED Requirements

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

The loop SHALL spell the current word on `start()` and on every navigation that restarts the loop, including a restart for the same word. It SHALL NOT spell the word when it resumes after feedback.

#### Scenario: Navigating to a word spells it

- **WHEN** a `NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown` or `Home` event moves the session onto a word
- **THEN** the restarted loop spells that word before drilling it

#### Scenario: Restarting on the same word spells it again

- **WHEN** the session phase is `listening` on the last word
- **AND** a `NavigateNext` event is received
- **THEN** the loop restarts for the same word and spells it first

#### Scenario: No spelling after feedback

- **WHEN** the success or error feedback for a word has played
- **THEN** the loop resumes with the word's token pattern
- **AND** the word is not spelled again

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

## MODIFIED Requirements

### Requirement: Configurable teaching loop timing

The orchestrator SHALL use a `TeachingTimingConfig` configuration object with a `repeatPause` duration (default: 3000ms), a `postFeedbackPause` duration (default: 500ms) and a `spellingLetterGap` duration (default: 1000ms). The `spellingLetterGap` SHALL be longer than the gap between the letters of a drilled word (300ms) and shorter than the `repeatPause`. The config SHALL be overridable via a Riverpod provider.

#### Scenario: Default repeat pause

- **WHEN** a `TeachingTimingConfig` is created with no arguments
- **THEN** the repeat pause is 3000ms

#### Scenario: Custom repeat pause

- **WHEN** a `TeachingTimingConfig` is created with `repeatPause: Duration(milliseconds: 5000)`
- **THEN** the repeat pause is 5000ms

#### Scenario: Default spelling letter gap

- **WHEN** a `TeachingTimingConfig` is created with no arguments
- **THEN** the spelling letter gap is 1000ms
