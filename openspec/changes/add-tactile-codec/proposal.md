## Why

Every later mode (the text reader, Talk, cloud answers, notifications) has to turn text into vibration, and none of them should need to know that the code is Morse. Today the vibration engine is Morse: `VibrationService` plays `List<MorseSignal>` or `List<MorseToken>`, and `buildMorseVibrationPattern` switches on dots, dashes and `CharGap`. Phase 6 adds a braille codec (#88), and Phase 0 adds prosigns (#43), reading speed (#42) and the reader (#44), all on top of this seam. It has to exist first, so it is the first task of Phase 0 (#40).

## What Changes

- **A tactile token vocabulary between codecs and the engine.** `TactileToken` has four values: a short pulse, a long pulse, an empty slot (a pulse-length silence) and a character gap. Morse needs the pulses and the gap. The empty slot is there so a braille cell (six dots as six time slots, #88) fits without an engine change; a prosign (#43) is a run of pulses with no character gap inside, which the vocabulary already allows.
- **A `TactileCodec` interface:** `encode(String)` returns the tokens that play a text, and `describe(String)` returns the text form a sighted helper reads in the companion overlay (`· · / —` for Morse `IT`).
- **`MorseCodec`, the first codec.** It owns the per-language alphabet lookups: the language's letters (case-insensitive), the letters that share another letter's pattern (أ, ى, Ё, now kept on the alphabet as `aliases`), the digits, and `?`. Characters are joined with a character gap. A Riverpod provider gives the codec for each language.
- **The vibration engine plays tokens only.** **BREAKING (internal API):** `VibrationService.playMorsePattern` and `playMorseTokenPattern` are replaced by `playTokens(List<TactileToken>)`; `buildMorseVibrationPattern` becomes `buildVibrationPattern(List<TactileToken>, MorseTimingConfig)` and `buildMorseVibrationIntensities` becomes `buildVibrationIntensities`. Nothing in `lib/vibration/` imports the Morse types any more.
- **Every playback goes through the codec:** lesson items, the letter-by-letter spelling of a word, the quiz's `?` marker and the language picker's identifiers. The companion overlay draws the item's pattern with `describe`. Answers are still checked against the level's Morse patterns, since the user still taps dots and dashes.
- **The user feels exactly what they felt before:** the same durations, gaps, patterns and lesson flow, on every item of every level of every language. A new integration test pins the vibration sequence of real lesson flows in three languages to the sequence recorded before the refactor.

## Accessibility

Nothing changes for the user: no new gesture, signal, timing or screen. The refactor is only safe if that holds, so the proof is in the tests: every lesson item encodes to the tokens and millisecond pattern it had, and the integration test compares whole lesson flows with the pre-refactor recording. Keeping amplitude out of the token vocabulary keeps the roadmap rule that timing alone carries meaning.

## Non-goals

- No prosigns (#43), no braille codec (#88) and no word gap or Farnsworth timing (#42). The tokens leave room for them; none is built.
- No change to input: the gesture classifier still produces Morse dots, dashes and letter gaps, and answer checking stays Morse.
- No rename of `MorseTimingConfig` or its fields: #42 extends it, and its values keep their meaning.
- No codec setting for the user, and no codec other than Morse.
- No change to the success, error and tap-feedback signals, which are not codec output.
- No screen-reader wording from the codec: the overlay's spoken summary still spells the level's pattern as before.

## Capabilities

### New Capabilities

- `tactile-codec`: the tactile token vocabulary, the `TactileCodec` interface, the Morse codec (encoding and describing text per language) and the provider that gives the codec for a language.

### Modified Capabilities

- `vibration-engine`: the service plays tactile tokens instead of Morse signals and tokens, the pure pattern builder works on tokens, the explicit 0/255 intensities apply to every tactile pattern, and the engine has no Morse dependency.
- `teaching-loop`: lesson items, the spelling and the quiz marker are encoded with the session language's codec; answers are still checked against the level's patterns.
- `companion-overlay`: the item's pattern line is the codec's description of the item.
- `language-selection`: the identifiers are encoded with the language's codec.
- `morse-alphabet-registry`: `MorseAlphabet` gains `aliases`.
- `integration-testing`: a regression test of the vibration sequence of real lesson flows.

## Impact

- **New code:** `lib/tactile/` (`TactileToken`, `TactileCodec`, splitting tokens at character gaps), `lib/morse/morse_codec.dart` and a codec provider in `morse_providers.dart`.
- **Vibration** (`lib/vibration/`): `vibration_service.dart`, `device_vibration_service.dart`, and `morse_vibration_pattern.dart` renamed to `vibration_pattern.dart`.
- **Morse data:** alias maps move from private constants onto `MorseAlphabet.aliases` (Arabic, Russian). `splitWordPattern` goes: the spelling now splits the codec's tokens.
- **Callers:** `teaching_orchestrator.dart` (and its provider), `companion_overlay.dart`, `language_picker_surface.dart`.
- **Tests:** the fake and recording vibration services implement `playTokens` and keep recording playbacks in Morse terms, so existing assertions stay as they are. Tests that call the engine directly move to tokens. New unit tests for the codec boundary; a new integration test of the vibration sequence.
- **Docs:** `app/README.md` code structure, CHANGELOG. No user-visible change, so no README change.
- **Platforms:** none. The plugin calls (`pattern:` and `intensities:`) are byte-for-byte the same on Android and iOS.
