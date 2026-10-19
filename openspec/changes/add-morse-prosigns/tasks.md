## 1. Prosigns in the codec

- [x] 1.1 Add `lib/tactile/prosign.dart` (`Prosign`: `endOfMessage`, `wait`, `sos`, `error`, each documented with its Morse name, pattern and intended use) and export it from `tactile.dart`; add `encodeProsign` and `describeProsign` to `TactileCodec` after the existing methods; give the three test codecs that implement it (`morse_codec_test.dart`, `tactile_codec_ui_test.dart`, `teaching_orchestrator_codec_test.dart`) implementations; verify `flutter analyze` reports no error
- [x] 1.2 Add `lib/morse/morse_prosigns.dart` (`morseProsignPattern`, an exhaustive switch) and implement both methods in `MorseCodec` without touching `encode`, `describe` or the punctuation table; export it from `morse.dart`; verify unit tests in `test/morse/morse_codec_test.dart`: tokens and descriptions of the four prosigns, identical in all six languages and through `tactileCodecProvider`, no character gap, one character when split, `encode('SOS')` still the three letters
- [x] 1.3 Add `test/morse/morse_prosigns_test.dart`: the default-timing milliseconds and totals (1300, 1100, 2300, 1500 ms), a custom timing that never uses the inter-character gap, no collision with any digit, letter or `?` of any language (over the registry), prosigns distinct from each other, every vibration 100 or 300 ms and every pause 100 ms against the success, error (both versions), tap-feedback and cloud-off signals, and no code in `lib/` outside the codec encoding a prosign; verify `flutter test test/morse test/tactile`
- [x] 1.4 Confirm `MorseTimingConfig`, `vibration_pattern.dart` and `TactileToken` are unchanged (`git diff --stat master -- app/lib/vibration app/lib/tactile/tactile_token.dart` shows nothing)

## 2. End-to-end test

- [x] 2.1 Add `integration_test/prosigns_test.dart`: per language, launch `E2EApp` with the language saved, the default `MorseTimingConfig` and the app's own vibration service over `FakeVibrationPlatform`; check the menu's L, then play the four prosigns, `?` and the identifier letter through the container's `tactileCodecProvider(session language)` and `vibrationServiceProvider`, and compare each `vibrate` call with written-out milliseconds and intensities; verify it passes on the `feel-you-e2e-43` simulator
- [x] 2.2 Break it on purpose: insert a character gap inside the prosigns in `MorseCodec.encodeProsign`, run the test and see it fail, then restore; verify the failure is reported in the change's summary

## 3. Docs

- [x] 3.1 README → Signal Vibrations: a prosigns table with pattern, total duration at the default timing and intended use, and why they don't clash with taught characters or the app's signals; `app/README.md` folder table (`lib/tactile/`, `lib/morse/`); CHANGELOG line under `[Unreleased]` → Added; `openspec/config.yaml` context line; verify the durations in the README match `morse_prosigns_test.dart`

## 4. Gates

- [x] 4.1 From `app/`: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos` (0 warnings, 0 errors), `flutter test`, and the full `flutter test integration_test` on the simulator; `openspec validate add-morse-prosigns --strict`; verify all pass
- [x] 4.2 Prove the archive in a scratch copy of `openspec/`: `openspec archive add-morse-prosigns --yes`, then `openspec validate --specs --strict`; verify both pass and the diff of the main specs only adds `morse-prosigns` and the two added requirements

## Workflow follow-up

- Archive the change (`/opsx:archive`) after the pull request is merged, as CONTRIBUTING.md says.
- #44, #53, #64 and #80 wire the prosigns in; each updates the "Nothing plays a prosign yet" scenario and the test that pins it.
