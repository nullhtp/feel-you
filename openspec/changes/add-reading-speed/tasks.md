## 1. Word gap

- [x] 1.1 Add `TactileToken.wordGap` and make `splitAtCharacterGaps` split at it too; update the token doc and `TactileCodec.encode`'s doc; verify `test/tactile/tactile_token_test.dart` (five tokens, two words split into four letters)
- [x] 1.2 `MorseCodec`: split the text at runs of whitespace, encode each word with the existing per-character code, put one word gap between words, describe it as `//`; verify `test/morse/morse_codec_test.dart` (two words, runs of whitespace, tabs and line breaks, leading and trailing whitespace, whitespace only, a Russian text, an unknown character in a later word), with the old "space throws" test replaced
- [x] 1.3 The vibration test doubles (`MockVibrationService`, `RecordingVibrationService`) throw for a word gap, as for an empty slot; verify `flutter analyze` reports no non-exhaustive switch

## 2. Timing

- [x] 2.1 `MorseTimingConfig`: `interWordGap` (700 ms), `copyWith`, value equality; `buildVibrationPattern` plays a word gap as `interWordGap` of silence; verify `morse_timing_config_test.dart`, `vibration_pattern_test.dart` (`[shortPulse, wordGap, longPulse]` → `[0, 100, 700, 300]`, a word gap alone → empty) and `device_vibration_service_test.dart` (the plugin is sent `[0, 100, 700, 300]` with `[0, 255, 0, 255]`)
- [x] 2.2 Add `lib/vibration/reading_speed.dart`: `ReadingSpeed` (12, 10, 8, 6, 5 wpm, `standard`, `fromWordsPerMinute`, the ARRL stretch from integers, `timing(base)`); export it; verify `test/vibration/reading_speed_test.dart` pins the table, the unchanged pulses and inter-symbol gap, the exact 1 at 12 wpm and the tuned-timing scenarios
- [x] 2.3 In `vibration_providers.dart`, build both device services with one helper and add the families `readingTimingConfigProvider(speed)` and `readingVibrationServiceProvider(speed)`; document that `morseTimingConfigProvider` and `vibrationServiceProvider` are the lesson timing; verify a provider test (reading timing follows an overridden lesson timing, the reading service uses it, the lesson service keeps the lesson timing) and that `vibration_engine_dependencies_test.dart` still passes

## 3. Saved speed and the change API

- [x] 3.1 Add `lib/settings/reading_speed_preference.dart`: `ReadingSpeedStore`, the `SharedPreferences` store (key `reading_speed_wpm`, an int), the in-memory store, `loadReadingSpeedStore()` and `readingSpeedStoreProvider`; load it in `main.dart` before `runApp`; verify `test/settings/reading_speed_preference_test.dart` (survives a restart, stored as an int, nothing saved, 7 / 0 / "12" / 12.5 read as 12, a write replaces a corrupt value)
- [x] 3.2 Add `readingSpeedProvider` (`ReadingSpeedNotifier.change`: publish, save, play the session language's sample word through `readingVibrationServiceProvider(speed)`, cancelling a sample still playing) and `readingSpeedSampleWord`; verify unit tests: the state and saved value after a change, the sample's tokens for every language (each a four-letter item of its words level), the reading service of the new speed is used, a second change cancels the first sample, and the same speed again replays it
- [x] 3.3 Pin the separation: with 5 wpm saved and after a change, `vibrationServiceProvider` and the teaching orchestrator's service keep the lesson timing (300 ms character gap) and the teaching config keeps its 3 s repeat pause and 1 s spelling gap; verify the test fails when `vibrationServiceProvider` is built from the reading timing

## 4. End to end

- [x] 4.1 Add `integration_test/reading_speed_test.dart` on `E2EApp` with the default Morse timing and `FakeVibrationPlatform`: for English and Russian, every speed through `change` and its sample's exact milliseconds and intensities; a restart on the real `SharedPreferences` at 6 wpm; a lesson word at 5 wpm with 300 ms letter gaps. Run it on the simulator `feel-you-e2e-42`; verify it passes, and fails when the lesson service uses the reading timing and when a gap of the table is off

## 5. Docs and gates

- [x] 5.1 README: a Reading speed table in Signal Vibrations (gaps per speed, that the lessons do not use it, the sample words, no screen until #45), the word gap, and what is saved; `app/README.md` folder roles (`lib/tactile/`, `lib/vibration/`, `lib/settings/`); one CHANGELOG line under Added; the `openspec/config.yaml` context; verify the README timing table and the spec agree
- [x] 5.2 Run the CI gates in `app/` (`dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos`, `flutter test`), `openspec validate add-reading-speed --strict`, and the full integration suite on `feel-you-e2e-42`; verify all pass
- [x] 5.3 Prove the archive applies: copy `openspec/` to a scratch directory, run `openspec archive add-reading-speed --yes` and `openspec validate --specs --strict` there, and diff the main specs; verify only the intended requirements changed

## Workflow follow-up

- Archive the change (`/opsx:archive`) after the pull request is merged, as CONTRIBUTING.md says.
- #44 plays text through `readingVibrationServiceProvider(ref.watch(readingSpeedProvider))`; #45 calls `ref.read(readingSpeedProvider.notifier).change(speed)` and adds the overlay line.
