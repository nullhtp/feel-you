## Why

The modes Phase 0 to 4 add need well-known markers that are Morse, unlike the app's own *correct* and *wrong* signals: the reader must say "end of the text" (#44), the cloud "wait, I'm working on it" (#64), the emergency gesture SOS (#80), and Morse input "I made a mistake" (#53). International Morse already has signs for all four, the prosigns AR, AS, SOS and error. Since #40 the vibration engine plays any codec's tokens, so the prosigns can be added to the codec now, before those modes are built on them (#43).

## What Changes

- **Four prosigns, a closed set the same in every language:** end of message (AR, `· − · − ·`), wait (AS, `· − · · ·`), SOS (`· · · − − − · · ·`) and error (eight dots, written HH). Callers name a prosign; they never spell it.
- **The codec encodes and describes them.** `TactileCodec` gains `encodeProsign` and `describeProsign`. The Morse codec of every language returns the same tokens for a prosign: its pulses with only the inter-symbol gap between them, never a character gap, so it is felt as one character. The description is the companion overlay's notation (`· — · — ·` for AR).
- **They play like any character:** through `playTokens`, timed by the Morse timing configuration, so a later speed setting (#42) applies to them too. At today's timing AR lasts 1300 ms, AS 1100 ms, SOS 2300 ms and error 1500 ms.
- **Checked against what the user already knows:** in none of the six languages does a prosign have the pattern of a digit, a letter or `?`, and none can be taken for the app's success, error, tap-feedback or cloud-off signals. Tests pin both.
- **Nothing plays them yet.** Their intended uses are written into the spec and the README so #44, #53, #64 and #80 build on them. The quiz's `?` stays the character `?`, and the app's success and error signals stay as they are.

## Accessibility

Prosigns are the standard service signals of Morse, so a user who learns Morse elsewhere, or later, already knows them, and a helper can look them up. Because each prosign is one character, its pulses run together with 100 ms gaps: it can't be mistaken for the word of the same letters (the word "SOS" has two 300 ms letter gaps). Each one differs from every item the user has learned in their language, so later modes can use them without making a known letter ambiguous. The app's non-Morse signals stay non-Morse, so *wrong* and the error prosign remain two different things.

## Non-goals

- No screen, gesture or mode plays a prosign in this change: the reader (#44), Morse input (#53), the cloud signals (#64) and the emergency gesture (#80) wire them in.
- No other prosigns (KA, SK, BT, ...) and no other punctuation: the codec still encodes only letters, digits and `?` as text.
- No decoding of a tapped prosign: that is Morse input (#53).
- No change to `MorseTimingConfig`, the vibration engine or the token vocabulary: a prosign is already a valid run of pulses.
- No change to the quiz marker `?`, the success, error, tap-feedback or cloud-off signals, or the language and mode identifiers.
- No lesson or quiz item for the prosigns: they are not taught yet.

## Capabilities

### New Capabilities

- `morse-prosigns`: the closed set of prosigns, their International Morse patterns, their timing, how they stay distinct from taught characters and from the app's signals, and what each one is for.

### Modified Capabilities

- `tactile-codec`: the codec interface also encodes and describes a prosign, and the Morse codec does it identically for every language (added requirement; the existing ones are unchanged).
- `integration-testing`: an end-to-end test plays every prosign in every language through the app's real codec and vibration service and checks what reaches the `vibration` plugin.

## Impact

- **New code:** `lib/tactile/prosign.dart` (the `Prosign` enum), `lib/morse/morse_prosigns.dart` (their Morse patterns).
- **Changed code:** `lib/tactile/tactile_codec.dart` (two methods), `lib/morse/morse_codec.dart` (implements them); the three test codecs that implement `TactileCodec`.
- **Tests:** unit tests for the patterns, descriptions, timings, collisions and distinctness; a new `integration_test/prosigns_test.dart`.
- **Docs:** README (Signal Vibrations), `app/README.md` (folder table), CHANGELOG, `openspec/config.yaml` context.
- **Platforms:** none. A prosign reaches the `vibration` plugin like any Morse character, with the same `pattern:` and `intensities:` on Android and iOS.
