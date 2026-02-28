## 1. Extend MorseSymbol Enum

- [x] 1.1 Add `charGap` value to `MorseSymbol` enum in `app/lib/morse/morse_symbol.dart`
- [x] 1.2 Fix all exhaustive switch expressions that match on `MorseSymbol` (compiler will flag these)

## 2. Update Vibration Engine for charGap

- [x] 2.1 Add `interCharGap` parameter (default 300ms) to `MorseTimingConfig` in `app/lib/vibration/morse_timing_config.dart`
- [x] 2.2 Update `buildMorseVibrationPattern` in `app/lib/vibration/morse_vibration_pattern.dart` to handle `charGap` — produce a silence of `interCharGap` duration instead of a vibration, replacing the inter-symbol gap at that position
- [x] 2.3 Add unit tests for `buildMorseVibrationPattern` with patterns containing `charGap` symbols

## 3. Create Word Morse Data

- [x] 3.1 Create `app/lib/morse/morse_words.dart` with `morseWords` map and `morseWordsList` list containing 20 words (IT, IS, TO, IN, AT, THE, AND, FOR, ARE, BUT, THAT, WITH, HAVE, THIS, FROM, THEIR, ABOUT, WHICH, WOULD, THERE) with flat Morse patterns using `charGap` between letters
- [x] 3.2 Export `morse_words.dart` from the barrel file `app/lib/morse/morse.dart`
- [x] 3.3 Add unit tests verifying all 20 words have correct patterns, charGap placement, and list ordering

## 4. Register Words Level

- [x] 4.1 Add words level entry at index 2 in `app/lib/morse/levels.dart`: `Level(name: 'words', characters: morseWordsList, patterns: morseWords)`
- [x] 4.2 Update `app/test/morse/levels_test.dart` to expect 3 levels and verify the words level at index 2

## 5. Update Gesture Classifier for charGap Input

- [x] 5.1 Add `charGapThreshold` parameter (default 400ms) to `GestureTimingConfig` in `app/lib/gestures/gesture_timing_config.dart`
- [x] 5.2 Update `GestureClassifier` in `app/lib/gestures/gesture_classifier.dart` to emit `MorseSymbol.charGap` in the input symbol sequence when silence between taps exceeds `charGapThreshold` but is less than `silenceTimeout`
- [x] 5.3 Add unit tests for gesture classifier: short silence (no charGap), medium silence (charGap emitted), long silence (InputComplete fired)

## 6. Update Existing Tests

- [x] 6.1 Update vibration pattern tests in `app/test/vibration/` to account for `charGap` in `MorseSymbol`
- [x] 6.2 Update teaching orchestrator tests to verify word pattern evaluation works with `charGap` symbols
- [x] 6.3 Update integration tests that assert on level count or level indices

## 7. Verify End-to-End

- [x] 7.1 Run `flutter analyze` and fix any remaining issues from the `MorseSymbol` enum change
- [x] 7.2 Run full test suite (`flutter test`) and verify all tests pass
