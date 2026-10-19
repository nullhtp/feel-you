## Why

Reading Morse that someone else chose is harder than echoing an item one has counted to. A learner needs more time between characters to recognise each one, without the dots and dashes themselves changing shape, which is what Farnsworth timing does. The text reader (#44) is the first mode that plays text the user did not choose, so it needs a reading speed, saved on the phone, and a way to play more than one word. The settings list (#45) will let the user change it; this change builds the speed, its storage and the API #45 calls (#42).

## What Changes

- **Five reading speeds**, in effective words per minute: **12** (the default, today's timing), **10**, **8**, **6** and **5**. They follow the ARRL Farnsworth formula with the character speed fixed at 12 wpm, the speed of the 100 ms dot. Dots (100 ms), dashes (300 ms) and the 100 ms gap between the pulses of a character never change; only the gaps between characters and between words stretch:

  | wpm | character gap | word gap |
  |---|---|---|
  | 12 | 300 ms | 700 ms |
  | 10 | 458 ms | 1068 ms |
  | 8 | 695 ms | 1621 ms |
  | 6 | 1089 ms | 2542 ms |
  | 5 | 1405 ms | 3279 ms |

- **A word gap.** A fifth tactile token, the word gap, sits between two words. The Morse codec emits it for a space (any run of whitespace between words), so a text of several words can be played; leading and trailing whitespace is ignored. The overlay notation writes it as `//`. `MorseTimingConfig` gains an inter-word gap (700 ms, 7 dots, as ITU) independent of the inter-character gap, and splitting a pattern into characters treats a word gap as a boundary too.
- **The speed is saved** on the phone like the language (`SharedPreferences`, key `reading_speed_wpm`, the speed in wpm). Nothing saved, or an unknown or corrupt value, means 12 wpm. It is backed up like the language.
- **Changing the speed** saves it and plays a sample word at the new speed as confirmation: the same four-letter word of the current language's own words level at every speed (GOOD, سعيد, ВОДА, BIEN, BIEN, WARM). A change while a sample plays cuts it short. No screen calls it yet; the settings list (#45) will.
- **Lessons keep their own timing.** The lessons, the spelling, the quiz, the home menu and the language picker play with the lesson timing whatever the saved speed: 300 ms between the letters of a word, the 1 s spelling gap and the 3 s repeat pause. Only reading modes use the reading timing, through their own timing and vibration service.

## Accessibility

The user feels nothing new until #44 and #45 land: the default is today's timing, and the lessons ignore the speed. The pulses keep their shape at every speed, so a letter learned in the lessons feels the same when read slowly; only the silence around it grows. The confirmation is a word, not a new signal, so it cannot be confused with the success, error or cloud-off signals, and it is a word of the user's own language that they learned in the lessons. Timing alone carries the speed; amplitude carries nothing.

## Non-goals

- No screen or gesture that changes the speed (#45), and no overlay line for it: the overlay changes come with #45.
- No text reader (#44): only the timing, the word gap and the codec support it will use.
- No speeds faster than 12 wpm, no change to the character speed and no per-language speed.
- No change to the lessons, the quiz, the spelling, the home menu or the language picker, nor to the success, error, tap-feedback and cloud-off signals.
- No prosigns (#43) and no other punctuation in the codec.

## Capabilities

### New Capabilities

- `reading-speed`: the five reading speeds and their Farnsworth gaps, the reading timing they give, the saved preference, the confirmation sample and the rule that the lessons keep their own timing.

### Modified Capabilities

- `tactile-codec`: a fifth token, the word gap; the Morse codec encodes whitespace between words as a word gap instead of rejecting a space, and describes it as `//`; splitting into characters also splits at word gaps.
- `vibration-engine`: `MorseTimingConfig` gains the inter-word gap (700 ms), and a word gap plays as a silence of that length.
- `language-selection`: the reading speed is saved besides the language and the learned items.
- `integration-testing`: an end-to-end test of the reading speed.

## Impact

- **Code:** `lib/tactile/tactile_token.dart` (word gap, splitting), `lib/morse/morse_codec.dart` (whitespace), `lib/vibration/` (`MorseTimingConfig.interWordGap` and `copyWith`, the pattern builder, a new `reading_speed.dart`, reading timing and service providers), a new `lib/settings/reading_speed_preference.dart` (store, provider, change and sample), `main.dart` (loads the store before the first frame).
- **Tests:** unit tests for the speeds, the store, the change API, the word gap in the codec and the engine; the vibration test doubles handle the new token; a new end-to-end test, `integration_test/reading_speed_test.dart`.
- **Docs:** README (the speed table in Signal Vibrations, what is saved), `app/README.md` (folder roles), CHANGELOG, `openspec/config.yaml` context.
- **Platforms:** no plugin change. The new preference is an integer in the same `SharedPreferences` file as the language, on Android and iOS.
