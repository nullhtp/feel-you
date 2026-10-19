## ADDED Requirements

### Requirement: Codec encodes and describes prosigns
Besides texts, the `TactileCodec` interface SHALL encode a named prosign (see `morse-prosigns`) into tactile tokens and describe it in the helper's notation. The tokens SHALL be one character: pulses only, with no character gap. The Morse codec SHALL do this the same way for every language, without looking at the language's alphabet, and its description SHALL use the notation of `describe`.

#### Scenario: Encode a prosign
- **WHEN** the Morse codec of any language encodes the end-of-message prosign
- **THEN** it SHALL return a short, a long, a short, a long and a short pulse, and no character gap

#### Scenario: Describe a prosign
- **WHEN** the Morse codec describes the end-of-message, wait, SOS and error prosigns
- **THEN** it SHALL return "· — · — ·", "· — · · ·", "· · · — — — · · ·" and "· · · · · · · ·"

#### Scenario: A prosign splits as one character
- **WHEN** the tokens of any prosign are split at their character gaps
- **THEN** the result SHALL be a single character

#### Scenario: Through the provider
- **WHEN** the codec provider is read for a language and asked for the SOS prosign
- **THEN** it SHALL return the same tokens as the Morse codec of any other language
