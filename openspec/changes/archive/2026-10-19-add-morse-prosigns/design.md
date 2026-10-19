## Context

See proposal.md for why. The current state, since #40:

- `TactileCodec` (`lib/tactile/tactile_codec.dart`) has `encode(String)` and `describe(String)`. `tactileCodecProvider(language)` gives the `MorseCodec` of a language; every playback is `vibrationService.playTokens(codec.encode(text))`.
- `MorseCodec` looks each character up in the language's letters, the digits, the language's aliases and a punctuation table that holds only `?` (`questionMarkPattern`, the quiz marker). Characters are joined with `TactileToken.characterGap`.
- `TactileToken`'s doc already says a prosign is one character of its codec: a run of pulses with no character gap inside. The engine (`buildVibrationPattern`) already plays such a run with the 100 ms inter-symbol gap between pulses, and `vibration_pattern_test.dart` pins it for a nine-pulse run.
- #42 (Farnsworth timing, possibly a word-gap token) is being built in parallel. It touches `MorseTimingConfig`, `vibration_pattern.dart` and probably the token vocabulary and `encode`'s handling of spaces.

## Goals / Non-Goals

**Goals:**
- A caller says *which* prosign (`Prosign.endOfMessage`) and gets the tokens for its language from the same codec and provider it already uses for text, then plays them with `playTokens`.
- The pattern of each prosign is defined once, for all six languages.
- Proof that no prosign collides with a taught character or an app signal, kept as a test so a new language or signal can't break it silently.
- No change to `MorseTimingConfig`, `vibration_pattern.dart` or `TactileToken`, so #42 rebases cleanly.

**Non-Goals:**
- Decoding prosigns from the user's taps (#53).
- Prosigns in free text (e.g. `<AR>` inside a string): nothing needs that yet.

## Decisions

### 1. `Prosign` is an enum in `lib/tactile/`, named by meaning

```dart
enum Prosign { endOfMessage, wait, sos, error }
```

in `lib/tactile/prosign.dart`, exported from `tactile.dart`. The values say what the sign means; each one's doc gives its Morse name (AR, AS, SOS, HH), pattern and the issue that will use it.

- *Why an enum:* the set is closed and small, the callers (#44, #53, #64, #80) should name a sign, not spell it, and an exhaustive `switch` makes a new value a compile error in every codec until it has a pattern.
- *Why in `lib/tactile/`, not `lib/morse/`:* callers hold a `TactileCodec`, not a `MorseCodec` (that is the point of #40). The meaning ("end of message") is codec-independent; the pattern is the codec's business. A braille codec (#88) would have to say how it ends a message too.
- *Why named by meaning:* `Prosign.as` would be a Dart built-in identifier, and `hh` or `ar` would mean nothing to someone reading the reader's code. The Morse names stay in the docs and the README, where helpers look them up.

Alternatives:
- *Private-use characters or markup in the text (`encode('<AR>')`).* Rejected: callers would spell prosigns, a text could contain one by accident, and the reader would have to escape user text.
- *A `prosign` token kind in `TactileToken`.* Rejected in #40 already: the engine would have to know the patterns.
- *Prosign methods on `MorseCodec` only.* Rejected: every caller would have to downcast the `TactileCodec` from the provider.
- *A separate `ProsignCodec` interface and provider.* Rejected: two providers per language for one code, and nothing forces a new codec to provide both.

### 2. `TactileCodec` gains `encodeProsign` and `describeProsign`

```dart
List<TactileToken> encodeProsign(Prosign prosign);
String describeProsign(Prosign prosign);
```

`encodeProsign` returns one character: pulses only, no `characterGap`. `describeProsign` returns the written form of the same pattern, for the companion overlay. They are added at the end of the interface; `encode` and `describe` are not touched (#42 may change them). The three test codecs that implement `TactileCodec` gain trivial implementations.

Playback stays the one path: `vibrationService.playTokens(codec.encodeProsign(p))`. No `playProsign` on `VibrationService`: the engine must not know Morse, and the prosigns are not signals of the app but characters of the code.

### 3. The Morse patterns live in `lib/morse/morse_prosigns.dart`, language-independent

`morseProsignPattern(Prosign)` is an exhaustive `switch` returning `List<MorseSignal>`:

| Prosign | Morse | Pattern | Vibration at default timing (ms, wait/vibrate) | Total |
|---|---|---|---|---|
| `endOfMessage` | AR | `· − · − ·` | `[0, 100, 100, 300, 100, 100, 100, 300, 100, 100]` | 1300 ms |
| `wait` | AS | `· − · · ·` | `[0, 100, 100, 300, 100, 100, 100, 100, 100, 100]` | 1100 ms |
| `sos` | SOS | `· · · − − − · · ·` | `[0, 100, 100, 100, 100, 100, 100, 300, 100, 300, 100, 300, 100, 100, 100, 100, 100, 100]` | 2300 ms |
| `error` | HH | `· · · · · · · ·` | `[0, 100, (100, 100) × 7]` | 1500 ms |

`MorseCodec.encodeProsign` maps the signals to pulses exactly as `encode` maps a character's; `describeProsign` formats them with `formatMorseTokens` (`· — · — ·`). Neither looks at the codec's language or registry: the prosigns are International Morse, the same in English, Arabic, Russian, Spanish, French and German. The durations come from `MorseTimingConfig` through the engine, like any character, so #42's speed setting applies without further work.

The prosigns are not added to the punctuation table: `encode('+')` still throws, and `encode('SOS')` is still the three letters with two character gaps.

### 4. Collision check: no prosign equals a taught character

Every digit, every letter of each language's letters level, and `?` were compared with the four prosign patterns (aliases share a taught letter's pattern, so they add nothing). The test `morse_prosigns_test.dart` repeats the check over the registry, so a new language or letter that collided would fail it.

| Language | Taught characters checked | AR `·−·−·` | AS `·−···` | SOS `···−−−···` | Error `········` | Nearest taught character (one element shorter) |
|---|---|---|---|---|---|---|
| English | 10 digits, 26 letters, `?` | no match | no match | no match | no match | L `·−··` (AS) |
| Arabic | 10 digits, 28 letters, `?` | no match | no match | no match | no match | ع `·−·−` (AR), ل `·−··` (AS) |
| Russian | 10 digits, 32 letters, `?` | no match | no match | no match | no match | Я `·−·−` (AR), Л `·−··` (AS) |
| Spanish | 10 digits, 27 letters, `?` | no match | no match | no match | no match | L `·−··` (AS) |
| French | 10 digits, 30 letters, `?` | no match | no match | no match | no match | L `·−··` (AS) |
| German | 10 digits, 29 letters, `?` | no match | no match | no match | no match | Ä `·−·−` (AR), L `·−··` (AS) |

No collision, so nothing needed resolving. The near neighbours differ by a whole extra dot (AS is L plus a dot, AR is ع / Я / Ä plus a dot), a difference the lessons already train: E, I, S, H and 5 differ in the same way. SOS (9 elements) and error (8) are longer than anything taught (5 at most, `?` 6). The prosigns also differ from each other.

ITU defines `+` as `·−·−·` and `&` as `·−···`, the same patterns as AR and AS; in Morse they are the same signs. The codec encodes neither, so there is no clash today; a later change that teaches or reads `+` or `&` should treat them as these prosigns.

### 5. Distinctness from the app's signals

| Signal | Shape | Why no prosign can be taken for it |
|---|---|---|
| Correct | five 50 ms taps, 40 ms (or 60 ms) apart | Prosign pulses are 100 or 300 ms with 100 ms gaps: at least twice as long and slower. The error prosign has eight pulses, not five. |
| Wrong | one 500 ms buzz (700 ms on a motor without amplitude control) | One buzz, longer than any prosign pulse (300 ms at most); every prosign has 5 to 9 pulses. |
| Tap feedback | one 50 ms buzz | Half a dot, and alone. |
| Cloud off | two 700 ms buzzes, 300 ms apart | Each buzz is more than twice a dash; two pulses only. |
| Language and mode identifiers | Morse letters (E, ع, Р, Ñ, É, Ü; L, S) | Covered by the collision check: they are letters of the languages. |
| Quiz marker | Morse `?` `··−−··` | Covered by the collision check; `?` stays the character `?`. |

The test asserts it structurally: every vibrate segment of a prosign is the dot or dash duration and every gap between pulses is the inter-symbol gap, while each app signal has a vibrate segment of 50 ms or of 500 ms and more.

### 6. The end-to-end test plays through the app's own objects

`integration_test/prosigns_test.dart` launches `E2EApp` per language with that language saved, the default `MorseTimingConfig` (so the asserted milliseconds are the real ones) and the app's own `DeviceVibrationService`, with `FakeVibrationPlatform` catching the plugin calls. After the menu's L has played, it reads the session's language, the codec from `tactileCodecProvider` and the service from `vibrationServiceProvider` out of the app's container, plays each prosign, then `?` and the language's identifier letter, and compares each `vibrate` call with the written-out milliseconds and intensities. Nothing in the app plays a prosign yet, so there is no gesture to drive; when #44 wires AR into the reader, its e2e test will reach it through a swipe.

## Risks / Trade-offs

- [Every `TactileCodec` must now implement two more methods] → Intended: a codec that cannot end a message is incomplete. Only test fakes implement it today.
- [#42 edits `tactile_codec.dart` and `morse_codec.dart` too] → The new methods are appended after the existing ones and touch none of their lines; the spec delta only ADDs requirements.
- [A prosign near a letter (AS vs L) might be misread at speed] → Accepted: it is the standard code, the difference is a whole dot, and Farnsworth spacing (#42) stretches gaps, not elements.
- [Future punctuation `+` / `&` share AR / AS] → Recorded above; whoever adds punctuation decides.
