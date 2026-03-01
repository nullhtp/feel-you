## Why

The Morse domain layer has grown organically across 11 files with structural issues that make it hard to extend, maintain, and reason about. `MorseSymbol.charGap` conflates user-facing signals with structural separators, `morse_utils.dart` is a grab-bag violating SRP, the encode/decode API is asymmetric across languages, and adding a third language would require touching 5+ files. A focused refactor applying DRY, KISS, and SOLID principles will make the codebase extensible, consistent, and easier to work with.

## What Changes

- **BREAKING** — Split `MorseSymbol` into `MorseSignal` (dot, dash) for user input and a sealed `MorseToken` class (Signal, CharGap) for word patterns. All APIs that previously used `MorseSymbol` will use the appropriate new type.
- **BREAKING** — Replace the scattered alphabet maps (`morseAlphabet`, `morseArabicAlphabet`, `morseDigits`) with a `MorseAlphabet` class and a `MorseAlphabetRegistry` that languages register into. Adding a language becomes adding one data file.
- **BREAKING** — Make encode/decode symmetrically language-aware: both `encodeLetter(char, language)` and `decodePattern(pattern, language)` require a language parameter. Remove the asymmetric `decodePatternForLanguage` variant.
- **BREAKING** — Split `morse_utils.dart` into focused modules: `morse_encoder.dart` (encode/decode via registry), `morse_pattern.dart` (comparison/validation), `morse_word_builder.dart` (word composition).
- **BREAKING** — Integrate levels into the registry so each `MorseAlphabet` defines its own levels. `Level` equality uses all fields, and the levels list becomes unmodifiable.
- Update all consumers (gestures, vibration, session, teaching, UI) to use the new API.
- Update all tests to match the new structure.

## Capabilities

### New Capabilities
- `morse-signal-model`: Separation of `MorseSignal` (dot/dash) from `MorseToken` (Signal/CharGap) to cleanly distinguish user input atoms from word-pattern structure.
- `morse-alphabet-registry`: A `MorseAlphabet` class and `MorseAlphabetRegistry` providing a centralized, extensible system for registering language alphabets, digits, and word lists.
- `morse-encoder`: Focused encode/decode module that uses the registry, with symmetric language-aware API for both directions.
- `morse-pattern-utils`: Focused pattern comparison and validation utilities, decoupled from alphabets.
- `morse-word-builder`: Focused word-pattern composition utilities, decoupled from specific alphabet data.

### Modified Capabilities
- `morse-data`: Letter-to-pattern mapping moves from top-level maps to `MorseAlphabet` instances registered in the registry. `MorseSymbol` replaced by `MorseSignal`.
- `digit-morse-data`: Digit patterns move into the registry as a universal alphabet entry.
- `arabic-morse-data`: Arabic patterns move into the registry as an Arabic-specific alphabet entry.
- `word-morse-data`: Word patterns use `MorseToken` instead of `MorseSymbol`. `charGap` is no longer in the signal enum.
- `word-pattern-composition`: `composeWordPattern` updated to produce `List<MorseToken>` instead of `List<MorseSymbol>`.
- `level-system`: Levels integrated into `MorseAlphabet` registry. `Level` equality uses all fields. Levels list is unmodifiable.
- `language-selection`: `MorseLanguage` enum unchanged, but language picker uses registry to look up identifier patterns instead of hardcoding them.

## Non-goals

- Adding new languages (e.g., Russian) — the registry enables this but we only migrate English and Arabic.
- Changing the vibration engine or gesture recognition — consumers are updated to use new types but their core logic is unchanged.
- Changing the learning flow, session management, or teaching loop behavior.
- Persisting language selection or adding new UI screens.

## Impact

- **Morse domain layer** (`app/lib/morse/`): Complete restructure — 11 files reorganized into ~8 focused files with new type hierarchy.
- **Vibration layer** (`app/lib/vibration/`): `buildMorseVibrationPattern` updated to accept `MorseSignal`/`MorseToken` instead of `MorseSymbol`. Timing config unchanged.
- **Gestures layer** (`app/lib/gestures/`): `GestureEvent` types updated to use `MorseSignal` instead of `MorseSymbol`.
- **Session layer** (`app/lib/session/`): Updated to use registry-based level lookups.
- **Teaching layer** (`app/lib/teaching/`): Pattern comparison calls updated to new module.
- **UI layer** (`app/lib/ui/`): Language picker uses registry instead of hardcoded patterns.
- **Tests** (`app/test/morse/`, `app/test/vibration/`): All 10 Morse-related test files rewritten to match new structure.
- **No new dependencies** — pure Dart refactor using existing packages.
