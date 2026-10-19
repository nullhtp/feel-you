## Context

See proposal.md for why. The current state:

- `lib/vibration/` imports `morse.dart`. `VibrationService` has `playMorsePattern(List<MorseSignal>)` and `playMorseTokenPattern(List<MorseToken>)`. `buildMorseVibrationPattern(List<MorseToken>, MorseTimingConfig)` turns `Signal(dot|dash)` and `CharGap` into `[wait, vibrate, ...]` milliseconds, and `buildMorseVibrationIntensities` adds the 0/255 intensities the iOS plugin needs to keep the gaps silent.
- Callers pick the method by level kind. `TeachingOrchestrator` plays `level.patterns[item]` on a characters level, `level.wordPatterns[item]` on a words level, `splitWordPattern(...)` letter by letter when spelling, and `questionMarkPattern` for the quiz. `LanguagePickerSurface` plays `encodeLetter('E' | 'ع' | 'Р', language)`. `CompanionOverlay` formats the level pattern as `· — /`.
- Letters that share another letter's pattern (أ, ى; Ё) are private maps in the alphabet files, used only to build word patterns. `MorseAlphabetRegistry.encodeLetter` does not know them.
- Input stays Morse: `GestureClassifier` emits `MorseToken`s, and answers are compared with the level's `patterns` / `wordPatterns`.
- About 25 test files assert on the fake vibration service in Morse terms (`VibrationCallType.playMorsePattern`, `.patterns` as `List<List<MorseSignal>>`, `callLog` strings), and two override `playMorsePattern` in subclasses.

## Goals / Non-Goals

**Goals:**
- One path from text to vibration (`codec.encode(text)` → `vibrationService.playTokens(tokens)`), used by the lessons now and by the reader later.
- An engine that the braille codec (#88) and prosigns (#43) can use without changing it.
- Byte-for-byte the same calls to the `vibration` plugin, proven by tests rather than argued.
- Existing tests unchanged, except where they call the engine directly or import a moved name.

**Non-Goals:**
- A generic input layer. The gesture classifier, `MorseToken` and answer checking are not touched.
- Moving the lesson data (`Level.patterns`, `wordPatterns`) onto tokens. Levels stay Morse data; only playback goes through the codec.

## Decisions

### 1. `TactileToken` is an enum of four values

```dart
enum TactileToken { shortPulse, longPulse, emptySlot, characterGap }
```

in `lib/tactile/tactile_token.dart`. A token says what is felt, never for how long: timing stays in one place, the engine's config, which is what #42 (Farnsworth) and #90 (watch motor) need to tune. An enum is const, has value equality and exhaustive `switch`, and needs no payload today.

- `shortPulse` / `longPulse`: Morse dot / dash. A raised braille dot would be a `shortPulse`.
- `emptySlot`: a silence as long as a short pulse, i.e. an unraised braille dot. Nothing produces it yet; it is in the vocabulary (and tested in the engine) so that #88 is a new codec, not an engine change.
- `characterGap`: the pause between two characters.
- A prosign (#43) is one character of its codec: a run of pulses with no `characterGap` inside. The engine needs nothing new for it.

Alternatives:
- *A sealed class with durations (`Pulse(ms)`, `Gap(ms)`)*. Rejected: every codec would hard-code timing, and a speed setting would have to re-encode text.
- *A sealed class with a `Prosign` token*. Rejected: the engine would have to know prosign patterns, which is the coupling this change removes.
- *Only pulses and gaps, braille as long pulse = raised, short = flat*. Rejected: #88 asks for "a vibration or a pause" per slot; deciding the braille rhythm belongs to #88, the vocabulary should not force it.
- *No `emptySlot` until #88*. Rejected by the issue's own requirement that braille fit without an engine change.

### 2. The engine maps tokens to `MorseTimingConfig`, merging silences

`buildVibrationPattern(List<TactileToken>, MorseTimingConfig)` in `lib/vibration/vibration_pattern.dart` (renamed from `morse_vibration_pattern.dart`) walks the tokens with a pending wait:

| Token | Effect |
|---|---|
| `shortPulse` | flush the pending wait, vibrate `dotDuration` (100 ms) |
| `longPulse` | flush the pending wait, vibrate `dashDuration` (300 ms) |
| `emptySlot` | add `dotDuration` of silence |
| `characterGap` | add `interCharGap` (300 ms) of silence |
| between two slots (pulse or empty slot) not separated by a gap | add `interSymbolGap` (100 ms) |

The pattern starts with a wait (0 ms when it starts with a pulse), so wait and vibrate always alternate and `buildVibrationIntensities` (renamed from `buildMorseVibrationIntensities`, unchanged) stays a parity rule. A trailing silence is kept, so the playback lasts as long as its tokens. Tokens without any pulse give an empty pattern: a lone wait would be a one-segment pattern, which the iOS plugin vibrates through.

For every pattern Morse produces (pulses, single gaps between characters, no leading or trailing gap) this is exactly the old output. It differs only where the old builder broke the alternation (two gaps in a row, a leading gap), which no code produced.

`MorseTimingConfig` keeps its name and fields: #42 extends it, and the values are the same durations under another view. Renaming it would touch every test harness for no behaviour.

### 3. `VibrationService.playTokens` replaces the two Morse methods

`playTokens(List<TactileToken>)` is the only playback method besides the signals. `DeviceVibrationService.playTokens` builds the pattern and intensities and sends them in one `Vibration.vibrate` call, then waits the total duration, as before. `lib/vibration/` imports `lib/tactile/` and nothing from `lib/morse/`.

### 4. `TactileCodec` and `MorseCodec`

```dart
abstract interface class TactileCodec {
  List<TactileToken> encode(String text);
  String describe(String text);
}
```

`MorseCodec(MorseLanguage language, {MorseAlphabetRegistry? registry})` in `lib/morse/morse_codec.dart` implements it:

- Each character (a Unicode code point) is looked up with `registry.encodeLetter(char, language)` (language letters ignoring case, then digits), then the language alphabet's `aliases`, then a punctuation table holding `?` (`questionMarkPattern`). An unknown character, a space included, throws `ArgumentError`.
- The result is first a `List<MorseToken>` (signals plus `CharGap` between characters); `encode` maps it to tokens (dot → `shortPulse`, dash → `longPulse`, `CharGap` → `characterGap`), `describe` formats it with `formatMorseTokens` (`·`, `—`, `/`, space-separated).
- `formatMorseTokens(List<MorseToken>)` is public so the overlay's input line, which shows the user's Morse input rather than a text, uses the same notation.

Throwing on unknown characters matches `composeWordPattern` and keeps silent data loss out of a deafblind user's reader; the reader (#44) decides what to do with punctuation and spaces. Lesson items are always encodable, which a test checks for every item.

`?` is in the codec because the quiz marker is Morse `?`: the orchestrator encodes `"?"` like any text and stays codec-agnostic. It is punctuation, not a prosign.

Alternatives:
- *Leave the per-character lookup in the registry and add aliases to `encodeLetter`*. Rejected: it changes a function the specs and tests define as "letters only", and the registry would grow text-encoding rules that belong to the codec.
- *Orchestrator converts `level.patterns` to tokens*. Rejected: the lessons would not exercise `encode`, and the reader would take a different path from the lessons.

### 5. Aliases move onto `MorseAlphabet`

`MorseAlphabet.aliases` (`Map<String, List<MorseSignal>>`, default empty) holds أ and ى (Arabic) and Ё (Russian). The alphabet files keep building word patterns from `{...characters, ...aliases}`. `characters` and decoding are unchanged.

### 6. Codec per language through a family provider

`tactileCodecProvider = Provider.family<TactileCodec, MorseLanguage>` in `morse_providers.dart` returns `MorseCodec(language, registry: ref.watch(morseRegistryProvider))`.

- `CompanionOverlay` watches it for the session language and shows `describe(item)`.
- `LanguagePickerSurface` reads it and plays `encode('E' | 'ع' | 'Р')`.
- `TeachingOrchestrator` gets a `TactileCodec Function(MorseLanguage) codecFor` constructor argument (default `MorseCodec.new`); its provider passes `(language) => ref.read(tactileCodecProvider(language))`. A function rather than a codec, because the language changes during the orchestrator's life and the orchestrator must not be rebuilt for it.

Tests that put the session on `FixedLevelsSessionState` (a registry with levels but no characters) do not override `morseRegistryProvider`, so the codec still encodes with the full registry.

### 7. The orchestrator plays what the codec encodes

- Loop: `playTokens(codec.encode(item))` for every level kind. The level kind still decides spelling, answer checking and the bottom strip.
- Spelling: `splitAtCharacterGaps(codec.encode(word))` (in `lib/tactile/`) and play each part, with `spellingLetterGap` between them. It replaces `splitWordPattern`, which nothing else uses and which is removed with its tests (the property it tested, every word splits back into its letters, moves to the codec tests).
- Quiz marker: `playTokens(codec.encode('?'))`.
- Answer checking: unchanged, against `level.patterns` / `level.wordPatterns`.

### 8. Test doubles keep recording in Morse terms

`MockVibrationService` (unit tests) and `RecordingVibrationService` (integration tests) implement `playTokens` and translate each playback back to Morse: a playback with a character gap is recorded as `playMorseTokenPattern` with `MorseToken`s, one without as `playMorsePattern` with `MorseSignal`s, through their existing `playMorsePattern` / `playMorseTokenPattern` methods (no longer `@override`). The existing assertions and the two subclasses that override those methods keep working unchanged. Every lesson word has at least two letters, so a gap reliably marks a word. `RecordingVibrationService` also keeps the raw tokens of each playback (`VibrationCall.played`) for the new integration test. The unit double does not: its Morse methods keep their exact signatures so the subclasses' overrides stay valid, and the new unit tests check tokens through the engine and codec directly.

The engine test files (`vibration_pattern_test.dart`, `device_vibration_service_test.dart` and the intensities test, renamed `vibration_intensities_test.dart`) do change: they call the engine, whose input is now tokens. Their expected milliseconds and plugin arguments are unchanged.

Alternative: *record `playTokens` calls and rewrite the assertions*. Rejected: about 60 assertions in 25 files would change for no gain in coverage.

### 9. Proving "byte-for-byte"

- Unit (`test/morse/morse_codec_test.dart`): for every item of every level of every language, `encode` equals the level pattern mapped to tokens, `buildVibrationPattern(encode(item))` equals the old builder's output for the level pattern (computed in the test from `level.patterns` / `wordPatterns` with the old rule), and `describe` equals the overlay notation.
- Unit (`test/vibration/`): the engine scenarios from the spec, the device service's plugin arguments for R and IT, unchanged from today's test, and a guard that no file in `lib/vibration/` imports `lib/morse/`.
- Unit (`test/teaching/teaching_orchestrator_codec_test.dart`, `test/ui/tactile_codec_ui_test.dart`): with a fake codec, the loop, the spelling, the quiz marker, the overlay's pattern line and the picker's identifiers follow the codec, while answers are still checked against the level.
- Integration (`integration_test/vibration_sequence_test.dart`): real lesson flows in three languages compared step by step with millisecond sequences recorded on master (94cc0b3) before the refactor. Repeats of the loop are timing-dependent, so each step expects: optional repeats of the previous item, then an exact prefix, then only repeats of the new item.

### Vibration patterns (default timing, unchanged)

| Played | Tokens | Milliseconds `[wait, vibrate, …]` |
|---|---|---|
| Digit 0 | 5 × long | `[0, 300, 100, 300, 100, 300, 100, 300, 100, 300]` (1900 ms) |
| Letter A | short, long | `[0, 100, 100, 300]` (500 ms) |
| Word HI | 4 × short, gap, 2 × short | `[0, 100, 100, 100, 100, 100, 100, 100, 300, 100, 100, 100]` (1300 ms) |
| Quiz `?` | short, short, long, long, short, short | `[0, 100, 100, 100, 100, 300, 100, 300, 100, 100, 100, 100]` (1500 ms) |
| Arabic أ (alias) | short, long | `[0, 100, 100, 300]` |

Intensities are 0 on every wait and 255 on every vibrate. Success, error and tap feedback are unchanged and do not go through the codec.

## Risks / Trade-offs

- [The doubles' Morse view hides that the real interface is token-based] → The doubles' doc comments say so, they keep the raw tokens, and the new tests assert on tokens and milliseconds directly.
- [A future one-letter word would be recorded as a character playback by the doubles] → Only affects test bookkeeping; documented on the doubles.
- [Two derivations of a lesson pattern: the level data (answers) and the codec (playback)] → Both read the same alphabet tables; a unit test compares them for every item, so they cannot drift silently.
- [`emptySlot` is unused until #88] → It is part of the engine's tested contract, which is what lets #88 add a codec without touching the engine.
- [An archive replaces a MODIFIED requirement wholesale, so a delta written against an older main spec silently undoes later edits] → The deltas are written against the main specs after `spec-unspecced-behaviour` (#32) was archived: "VibrationService is abstract…" keeps #32's tap feedback, "Morse patterns are sent with explicit intensities" (#32) is modified rather than duplicated, and "Language picker vibration identifiers" keeps "(via tap or swipe)".

## Migration Plan

Internal only; nothing is stored, so there is no data migration and a revert is a plain revert. Order of work: tokens and engine, codec, callers, doubles and tests, docs.

## Open Questions

- Should `MorseTimingConfig` be renamed (e.g. `TactileTimingConfig`) once a second codec exists? Deferred to #88.
- Should the codec also give the screen-reader wording of a pattern ("dot dash gap")? Today the overlay's summary spells the level's Morse pattern; the reader (#44) may want the codec to own it.
- How should the reader treat spaces and unsupported characters (skip, a signal, a word gap)? Decided in #42 / #44; `encode` throws until then.
