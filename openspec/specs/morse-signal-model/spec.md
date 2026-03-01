## ADDED Requirements

### Requirement: MorseSignal enum
The system SHALL define a `MorseSignal` enum with exactly two values: `dot` and `dash`. This enum represents the atomic user-facing signals in Morse code. All APIs dealing with individual Morse symbols (gesture input, single-character patterns, pattern comparison) SHALL use `MorseSignal` instead of the former `MorseSymbol`.

#### Scenario: Enum has exactly two values
- **WHEN** a developer inspects the `MorseSignal` enum
- **THEN** it SHALL contain exactly `dot` and `dash` as values

#### Scenario: Type safety prevents invalid signals
- **WHEN** a developer attempts to pass a non-MorseSignal value to a signal-based API
- **THEN** the Dart type system SHALL reject the code at compile time

#### Scenario: No charGap in MorseSignal
- **WHEN** a developer inspects `MorseSignal.values`
- **THEN** there SHALL be no `charGap` or any other structural separator value

### Requirement: MorseToken sealed class
The system SHALL define a `MorseToken` sealed class with exactly two subtypes: `Signal` (wrapping a `MorseSignal` value) and `CharGap` (representing an inter-character boundary). `MorseToken` SHALL be used in word-level patterns where structural separators are needed between character patterns.

#### Scenario: Signal subtype wraps a MorseSignal
- **WHEN** a `Signal(MorseSignal.dot)` token is created
- **THEN** its `signal` property SHALL be `MorseSignal.dot`

#### Scenario: CharGap is a distinct subtype
- **WHEN** a `CharGap()` token is created
- **THEN** it SHALL be distinguishable from any `Signal` token via pattern matching

#### Scenario: Exhaustive switch on MorseToken
- **WHEN** a developer writes a `switch` on a `MorseToken` value with cases for `Signal` and `CharGap`
- **THEN** the Dart compiler SHALL consider the switch exhaustive with no default branch needed

#### Scenario: Signal and CharGap support value equality
- **WHEN** comparing `Signal(MorseSignal.dot)` with another `Signal(MorseSignal.dot)`
- **THEN** they SHALL be equal

#### Scenario: Two CharGap instances are equal
- **WHEN** comparing `CharGap()` with another `CharGap()`
- **THEN** they SHALL be equal

### Requirement: MorseSymbol enum removed
The system SHALL NOT define a `MorseSymbol` enum. All code that previously used `MorseSymbol.dot` or `MorseSymbol.dash` SHALL use `MorseSignal.dot` or `MorseSignal.dash`. All code that previously used `MorseSymbol.charGap` SHALL use the `CharGap` subtype of `MorseToken`.

#### Scenario: No MorseSymbol references in codebase
- **WHEN** searching the codebase for `MorseSymbol`
- **THEN** no references SHALL exist in production code (excluding migration notes or comments)
