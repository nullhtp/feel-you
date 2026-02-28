## ADDED Requirements

### Requirement: Position-based dot/dash classification
The system SHALL classify Morse input based on the horizontal position of the touch relative to the screen width. A tap on the left half of the screen (x-position < screenWidth / 2) SHALL produce a dot. A tap on the right half of the screen (x-position >= screenWidth / 2) SHALL produce a dash.

#### Scenario: Tap on left half produces dot
- **WHEN** the user taps at x-position 100 on a screen with width 800
- **THEN** the system SHALL emit a `MorseInput(dot)` event

#### Scenario: Tap on right half produces dash
- **WHEN** the user taps at x-position 500 on a screen with width 800
- **THEN** the system SHALL emit a `MorseInput(dash)` event

#### Scenario: Tap exactly at midpoint produces dash
- **WHEN** the user taps at x-position 400 on a screen with width 800
- **THEN** the system SHALL emit a `MorseInput(dash)` event (midpoint is inclusive to the right/dash side)

#### Scenario: Tap near left edge produces dot
- **WHEN** the user taps at x-position 10 on a screen with width 800
- **THEN** the system SHALL emit a `MorseInput(dot)` event

#### Scenario: Tap near right edge produces dash
- **WHEN** the user taps at x-position 790 on a screen with width 800
- **THEN** the system SHALL emit a `MorseInput(dash)` event

### Requirement: Screen width provided to classifier
The `GestureClassifier` SHALL accept a `screenWidth` parameter (in logical pixels) that defines the boundary between dot and dash input zones. This value SHALL be provided by the UI layer when constructing the classifier.

#### Scenario: Classifier constructed with screen width
- **WHEN** a `GestureClassifier` is created with `screenWidth: 800`
- **THEN** it SHALL use 400 (800 / 2) as the boundary between dot and dash zones

#### Scenario: Classifier is testable with any screen width
- **WHEN** a `GestureClassifier` is created with `screenWidth: 1000` in a test
- **THEN** taps at x < 500 SHALL produce dots and taps at x >= 500 SHALL produce dashes

### Requirement: Tap duration does not affect dot/dash classification
Any non-swipe tap that is shorter than the reset threshold SHALL be classified as dot or dash based solely on position. There SHALL be no dead zone between a maximum tap duration and the reset threshold for Morse input purposes.

#### Scenario: Long tap still classified by position
- **WHEN** the user taps on the left half and holds for 800ms (previously in the dead zone)
- **THEN** the system SHALL emit a `MorseInput(dot)` event based on position

#### Scenario: Very short tap classified by position
- **WHEN** the user taps on the right half for 50ms
- **THEN** the system SHALL emit a `MorseInput(dash)` event based on position
