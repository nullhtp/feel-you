## MODIFIED Requirements

### Requirement: Current symbol or word display
The overlay SHALL display the current character or word being taught in large, bold, high-contrast white text, centered on the screen. The text SHALL be the largest visual element on screen. For single characters (digits and letters), the font size SHALL be approximately 72sp. For words, the font size SHALL scale down proportionally to fit the screen width while remaining prominent. In the quiz it SHALL show `?` in place of the quiz item, except during feedback.

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

#### Scenario: Quiz item hidden until answered
- **WHEN** the session is in the quiz with quiz item "K" and the phase is `playing` or `listening`
- **THEN** the text "?" SHALL be displayed in place of "K"
- **AND** the text "K" SHALL NOT be displayed

#### Scenario: Quiz item shown during feedback
- **WHEN** the session is in the quiz with quiz item "K" and the phase is `feedback`
- **THEN** the text "K" SHALL be displayed

### Requirement: Morse pattern display
The overlay SHALL display the Morse code pattern for the current character below the symbol display, using dot (·) and dash (—) characters separated by spaces. For words, the pattern SHALL show the full word pattern with a slash (/) separating each letter's pattern. In the quiz the pattern SHALL be hidden, except during feedback.

#### Scenario: Morse pattern for single character
- **WHEN** the current character is "A" (dot dash)
- **THEN** the text "· —" SHALL be displayed below the character, centered on the screen

#### Scenario: Morse pattern for digit
- **WHEN** the current character is "5" (dot dot dot dot dot)
- **THEN** the text "· · · · ·" SHALL be displayed below the character

#### Scenario: Morse pattern for word
- **WHEN** the current word is "IT" (dot dot charGap dash)
- **THEN** the pattern SHALL be displayed with a "/" separating each letter's pattern: "· · / —"

#### Scenario: Quiz pattern hidden until answered
- **WHEN** the session is in the quiz with quiz item "K" and the phase is `playing` or `listening`
- **THEN** the pattern "— · —" SHALL NOT be displayed

### Requirement: Position progress indicator
The overlay SHALL display the user's position within the current level in the top-right corner of the screen, formatted as "current/total" (e.g., "3/26" for the 3rd of 26 letters). Position numbers SHALL be 1-indexed for human readability. In the quiz it SHALL display "QUIZ" instead.

#### Scenario: Progress displayed for letters
- **WHEN** the user is at position index 2 (third letter) in the letters level (26 characters)
- **THEN** the text "3/26" SHALL be displayed in the top-right area

#### Scenario: Progress displayed for digits
- **WHEN** the user is at position index 0 (first digit) in the digits level (10 characters)
- **THEN** the text "1/10" SHALL be displayed in the top-right area

#### Scenario: Progress updates on navigation
- **WHEN** the user navigates to the next or previous character
- **THEN** the progress indicator SHALL update to reflect the new position

#### Scenario: Quiz shown instead of the position
- **WHEN** the session is in the quiz of the letters level
- **THEN** the text "QUIZ" SHALL be displayed in the top-right area
- **AND** no "current/total" position SHALL be displayed

## ADDED Requirements

### Requirement: Learned count
The overlay SHALL display, below the position indicator, how many items of the current level are learned in the current language, formatted as "learned N/total" (e.g. "learned 11/32"). It SHALL show it in the lessons and in the quiz, and update it as soon as an item becomes learned.

#### Scenario: Learned count displayed
- **WHEN** 11 of the 32 Russian letters are learned and the user is on the Russian letters level
- **THEN** the text "learned 11/32" SHALL be displayed below the position indicator

#### Scenario: Learned count updates
- **WHEN** the user answers a letter that is not yet learned correctly in the lessons
- **THEN** the learned count SHALL increase by one

### Requirement: Screen-reader summary in the quiz
The overlay's screen-reader summary SHALL include the learned count. In the quiz it SHALL say "quiz" in place of the position, and it SHALL NOT name the quiz item or its pattern, except during feedback.

#### Scenario: Summary while a quiz item plays
- **WHEN** the session is in the quiz of the English letters level with quiz item "K" and the phase is `playing`
- **THEN** the summary SHALL include "quiz" and the learned count
- **AND** it SHALL NOT include "K" or its pattern

#### Scenario: Summary during quiz feedback
- **WHEN** the session is in the quiz with quiz item "K" and the phase is `feedback`
- **THEN** the summary SHALL include "K"
