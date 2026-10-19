## MODIFIED Requirements

### Requirement: Morse pattern display
The overlay SHALL display the Morse code pattern for the current character below the symbol display, as the session language's codec describes it: dot (·) and dash (—) characters separated by spaces. For words, the pattern SHALL show the full word pattern with a slash (/) separating each letter's pattern. In the quiz the pattern SHALL be hidden, except during feedback.

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

#### Scenario: Pattern line comes from the codec
- **WHEN** the codec of the session language is replaced, for example by a test codec
- **THEN** the pattern line SHALL show that codec's description of the current item
