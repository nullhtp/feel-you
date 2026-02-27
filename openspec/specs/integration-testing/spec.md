## ADDED Requirements

### Requirement: Full learning flow integration test
The system SHALL have an integration test that validates the complete learning flow from app initialization through letter playback, user input, feedback, and navigation. The test SHALL use real Riverpod providers with a mock `VibrationService` that records all vibration calls.

#### Scenario: Happy path — learn letter A with correct input
- **WHEN** the app starts and the teaching orchestrator begins
- **THEN** the mock vibration service SHALL receive a `playMorsePattern` call with the pattern for letter "A" (dot, dash)
- **WHEN** the user inputs the correct Morse pattern for "A" (a short tap followed by a long press, then silence timeout)
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
The system SHALL have integration tests that validate boundary behavior at letters A and Z.

#### Scenario: Navigate previous at letter A
- **WHEN** the session is on letter "A" and the user swipes left
- **THEN** the session SHALL remain on letter "A"
- **THEN** the orchestrator SHALL continue playing the pattern for "A"

#### Scenario: Navigate next at letter Z
- **WHEN** the session is on letter "Z" and the user swipes right
- **THEN** the session SHALL remain on letter "Z"
- **THEN** the orchestrator SHALL continue playing the pattern for "Z"
