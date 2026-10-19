# integration-testing Specification

## Purpose

The end-to-end tests that drive the whole learning flow and its edge cases.

## Requirements

### Requirement: Full learning flow integration test
The system SHALL have an integration test that validates the complete learning flow from app initialization through letter playback, user input, feedback, and navigation. The test SHALL use real Riverpod providers with a mock `VibrationService` that records all vibration calls.

#### Scenario: Happy path — learn letter A with correct input
- **WHEN** the app starts and the teaching orchestrator begins
- **THEN** the mock vibration service SHALL receive a `playMorsePattern` call with the pattern for digit "0" (five dashes), the first item of the first level
- **WHEN** the user moves to the letters level and inputs the correct Morse pattern for "A" (a tap on the left half, then a tap on the right half, then the silence timeout)
- **THEN** the mock vibration service SHALL receive a `playSuccess` call
- **THEN** the orchestrator SHALL resume the play-wait-repeat loop for "A"

#### Scenario: Wrong input triggers error feedback and replay
- **WHEN** the user inputs an incorrect Morse pattern during the listening phase
- **THEN** the mock vibration service SHALL receive a `playError` call
- **THEN** the mock vibration service SHALL receive a `playMorsePattern` call replaying the correct pattern
- **THEN** the orchestrator SHALL resume the play-wait-repeat loop

#### Scenario: Navigate to next letter after correct answer
- **WHEN** the user swipes right (NavigateNext gesture)
- **THEN** the session SHALL advance to the next letter
- **THEN** the orchestrator SHALL begin playing the new letter's Morse pattern

#### Scenario: Navigate backward to previous letter
- **WHEN** the user swipes left (NavigatePrevious gesture)
- **THEN** the session SHALL move to the previous letter
- **THEN** the orchestrator SHALL begin playing the new letter's Morse pattern

#### Scenario: Reset to letter A
- **WHEN** the user performs a long hold (Reset gesture)
- **THEN** the session SHALL reset to letter "A"
- **THEN** the orchestrator SHALL begin playing the pattern for "A"

### Requirement: Multi-letter learning sequence
The system SHALL have an integration test that validates learning multiple consecutive letters in sequence.

#### Scenario: Learn A then navigate to B and learn B
- **WHEN** the user correctly inputs letter "A" and then swipes right
- **THEN** the session SHALL be on letter "B"
- **WHEN** the orchestrator plays "B" and the user inputs the correct pattern
- **THEN** the mock vibration service SHALL receive a `playSuccess` call

### Requirement: Edge case — rapid navigation
The system SHALL have an integration test that validates rapid consecutive navigation gestures do not corrupt state.

#### Scenario: Multiple rapid swipes right
- **WHEN** the user performs three consecutive NavigateNext gestures in rapid succession
- **THEN** the session SHALL be on letter "D" (advanced 3 from A)
- **THEN** the orchestrator SHALL be playing the pattern for "D" (not A, B, or C)

#### Scenario: Rapid swipe right then swipe left
- **WHEN** the user performs NavigateNext followed immediately by NavigatePrevious
- **THEN** the session SHALL return to the original letter
- **THEN** the orchestrator SHALL be playing the pattern for the original letter

### Requirement: Edge case — input during playback
The system SHALL have an integration test that validates user taps during active pattern playback correctly interrupt and transition to listening.

#### Scenario: Tap during pattern playback
- **WHEN** the orchestrator is playing a Morse pattern and the user taps (MorseInput)
- **THEN** the vibration service SHALL receive a `cancel` call (interrupting playback)
- **THEN** the session phase SHALL transition to `listening`

#### Scenario: Double tap during playback
- **WHEN** the orchestrator is playing and the user sends two MorseInput events
- **THEN** only the first tap SHALL trigger the interrupt
- **THEN** the second tap SHALL be accumulated as part of the user's input (dot or dash)

### Requirement: Edge case — navigation during feedback
The system SHALL have an integration test that validates navigation works correctly even during the feedback phase.

#### Scenario: Swipe during success feedback
- **WHEN** the user swipes right while success feedback is playing
- **THEN** the feedback SHALL be cancelled
- **THEN** the session SHALL advance to the next letter
- **THEN** the orchestrator SHALL begin playing the new letter's pattern

### Requirement: Edge case — input at alphabet boundaries
The system SHALL have integration tests that validate the behavior at the first and the last letter: a swipe left on "A" stays on "A", and a swipe right on "Z" enters the letters level's quiz.

#### Scenario: Navigate previous at letter A
- **WHEN** the session is on letter "A" and the user swipes left
- **THEN** the session SHALL remain on letter "A"
- **THEN** the orchestrator SHALL continue playing the pattern for "A"

#### Scenario: Navigate next at letter Z
- **WHEN** the session is on letter "Z" and the user swipes right
- **THEN** the session SHALL be in the quiz of the letters level, with the position still on "Z" and the phase `playing`
- **THEN** the orchestrator SHALL play Morse `?` to announce the quiz

### Requirement: End-to-end tests run the real app on a device
The end-to-end tests below SHALL launch `FeelYouApp` on a device or simulator with its real screens, gesture classifier, teaching loop and plugins, and drive it with pointer events. They SHALL replace only what a simulator cannot provide or a test must fix: the saved language, the timing configs, the vibration output (recorded, or caught at the plugin's platform channel), the motor's answers where a test needs a particular motor, and the accelerometer readings.

#### Scenario: What runs for real
- **WHEN** an end-to-end test runs
- **THEN** the lesson surface, the language picker, the vibration gate, the classifier, the orchestrator, the session and the wakelock plugin SHALL be the app's own

### Requirement: Background suspension end-to-end test
An end-to-end test SHALL send the running app to the background and back and check `app-lifecycle` against the real wakelock plugin: the loop stops, the wakelock is released, a press in progress is cancelled and a half-entered answer is dropped; on resume the wakelock is enabled again and the current item restarts from the beginning.

#### Scenario: Suspend and resume
- **WHEN** the lesson plays digit "0" and the app goes to the background
- **THEN** the loop SHALL be stopped, the wakelock disabled, and nothing SHALL vibrate while it stays there
- **WHEN** the app returns to the foreground
- **THEN** the wakelock SHALL be enabled and the pattern of "0" SHALL be played again from its first element

#### Scenario: Press held across the trip
- **WHEN** a finger goes down on the left half, the app goes to the background for longer than the reset threshold and comes back, and the finger is lifted
- **THEN** no dot and no reset SHALL be produced, and the session SHALL stay on the same item

#### Scenario: Half-entered answer
- **WHEN** the user has tapped a dash and the app goes to the background before the answer is checked
- **THEN** no success or error signal SHALL be played, then or after the resume

### Requirement: Double shake end-to-end test
An end-to-end test SHALL feed the app's shake detector accelerometer readings in real time, with the default `ShakeConfig`, and check the double-shake window: two shakes 0.9 s apart open the language picker, which plays the current language's identifier; two shakes 1.8 s apart only go home twice, and the lesson stays.

#### Scenario: Inside the window
- **WHEN** the lesson runs in Russian and the phone is shaken twice, 0.9 s apart
- **THEN** the language picker SHALL replace the lesson surface, the teaching loop SHALL be stopped, and Morse "Р" SHALL be played

#### Scenario: Outside the window
- **WHEN** the phone is shaken twice, 1.8 s apart
- **THEN** the lesson surface SHALL stay, on digit "0", with the loop running

### Requirement: Bottom-strip tap feedback end-to-end test
An end-to-end test SHALL tap the real lesson surface and check that a bottom-strip tap while listening plays the 50 ms tap feedback before the answer is checked, and that a bottom-strip tap while the item plays plays none and does not stop the item.

#### Scenario: Tap feedback before the check
- **WHEN** the user taps five dashes for digit "0" and then the bottom strip
- **THEN** a 50 ms vibration SHALL be sent, followed by the success signal

#### Scenario: Bottom strip while the item plays
- **WHEN** the user taps only the bottom strip while digit "0" plays
- **THEN** no 50 ms vibration SHALL be sent and the pattern of "0" SHALL keep repeating

### Requirement: Signal shapes end-to-end test
An end-to-end test SHALL run the app with its real vibration service, catch what it sends to the `vibration` plugin's channel, and answer the motor questions on the `feel_you/vibrator` channel, once with and once without amplitude control. It SHALL check that a correct and a wrong answer send the success and error signals of `vibration-engine` in the version that matches the motor.

#### Scenario: Motor with amplitude control
- **WHEN** the motor reports amplitude control and the user answers once correctly and once wrongly
- **THEN** the success signal SHALL be sent as `[50, 40, 50, 40, 50, 40, 50, 40, 50]` ms and the error signal as `[500]` ms, with their intensities

#### Scenario: Motor without amplitude control
- **WHEN** the motor reports no amplitude control and the user answers once correctly and once wrongly
- **THEN** the success signal SHALL be sent as `[0, 50, 60, 50, 60, 50, 60, 50, 60, 50]` ms and the error signal as `[0, 700]` ms

### Requirement: Vibration gate end-to-end test
An end-to-end test SHALL check `vibration-capability-gate` on the device: with the device's own answers on the iOS simulator, which has no motor, the No vibration screen replaces the picker and the lessons, and the debug button opens the first screen. With a detection that ends late, the No vibration screen SHALL replace a route opened after launch and stop its loop.

#### Scenario: iOS simulator
- **WHEN** the app is launched on the iOS simulator, with or without a saved language
- **THEN** the No vibration screen SHALL be shown, and neither the picker nor the lessons

#### Scenario: Debug bypass
- **WHEN** the debug button is tapped on the No vibration screen
- **THEN** the app's first screen SHALL be shown

#### Scenario: Late detection after a route change
- **WHEN** a language is started in the picker before detection ends, and detection then reports no motor
- **THEN** the No vibration screen SHALL replace the lessons and the teaching loop SHALL be stopped

### Requirement: Vibration sequence regression integration test
The system SHALL have an integration test that drives real lesson flows in English, Arabic and Russian (digits, letters and words, with answers, navigation, spelling and the quiz) and checks, step by step, that the vibration service is asked to play the millisecond patterns and signals recorded on the app before the tactile codec was introduced, with the default Morse timing.

#### Scenario: English digits, letters, words and quiz
- **WHEN** the English lessons start on "0", the user answers "0", swipes to "1", up to "A", answers "A" wrong, up to the words, answers "HI" with a bottom-strip letter gap, holds, swipes down twice and right into the digits quiz
- **THEN** each step SHALL play exactly the recorded sequence: for example `[0, 300, 100, 300, 100, 300, 100, 300, 100, 300]` for "0", cancel and the success signal after the answer, the letters H and I then the word for "HI", and `?` before the quiz item

#### Scenario: Arabic letters and a word with an alias
- **WHEN** the Arabic lessons go from "0" up to "ا", right to "ب", up to the words and right to "ألم"
- **THEN** each step SHALL play the recorded sequence, "ألم" being spelled with Alif's pattern for "أ"

#### Scenario: Russian words and a boundary swipe
- **WHEN** the Russian lessons go from "0" up to "А", up to "ДА", swipe left at the first word and right to "НЕ"
- **THEN** each step SHALL play the recorded sequence, and the boundary swipe SHALL leave "ДА" repeating without a cancel
