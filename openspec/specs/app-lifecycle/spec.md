# app-lifecycle Specification

## Purpose
What the lessons do when the app leaves and returns to the foreground: nothing vibrates in the background, and the user comes back to the start of the item they were on.

## Requirements

### Requirement: Leaving the foreground suspends the lesson
When the app leaves the foreground while the lesson surface is shown, the lesson SHALL be suspended. Every lifecycle state other than resumed counts: inactive, hidden, paused and detached. Suspending SHALL cancel a press in progress, release the wakelock and stop the teaching loop, once per trip away from the foreground. Nothing SHALL vibrate until the app is resumed.

#### Scenario: App sent to the background
- **WHEN** the teaching loop is playing an item and the app goes to the background (inactive, then hidden, then paused)
- **THEN** the vibration in progress and the pause between repetitions SHALL be cancelled
- **AND** the teaching loop SHALL stop
- **AND** the wakelock SHALL be released
- **AND** nothing SHALL vibrate for as long as the app stays in the background

#### Scenario: App inactive only
- **WHEN** the app becomes inactive without being hidden (an incoming call, Control Center, the app switcher)
- **THEN** the lesson SHALL be suspended as in the background

#### Scenario: Suspended once per trip
- **WHEN** the app passes through inactive, hidden and paused on its way to the background
- **THEN** the lesson SHALL be suspended on the first of them only

#### Scenario: Press in progress
- **WHEN** the user's first finger is on the screen as the app leaves the foreground
- **THEN** the press SHALL be cancelled: it SHALL produce no dot, dash, swipe, bottom-strip action or reset, neither in the background nor when the finger is lifted later
- **AND** a long hold that has not reached the reset threshold SHALL NOT emit a reset in the background

#### Scenario: Half-entered answer
- **WHEN** the user has tapped part of an answer and the app leaves the foreground before it is checked
- **THEN** the input SHALL be discarded without being checked
- **AND** no success or error signal SHALL play

#### Scenario: Gestures and shakes while suspended
- **WHEN** a gesture event or a shake arrives while the lesson is suspended
- **THEN** it SHALL be ignored, and shake detection SHALL be paused until the loop starts again

### Requirement: Returning to the foreground restarts the lesson's current item
When the app is resumed after the lesson was suspended, the wakelock SHALL be enabled again and the teaching loop SHALL start again on the same item, from the beginning, in the `playing` phase, with no input. As on any start, a word SHALL be spelled first, and in the quiz `?` SHALL be played first. Language, level, position and quiz item SHALL NOT change. A resume that follows no suspension SHALL do nothing.

#### Scenario: Resume replays the current item
- **WHEN** the app was suspended on letter "K" while listening, with a dot already entered
- **AND** the app is resumed
- **THEN** the session SHALL be on "K" in the `playing` phase, with an empty input buffer
- **AND** the pattern of "K" SHALL be played from its first element
- **AND** it SHALL keep repeating after each repeat pause

#### Scenario: Wakelock enabled again
- **WHEN** the app is resumed after a suspension
- **THEN** the wakelock SHALL be enabled again

#### Scenario: Resume on a word
- **WHEN** the app is resumed on a word outside the quiz
- **THEN** the word SHALL be spelled letter by letter before it is drilled

#### Scenario: Resume after feedback was cut short
- **WHEN** the app was suspended while the success or error signal of an answer played
- **AND** the app is resumed
- **THEN** the feedback SHALL NOT be played again
- **AND** the loop SHALL start on the same item in the `playing` phase, also in the quiz after a correct answer

#### Scenario: Several trips
- **WHEN** the app goes to the background and comes back several times in a row
- **THEN** each return SHALL start the loop exactly once, and the loop SHALL be running after the last one

#### Scenario: Leaving for the menu
- **WHEN** a double shake has stopped the loop and the home menu is replacing the lesson surface
- **AND** the app goes to the background and comes back during the transition
- **THEN** the teaching loop SHALL NOT start again
