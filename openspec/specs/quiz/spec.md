# quiz Specification

## Purpose
The quiz at the end of every level: it plays an item the user did not choose and checks that they felt it, so they practise recognising Morse by touch, not only copying a known item.

## Requirements

### Requirement: Every level ends with a quiz
Every level of every language (digits, letters and words) SHALL have a quiz after its last item. The user SHALL enter it by swiping right on the last item, and leave it as described in `learning-session`. In the quiz the item being taught is a quiz item drawn from the level, not the item at the current position.

#### Scenario: Entering the quiz of the digits level
- **WHEN** the session is on digit "9" and the user swipes right
- **THEN** the session SHALL be in the quiz of the digits level
- **AND** the quiz item SHALL be one of the digits "0" to "9"

#### Scenario: Every level has a quiz
- **WHEN** the session is on the last item of any level of any language and the user swipes right
- **THEN** the session SHALL be in the quiz of that level

### Requirement: Quiz items come from the learned items of the level
The quiz SHALL draw each item at random from the learned items of the current level in the current language (see `learned-items`). While fewer than two items of the level are learned, it SHALL draw from the whole level. A new quiz item SHALL never be the same as the one before it.

#### Scenario: Drawing from learned items
- **WHEN** "A", "B" and "C" are the only learned items of the English letters level
- **AND** the session enters the quiz of that level
- **THEN** every quiz item SHALL be "A", "B" or "C"

#### Scenario: Too few learned items
- **WHEN** only "A" is learned on the English letters level
- **AND** the session enters the quiz of that level
- **THEN** the quiz item SHALL be drawn from all 26 letters

#### Scenario: No immediate repeat
- **WHEN** the quiz item is "B" and a new quiz item is drawn
- **THEN** the new quiz item SHALL NOT be "B"

### Requirement: The quiz announces itself with Morse question mark
When the loop starts in the quiz, or a navigation brings the session into the quiz from outside it, the app SHALL play Morse `?` (`··−−··`, 1500 ms with the default Morse timing), then 1000 ms of silence, then the quiz item. It SHALL NOT play `?` when a new quiz item follows a skip or a correct answer, nor when the loop restarts in the quiz on the same item.

#### Scenario: Entering the quiz
- **WHEN** the session is on the last digit "9" and the user swipes right
- **THEN** the app SHALL play `[dot, dot, dash, dash, dot, dot]`
- **AND** after 1000 ms of silence it SHALL play the quiz item

#### Scenario: Lessons start in the quiz
- **WHEN** the lessons start, or come back to the foreground, while the session is in the quiz
- **THEN** the app SHALL play `?`, then the current quiz item

#### Scenario: No marker for a new item
- **WHEN** the session is in the quiz and a new quiz item follows a skip or a correct answer
- **THEN** the app SHALL play the new quiz item without `?` before it

#### Scenario: Marker is longer than any character
- **WHEN** the `?` pattern (6 elements) is compared with every digit and letter of every language
- **THEN** none SHALL have more than 5 elements

### Requirement: The quiz item repeats like a lesson item
In the quiz the loop SHALL play the quiz item, pause for the repeat pause (3000 ms by default) and play it again, indefinitely, as in the lessons. A word SHALL NOT be spelled before it is played in the quiz: telling which word it is, is the exercise.

#### Scenario: Quiz item repeats
- **WHEN** the quiz item is "K" and the user does not tap
- **THEN** the app SHALL play `[dash, dot, dash]` every repeat pause

#### Scenario: Words are not spelled in the quiz
- **WHEN** the session enters the quiz of a words level and the quiz item is "HI"
- **THEN** after `?` and the silence, the app SHALL play the word's token pattern
- **AND** it SHALL NOT play the letters "H" and "I" on their own first

### Requirement: The user answers a quiz item by echo
The user SHALL answer a quiz item by tapping the pattern they felt. The answer SHALL be taken and checked exactly as in the lessons: the first tap stops the playback, the answer ends after the silence timeout or with a bottom-strip tap on a characters level, and a words level needs the letter gaps in the right places.

#### Scenario: Correct echo
- **WHEN** the quiz item is "K" and the user taps `[dash, dot, dash]`
- **THEN** the answer SHALL be correct

#### Scenario: Wrong echo
- **WHEN** the quiz item is "K" and the user taps `[dash, dot]`
- **THEN** the answer SHALL be wrong

### Requirement: A correct quiz answer moves to a new item
On a correct quiz answer the app SHALL play the success signal, wait the post-feedback pause (500 ms by default) and play a new quiz item, which then repeats. On a wrong answer it SHALL play the error signal, wait the post-feedback pause and play the same quiz item again. A navigation during the feedback SHALL cancel it as in the lessons.

#### Scenario: Correct answer
- **WHEN** the quiz item is "K" and the user's answer is correct
- **THEN** the app SHALL play the success signal
- **AND** after the post-feedback pause it SHALL play a quiz item other than "K"

#### Scenario: Wrong answer
- **WHEN** the quiz item is "K" and the user's answer is wrong
- **THEN** the app SHALL play the error signal
- **AND** after the post-feedback pause it SHALL play "K" again

#### Scenario: Skip during feedback
- **WHEN** the success signal of a quiz answer is playing and the user swipes right
- **THEN** the signal SHALL be cancelled and the app SHALL play a new quiz item
