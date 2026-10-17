## MODIFIED Requirements

### Requirement: Position-based dot/dash classification
The `GestureClassifier` SHALL classify a tap by where it started: left of the horizontal midpoint (x < screenWidth / 2) it SHALL produce a dot, on or right of it a dash. This SHALL apply only to taps that start above the bottom input zone, the lower 15% of the screen height. A tap that starts in the bottom zone SHALL emit a `BottomZoneAction` instead (see `bottom-input-zone`) and never a dot or dash.

#### Scenario: Tap on left half above bottom zone produces dot
- **WHEN** the user taps at x-position 100, y-position 100 on a screen with width 800 and height 400
- **THEN** the system SHALL emit a `MorseInput(dot)` event (y=100 < 340 boundary, x=100 < 400 midpoint)

#### Scenario: Tap on right half above bottom zone produces dash
- **WHEN** the user taps at x-position 500, y-position 100 on a screen with width 800 and height 400
- **THEN** the system SHALL emit a `MorseInput(dash)` event

#### Scenario: Tap exactly at midpoint produces dash
- **WHEN** the user taps at x-position 400, y-position 100 on a screen with width 800 and height 400
- **THEN** the system SHALL emit a `MorseInput(dash)` event (midpoint is inclusive to the right/dash side)

#### Scenario: Tap in bottom zone does not produce dot or dash
- **WHEN** the user taps at x-position 100, y-position 360 on a screen with width 800 and height 400
- **THEN** the system SHALL NOT emit a `MorseInput` event (y=360 >= 340 boundary)
- **AND** it SHALL emit a `BottomZoneAction` event

#### Scenario: The start of the press decides
- **WHEN** the user presses at x-position 390, y-position 100 and releases at x-position 420 (too short for a swipe) on a screen with width 800 and height 400
- **THEN** the system SHALL emit a `MorseInput(dot)` event

## ADDED Requirements

### Requirement: Screen width provided to classifier
The `GestureClassifier` SHALL take the screen width in logical pixels, whose half is the dot/dash boundary, and optionally the screen height, which places the bottom zone. Both SHALL be settable after construction. The touch surface SHALL set them from the live layout size on every touch down, so the zones follow split screen, rotation and display-size changes without recreating the classifier. An unusable value (zero, negative or not finite) SHALL be ignored, keeping the last usable one.

#### Scenario: Classifier constructed with screen width
- **WHEN** a `GestureClassifier` is created with `screenWidth: 800`
- **THEN** it SHALL use 400 (800 / 2) as the boundary between dot and dash zones

#### Scenario: Classifier is testable with any screen width
- **WHEN** a `GestureClassifier` is created with `screenWidth: 1000` in a test
- **THEN** taps at x < 500 SHALL produce dots and taps at x >= 500 SHALL produce dashes

#### Scenario: Width follows the layout
- **WHEN** a classifier created with `screenWidth: 800` later gets `screenWidth = 1000`
- **THEN** a tap at x = 450 SHALL produce a dot

#### Scenario: Unusable width is ignored
- **WHEN** `screenWidth` is set to 0 on a classifier whose width is 800
- **THEN** the width SHALL stay 800

#### Scenario: No usable width yet
- **WHEN** a classifier was created with `screenWidth: 0` and no usable width has been set since
- **THEN** a tap outside the bottom zone SHALL produce neither a dot nor a dash, rather than a dash for every tap

#### Scenario: No height yet
- **WHEN** a classifier has no usable screen height
- **THEN** there SHALL be no bottom zone, and every tap SHALL be a dot or a dash
