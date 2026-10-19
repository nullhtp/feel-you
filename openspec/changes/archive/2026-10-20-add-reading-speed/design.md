## Context

See proposal.md for why. The current state (since #40):

- Codecs turn text into `TactileToken`s (`shortPulse`, `longPulse`, `emptySlot`, `characterGap`); `buildVibrationPattern(tokens, MorseTimingConfig)` turns them into `[wait, vibrate, ...]` milliseconds. `MorseTimingConfig` has `dotDuration` 100, `dashDuration` 300, `interSymbolGap` 100 and `interCharGap` 300. There is no word gap: the Morse codec rejects a space.
- One `VibrationService` (`vibrationServiceProvider`, a `DeviceVibrationService` built from `morseTimingConfigProvider`) plays everything: the lessons, the spelling, the quiz marker, the home menu and picker identifiers, and the signals.
- The language is saved by `lib/settings/language_preference.dart`: an interface, a `SharedPreferences` store, an in-memory fallback, a loader `main` awaits before `runApp`, and a provider tests leave at its in-memory default.
- `lib/vibration/` must not import `lib/morse/` (a test enforces it). `lib/settings/` already imports `lib/morse/`, and `lib/session/` imports `lib/settings/`.
- Prosigns (#43) add `encodeProsign` and `describeProsign` to `TactileCodec`: a prosign is one character of pulses.

## Goals / Non-Goals

**Goals:**
- Reading timing that differs from the lesson timing only in the two stretched gaps, from one formula, pinned to whole milliseconds.
- A separation between lesson and reading timing that is visible in the provider names and that a test fails on if the lessons ever pick up the saved speed.
- The smallest codec change that lets a text of several words be played, kept apart from the per-character lookup that #43 changes.
- An API for #45 that is one call: change the speed, which saves it and confirms it.

**Non-Goals:**
- A reader loop, a settings screen, an overlay line (#44, #45).
- Changing how the lessons time anything, including when a speed is saved.

## Decisions

### 1. Five speeds as an enum, with the ARRL stretch as one factor

`ReadingSpeed` in `lib/vibration/reading_speed.dart` is an enum `wpm12, wpm10, wpm8, wpm6, wpm5`, in that order (fastest first), with `wordsPerMinute`, `standard` (`wpm12`) and `fromWordsPerMinute(int)`. It lives next to `MorseTimingConfig` because it is timing (CONTRIBUTING: timing constants stay in the config classes) and needs no Morse type.

ARRL Farnsworth, with the character speed `c` and the effective speed `s` in wpm: the extra delay per standard word (PARIS, 50 units) is `ta = (60c − 37.2s) / (c·s)` seconds, spread over the 19 units of gap in PARIS (four 3-unit character gaps and one 7-unit word gap), so the character gap is `3·ta/19` and the word gap `7·ta/19`. A 100 ms dot is `c = 12` (50 units × 100 ms = 5 s per word). At `s = c`, `ta` is 1.9 s, i.e. 19 dots, the standard 300 and 700 ms gaps. So both gaps are the standard ones scaled by the same factor:

`stretch(s) = ta(s) / ta(c) = (60c − 37.2s) / (22.8·s) = (600c − 372s) / (228s)`

computed from integers, so it is exactly 1 at 12 wpm. `speed.timing(base)` returns `base` with `interCharGap` and `interWordGap` multiplied by the stretch and rounded to whole milliseconds; dots, dashes and `interSymbolGap` are `base`'s. With the default base this gives the table in the proposal (no value is within 0.1 ms of a rounding edge: 457.89, 1068.42, 694.74, 1621.05, 1089.47, 2542.11, 1405.26, 3278.95).

Alternatives:
- *The table as constants.* Same numbers for the default base, but a test config with other gaps would be ignored at 12 wpm, so "12 wpm = the lesson timing" would only hold for the defaults. The factor keeps it for any base; the table is pinned in tests instead.
- *Recomputing the character speed from the base dot.* A test config with a 1 ms dot would make `c` 1200 wpm and the gaps meaningless. The labels assume the 100 ms dot; tuning the dot would make them approximate, which is acceptable for a tuning knob.
- *Faster speeds than 12.* Out of scope: the character speed is fixed at 12, and Farnsworth only slows down.

### 2. `MorseTimingConfig` gains `interWordGap`, `copyWith` and value equality

`interWordGap` defaults to 700 ms (7 dots, ITU), independent of `interCharGap`. `copyWith` lets a speed replace the two gaps. The class becomes an `Equatable`, so configs compare by value in tests and an equal reading timing does not rebuild its service. No field is renamed (#40 kept the names for this change).

### 3. A word gap token, emitted by the codec for whitespace between words

`TactileToken.wordGap` is the pause between two words. The engine plays it as `interWordGap` of silence in place of the gap that would follow the last slot, exactly like a character gap with its own length; consecutive silences still merge.

`MorseCodec.encode` splits the text at runs of whitespace (`\s+`: a space, a tab, a line break), drops empty pieces (leading and trailing whitespace), encodes each word with the existing per-character code and puts one `wordGap` between words. `describe` joins the word descriptions with ` // `, extending the overlay's `/` letter gap: `HI OK` is `· · · · / · · // — — — / — · —`. A text of whitespace only gives no tokens and an empty description, like an empty text. The per-character lookup and the error for an unknown character are unchanged, so #43 (prosigns, inside that lookup) and this change touch different lines.

A prosign (#43) is one character: `encodeProsign` emits pulses only, neither a character gap nor a word gap, so a reading speed leaves its duration unchanged (SOS lasts 2300 ms at every speed). The `TactileCodec` and `Prosign` docs say so; the `morse-prosigns` spec already requires pulses only.

`splitAtCharacterGaps` treats a word gap as a boundary between characters too: `HI OK` splits into H, I, O, K. Each piece is still one character with no gap inside, which is what its callers (the spelling) rely on; a caller that needs the words can split at word gaps first.

The test doubles that record playbacks in Morse terms (`MockVibrationService`, `RecordingVibrationService`) throw for a word gap, as for an empty slot: no lesson plays one.

Alternatives:
- *Only the space character.* A reader text with a line break would then throw. Whitespace is never felt as anything but a pause between words.
- *A `WordGap` Morse token.* `MorseToken` is also the user's input in the lessons, where a word gap does not exist; the gesture classifier and answer checking would have to handle a case they never see.
- *Splitting at word gaps into words in `splitAtCharacterGaps`.* It would hand the spelling pieces with gaps inside, breaking its contract.

### 4. Lesson timing and reading timing are separate providers

| | Lessons, spelling, quiz, menu, picker, signals | Reading modes |
|---|---|---|
| Timing | `morseTimingConfigProvider` | `readingTimingConfigProvider(speed)` = `speed.timing(morseTimingConfigProvider)` |
| Service | `vibrationServiceProvider` | `readingVibrationServiceProvider(speed)` |

Both are in `lib/vibration/vibration_providers.dart`; the reading ones are families keyed by the speed. Both services are `DeviceVibrationService`s built by one helper, so they read the motor's capabilities the same way, and `cancel()` on either stops the motor. The teaching orchestrator, the menu and the picker keep reading `vibrationServiceProvider`, whose doc says the saved speed never reaches it. Which speed is saved is decided in `lib/settings/` (decision 5), so `lib/vibration/` never imports the settings, which import `lib/morse/`.

Alternatives:
- *One `readingTimingConfigProvider` that watches the saved speed.* `lib/vibration/` would import the settings file, which imports the Morse codec and the session for the sample, so the engine would depend on Morse through it.
- *A timing argument on `playTokens`.* Every implementation and test double would change, and nothing would stop a lesson from passing the reading timing; separate providers make the lesson path unable to see it.
- *The orchestrator reading the speed and ignoring it.* No separation to test.

### 5. The saved speed and the change API in `lib/settings/reading_speed_preference.dart`

The file mirrors `language_preference.dart`: `ReadingSpeedStore` (`read()` never returns null: nothing saved, a value that is not an integer, or an integer that is not one of the five speeds, reads as `ReadingSpeed.standard`; `write()` is best effort and logs a failure), `SharedPreferencesReadingSpeedStore` (key `reading_speed_wpm`, the speed's wpm as an int, so the stored value reads as what it means and survives a rename of the enum), `InMemoryReadingSpeedStore`, `loadReadingSpeedStore()` (awaited in `main` before `runApp`, in-memory fallback when the storage cannot be loaded) and `readingSpeedStoreProvider` (in-memory by default, so tests and the end-to-end harness start at 12 wpm without setup). It sits in the same `SharedPreferences` file as the language, so backup treats it the same: the backup rules exclude only the secure storage.

`readingSpeedProvider` is a `NotifierProvider<ReadingSpeedNotifier, ReadingSpeed>`: the speed reading modes play at. It reads the store once, when first read. `change(speed)`:

1. publishes `speed`, so a reader watching the provider picks it up at once;
2. starts saving it;
3. plays the sample word (decision 6) of the session's language, encoded with that language's codec, through `readingVibrationServiceProvider(speed)`; if an earlier sample is still playing it is cancelled first, so quick changes never overlap;
4. completes once the sample has played and the save has finished.

It saves and plays even when the speed is the one already set: the call is a confirmation of where the user is, as a highlight change is in the picker. #45 decides which speed its gestures ask for.

### 6. The sample word: four letters of the language's own words level

The same word at every speed, so only the gaps change between two samples. Four letters give three character gaps, enough to feel the rhythm, while the slowest sample stays under 8.1 s. Each is in the language's words level, so the user has learned it, and none is a word of pain or refusal:

| Language | Word | Morse | At 12 wpm | At 5 wpm |
|---|---|---|---|---|
| English | GOOD | `−−· −−− −−− −··` | 4700 ms | 8015 ms |
| Arabic | سعيد (happy) | `··· ·−·− ·· −··` | 3500 ms | 6815 ms |
| Russian | ВОДА (water) | `·−− −−− −·· ·−` | 4100 ms | 7415 ms |
| Spanish | BIEN (well) | `−··· ·· · −·` | 2700 ms | 6015 ms |
| French | BIEN (well) | `−··· ·· · −·` | 2700 ms | 6015 ms |
| German | WARM (warm) | `·−− ·− ·−· −−` | 3700 ms | 7015 ms |

`readingSpeedSampleWord(language)` is an exhaustive `switch`, so a new language does not compile without one; a unit test checks each is a four-letter item of its words level.

### 7. Tests

- Unit: the pinned table, the stretch at 12 wpm, `timing` keeping pulses and the inter-symbol gap; `interWordGap` and the engine's word gap; the codec's whitespace handling and `//`; splitting at word gaps; the store's fallbacks; `change` (state, saved value, the sample's tokens and timing, cancelling an earlier sample); the lesson service and orchestrator keeping the lesson timing with a slow speed saved.
- End to end (`integration_test/reading_speed_test.dart`), on the app's own `DeviceVibrationService` with the default Morse timing and the plugin channel recorded: for English and Russian, every speed through `change`, each sample's exact milliseconds; a restart through the real `SharedPreferences`; a lesson word at 5 wpm still sent with 300 ms letter gaps. Each is checked to fail when the lesson service is given the reading timing or a gap is off.

## Risks / Trade-offs

- [#43 changed the same codec file and the `tactile-codec` spec] → This change is rebased on it: the word-gap code wraps the per-character code, next to `encodeProsign`. In the spec, "Tactile token vocabulary" is replaced by "Tactile tokens" (REMOVED + ADDED, because its "Four token kinds" scenario has to be renamed), "Morse codec rejects what it cannot encode" and "Splitting tokens into characters" are modified, and the word gap is a new requirement; #43's added "Codec encodes and describes prosigns" is left as it is.
- [Two `DeviceVibrationService` instances] → Neither keeps playback state beyond its own call; `cancel()` is the plugin's global cancel, so a reading sample and a lesson can never both vibrate unnoticed. Nothing plays a sample during a lesson today.
- [A cancelled sample's `change` future still waits its full duration] → `DeviceVibrationService` waits the pattern's length after sending it, as for every playback. Harmless for #45, which does not need to wait for the sample.
- [The slowest sample is about 8 s] → A later change cuts it short, so the user is never stuck waiting for it.

## Migration Plan

Nothing to migrate: no speed is saved before this change, so every phone reads 12 wpm, which is today's timing. Rolling back leaves an unused integer in the preferences.
