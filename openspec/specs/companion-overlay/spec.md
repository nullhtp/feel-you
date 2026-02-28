### Requirement: Zone boundary visualization
The overlay SHALL render thin white divider lines showing the input zone boundaries: a vertical line at the horizontal center of the screen (separating the dot zone from the dash zone), and a horizontal line at 85% of the screen height (separating the upper input area from the bottom submit zone). Zone divider lines SHALL use low opacity (approximately 10-20%) to remain visible without dominating the screen.

#### Scenario: Vertical zone divider displayed
- **WHEN** the overlay is rendered
- **THEN** a thin white vertical line SHALL be displayed at the horizontal midpoint of the screen, spanning from the top to the bottom zone boundary

#### Scenario: Horizontal zone divider displayed
- **WHEN** the overlay is rendered
- **THEN** a thin white horizontal line SHALL be displayed at 85% of the screen height, spanning the full width of the screen

### Requirement: Zone labels
The overlay SHALL display text labels identifying each input zone: "DOT" in the left zone, "DASH" in the right zone, and "SUBMIT" in the bottom zone. Labels SHALL be white text with reduced opacity (approximately 30%) to remain readable without visual dominance. On the words level, the bottom zone label SHALL display "GAP" instead of "SUBMIT".

#### Scenario: Dot zone label displayed
- **WHEN** the overlay is rendered
- **THEN** the text "DOT" SHALL be displayed centered vertically in the left half of the screen

#### Scenario: Dash zone label displayed
- **WHEN** the overlay is rendered
- **THEN** the text "DASH" SHALL be displayed centered vertically in the right half of the screen

#### Scenario: Submit zone label on digits or letters level
- **WHEN** the overlay is rendered and the current level is digits or letters
- **THEN** the text "SUBMIT" SHALL be displayed centered in the bottom zone

#### Scenario: Gap zone label on words level
- **WHEN** the overlay is rendered and the current level is words
- **THEN** the text "GAP" SHALL be displayed centered in the bottom zone

### Requirement: Current symbol or word display
The overlay SHALL display the current character or word being taught in large, bold, high-contrast white text, centered on the screen. The text SHALL be the largest visual element on screen. For single characters (digits and letters), the font size SHALL be approximately 72sp. For words, the font size SHALL scale down proportionally to fit the screen width while remaining prominent.

#### Scenario: Current digit displayed
- **WHEN** the user is on the digits level learning the digit "5"
- **THEN** the text "5" SHALL be displayed in large bold white text, centered on the screen

#### Scenario: Current letter displayed
- **WHEN** the user is on the letters level learning the letter "A"
- **THEN** the text "A" SHALL be displayed in large bold white text, centered on the screen

#### Scenario: Current word displayed
- **WHEN** the user is on the words level learning the word "HELLO"
- **THEN** the text "HELLO" SHALL be displayed in bold white text, centered on the screen, with font size scaled to fit

#### Scenario: Symbol updates on navigation
- **WHEN** the user navigates to a different character (via swipe or other gesture)
- **THEN** the displayed symbol SHALL update to show the new current character

### Requirement: Morse pattern display
The overlay SHALL display the Morse code pattern for the current character below the symbol display, using dot (·) and dash (—) characters separated by spaces. For words, the pattern SHALL show the full word pattern with a slash (/) separating each letter's pattern.

#### Scenario: Morse pattern for single character
- **WHEN** the current character is "A" (dot dash)
- **THEN** the text "· —" SHALL be displayed below the character, centered on the screen

#### Scenario: Morse pattern for digit
- **WHEN** the current character is "5" (dot dot dot dot dot)
- **THEN** the text "· · · · ·" SHALL be displayed below the character

#### Scenario: Morse pattern for word
- **WHEN** the current word is "IT" (dot dot charGap dash)
- **THEN** the pattern SHALL be displayed with a "/" separating each letter's pattern: "· · / —"

### Requirement: Level indicator
The overlay SHALL display the name of the current level in the top-left corner of the screen. The level name SHALL be displayed in uppercase white text (e.g., "DIGITS", "LETTERS", "WORDS").

#### Scenario: Level name displayed
- **WHEN** the user is on the letters level
- **THEN** the text "LETTERS" SHALL be displayed in the top-left area of the screen

#### Scenario: Level name updates on navigation
- **WHEN** the user navigates to a different level (via vertical swipe)
- **THEN** the level indicator SHALL update to show the new level name

### Requirement: Position progress indicator
The overlay SHALL display the user's position within the current level in the top-right corner of the screen, formatted as "current/total" (e.g., "3/26" for the 3rd of 26 letters). Position numbers SHALL be 1-indexed for human readability.

#### Scenario: Progress displayed for letters
- **WHEN** the user is at position index 2 (third letter) in the letters level (26 characters)
- **THEN** the text "3/26" SHALL be displayed in the top-right area

#### Scenario: Progress displayed for digits
- **WHEN** the user is at position index 0 (first digit) in the digits level (10 characters)
- **THEN** the text "1/10" SHALL be displayed in the top-right area

#### Scenario: Progress updates on navigation
- **WHEN** the user navigates to the next or previous character
- **THEN** the progress indicator SHALL update to reflect the new position

### Requirement: User input buffer display
The overlay SHALL display the user's accumulated input (dots and dashes tapped so far) above the bottom zone, centered horizontally. Each dot SHALL be rendered as "·" and each dash as "—", separated by spaces. Character gaps (on words level) SHALL be rendered as "/". The input buffer SHALL clear when input is submitted or when the user navigates away.

#### Scenario: Input buffer shows accumulated symbols
- **WHEN** the user has tapped dot, dot, dash
- **THEN** the text "· · —" SHALL be displayed above the bottom zone

#### Scenario: Input buffer shows character gap on words level
- **WHEN** the user has tapped dot, dot, then inserted a character gap, then tapped dash
- **THEN** the text "· · / —" SHALL be displayed above the bottom zone

#### Scenario: Input buffer clears after submission
- **WHEN** the user's input is submitted (via silence timeout or bottom zone tap)
- **THEN** the input buffer display SHALL become empty

#### Scenario: Input buffer is empty initially
- **WHEN** the session starts or the user navigates to a new character
- **THEN** the input buffer display SHALL be empty (no text shown)

### Requirement: Phase indicator
The overlay SHALL display the current session phase in the top-center area of the screen. The phase SHALL be displayed as uppercase text: "PLAYING", "LISTENING", or "FEEDBACK".

#### Scenario: Playing phase displayed
- **WHEN** the session is in the playing phase (vibrating the pattern)
- **THEN** the text "PLAYING" SHALL be displayed at the top-center

#### Scenario: Listening phase displayed
- **WHEN** the session is in the listening phase (waiting for user input)
- **THEN** the text "LISTENING" SHALL be displayed at the top-center

#### Scenario: Feedback phase displayed
- **WHEN** the session is in the feedback phase (providing success/error vibration)
- **THEN** the text "FEEDBACK" SHALL be displayed at the top-center

### Requirement: Overlay does not intercept touch events
The overlay SHALL NOT intercept or consume any touch events. All touch input SHALL pass through the overlay to the underlying touch surface `Listener` widget. The overlay is purely visual and read-only.

#### Scenario: Touch passes through overlay text
- **WHEN** the user taps on an area where overlay text is displayed
- **THEN** the touch event SHALL be received by the underlying `Listener` and processed normally as a dot or dash input

#### Scenario: Touch passes through zone dividers
- **WHEN** the user taps on a zone divider line
- **THEN** the touch event SHALL be received by the underlying `Listener` and processed normally
