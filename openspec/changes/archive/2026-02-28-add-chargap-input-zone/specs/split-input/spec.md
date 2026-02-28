## MODIFIED Requirements

### Requirement: Position-based dot/dash classification
The system SHALL classify Morse input based on the horizontal position of the touch relative to the screen width. A tap on the left half of the screen (x-position < screenWidth / 2) SHALL produce a dot. A tap on the right half of the screen (x-position >= screenWidth / 2) SHALL produce a dash. This classification SHALL only apply to taps in the upper region of the screen (above the bottom input zone boundary at 85% of screen height). Taps in the bottom 15% are handled as bottom-zone actions by the `TouchSurface` and are never classified as dot or dash.

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
- **THEN** the system SHALL NOT emit a `MorseInput` event (y=360 >= 340 boundary — this is a bottom-zone tap)
