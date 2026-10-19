## 1. Tactile tokens and the vibration engine

- [x] 1.1 Add `lib/tactile/` with `TactileToken` (`shortPulse`, `longPulse`, `emptySlot`, `characterGap`), `splitAtCharacterGaps`, the `TactileCodec` interface and a `tactile.dart` barrel; verify with `test/tactile/tactile_token_test.dart` (splitting a word, a gapless run, an empty pattern)
- [x] 1.2 Rename `lib/vibration/morse_vibration_pattern.dart` to `vibration_pattern.dart` (`git mv`) and rewrite it as `buildVibrationPattern(List<TactileToken>, MorseTimingConfig)` with merged silences and `buildVibrationIntensities`; move `vibration_pattern_test.dart` and the intensities test to tokens and add the spec scenarios (empty slot, merged waits, no pulse, a nine-pulse run); verify `flutter test test/vibration`
- [x] 1.3 Replace `playMorsePattern` / `playMorseTokenPattern` with `playTokens` in `VibrationService` and `DeviceVibrationService`, drop every `morse` import from `lib/vibration/`, and update `MorseTimingConfig`'s doc to say how tokens map to its fields; verify `device_vibration_service_test.dart` still expects the same plugin `pattern:` / `intensities:` for R and IT on both platforms' code path, and `grep -rn "morse/" lib/vibration` finds nothing

## 2. Morse codec

- [x] 2.1 Add `MorseAlphabet.aliases` (default empty), move أ / ى and Ё onto the Arabic and Russian alphabets, and build word patterns from `characters` plus `aliases`; verify alias tests (present, not in `characters`, not decoded) and the existing alphabet and words tests pass unchanged
- [x] 2.2 Add `lib/morse/morse_codec.dart`: `MorseCodec` (letters ignoring case, aliases, digits, `?`, `ArgumentError` for anything else, empty text → no tokens) and `formatMorseTokens`; export it from `morse.dart`; verify `test/morse/morse_codec_test.dart`: encode and describe per language and level kind, and for every item of every level of every language the tokens, the default-timing milliseconds (old rule computed from the level pattern) and the description match the level pattern
- [x] 2.3 Add `tactileCodecProvider` (family by language, Morse codec over `morseRegistryProvider`); verify a provider test (default codec per language, override)

## 3. Callers and test doubles

- [x] 3.1 Update `MockVibrationService` and `RecordingVibrationService` to implement `playTokens`, keep recording playbacks in Morse terms through their `playMorsePattern` / `playMorseTokenPattern` methods, and keep the raw tokens in the recording service; verify the doubles' doc comments explain it
- [x] 3.2 `TeachingOrchestrator`: take `codecFor` (default `MorseCodec.new`, provider passes `tactileCodecProvider`), play `codec.encode(item)` on every level, spell with `splitAtCharacterGaps`, announce the quiz with `encode('?')`; remove `splitWordPattern` and its tests; verify all `test/teaching` tests pass unchanged plus a new test with a fake codec (playback follows the codec, answers still checked against the level)
- [x] 3.3 `LanguagePickerSurface`: identifiers are letters (`E`, `ع`, `Р`) encoded with the language's codec; verify the language picker tests pass unchanged (same identifier vibrations)
- [x] 3.4 `CompanionOverlay`: the pattern line is `describe(item)` from the session language's codec, the input line uses `formatMorseTokens`; verify the overlay tests pass unchanged plus a test with an overridden codec
- [x] 3.5 Run the whole unit suite (`flutter test`) and check that the only existing test files changed are the ones calling the engine directly, the doubles, and the removed `splitWordPattern` group

## 4. Integration test of the vibration sequence

- [x] 4.1 Add `integration_test/vibration_sequence_test.dart`: English (digits, answer, letters, wrong answer, words with a bottom-strip gap, hold, quiz), Arabic (letters, word with أ) and Russian (words, boundary swipe) flows, each step compared with the millisecond sequence recorded on master before the refactor; verify it passes with `flutter test integration_test -d E3094777-B342-4A15-AFEF-50A9F98872AA` together with the existing integration tests

## 5. Docs and gates

- [x] 5.1 Update `app/README.md` (code structure: `lib/tactile/`, the Morse codec, the engine) and add a line under `[Unreleased]` in `CHANGELOG.md`; verify the README table lists every `lib/` folder
- [x] 5.2 Run the CI gates from `app/` (`dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos`, `flutter test`) and `openspec validate add-tactile-codec --strict`; verify all pass
- [x] 5.3 Prove the archive applies: copy `openspec/` to a scratch directory, run `openspec archive add-tactile-codec --yes` and `openspec validate --specs --strict` there; verify both pass and the worktree is untouched

## Workflow follow-up

- Archive the change (`/opsx:archive`) after the pull request is merged, as CONTRIBUTING.md says.
