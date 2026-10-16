# Feel You

[![CI](https://github.com/nullhtp/feel-you/actions/workflows/ci.yml/badge.svg)](https://github.com/nullhtp/feel-you/actions/workflows/ci.yml)

A mobile app for deaf-blind people to communicate with the real world using only a phone.

**Platform:** Flutter (Android, and iPhone on iOS), landscape only

## Vision

The phone is the bridge between a deaf-blind person and the world. The entire interface is two channels:

- **Input:** Touch (tap, hold, swipe) and shaking the phone
- **Output:** Vibration (short, long, patterns)

No sight needed. No hearing needed.

## Phase 1: Learn Vibro Morse

The first step is a Morse code learning tool that works through vibration alone, with minimal external help.

### How It Works

The app is a patient, tireless teacher. It vibrates the Morse pattern of one item, waits, and repeats it, forever. The user taps it back when ready, and decides when to move on.

**Prerequisites:** The user knows the digits and the alphabet of their language, and can count positions (A=1, B=2, C=3...). Digits come in order 0-9 and letters in alphabetical order, so counting swipes tells the user which item they are on. Words are grouped by length only, so counting cannot tell which word it is: instead the app spells each word with the letters the user already knows before drilling it (see [the learning loop](#the-learning-loop)).

**Almost no other help needed.** On the very first launch someone (or the user, by touch) picks the language. The choice is saved on the phone, so every later launch goes straight into the lessons.

#### Languages and levels

Three Morse alphabets: **English** (International Morse), **Arabic** and **Russian**. Each language has three levels, always in this order:

| Level | English | Arabic | Russian |
|-------|---------|--------|---------|
| 1. Digits | 0-9 (10) | 0-9 (10) | 0-9 (10) |
| 2. Letters | A-Z (26) | ا ... ي (28) | А ... Я (32, Ё left out: same pattern as Е) |
| 3. Words | 20 words | 20 words | 20 words |

The digits use the same International Morse patterns in every language. Each words level has five 2-letter, five 3-letter, five 4-letter and five 5-letter words, in this order:

| Language | Words |
|----------|-------|
| English | HI OK NO GO UP · YES EAT HOT SIT BAD · HELP COLD PAIN GOOD STOP · WATER HAPPY TIRED SORRY THANK |
| Arabic | كل لا نم هل حر · نعم ألم برد شكر قلب · سعيد شراب وقوف مريض جالس · مساعد عطشان جوعان تعبان سلامك |
| Russian | ДА НЕ ОН НУ УЖ · НЕТ ЕДА СОН ДОМ ПИЛ · БОЛЬ СТОП ВОДА ХОЧУ ЖАРА · СПАТЬ УСТАЛ ЖАРКО ХОЛОД ПУСТЬ |

A session starts at the digits level, on 0. Only the language is saved; the level and position are not, so every launch starts at 0 again.

#### The learning loop

The app plays the current item, pauses for 3 seconds and plays it again, with no limit. A word is played letter by letter, with a longer pause between its letters.

Before drilling a word the app spells it: it plays the word's letters one at a time, 1 second apart, so the user can read the word with the letters they know. Then come the usual 3-second pause and the word itself, which repeats. The app spells the word whenever it starts on one: after a swipe, a level change, a hold or a shake, and when the lessons start or come back to the foreground. After the *correct* or *wrong* signal it goes straight back to the word without spelling it again; swipe away and back to hear the spelling again. A tap during the spelling stops it and the app listens, as during the word.

```
Phone:  · · · ·  ...1 s...  · ·   (spells HI: H, then I)
        ...3 s pause...
Phone:  · · · ·  · ·        (HI, its letters 300 ms apart)
        ...3 s pause...
Phone:  · · · ·  · ·        (repeats, forever)
```

The first dot or dash the user taps stops the playback and the app listens. The answer is checked when the user stops tapping for 1 second, or right away when they tap the bottom strip (digits and letters levels only). Then the app vibrates *correct* or *wrong*, pauses for half a second and goes back to repeating the **same** item. It never moves on by itself.

```
Phone:  · −        (plays A, on the letters level)
        ...3 s pause...
Phone:  · −        (repeats, no rush, forever)
        ...3 s pause...
User:   · −        (taps the left half, then the right half)
        ...1 s without a tap: the answer is checked...
Phone:  ·····      (five quick taps: correct)
        ...0.5 s...
Phone:  · −        (A again, until the user swipes to the next letter)
```

Wrong attempt:

```
User:   ·          (taps the left half only)
Phone:  ━━━━━      (one long buzz: wrong)
        ...0.5 s...
Phone:  · −        (here it is again, keep trying)
```

On a words level the answer must also have the letter boundaries in the right places: the user taps the bottom strip once between letters. For `HI` that is `· · · ·`, a bottom-strip tap, then `· ·`. On digits and letters levels only the dots and dashes count.

### The Screen

The phone is held in landscape. The screen is black. It is split by where a press *starts*:

```
+--------------------------------+--------------------------------+
|                                |                                |
|           LEFT HALF            |           RIGHT HALF           |
|          tap = dot  ·          |          tap = dash  −         |
|                                |                                |
|                                |                                |
+--------------------------------+--------------------------------+
|  BOTTOM STRIP (lower 15% of the height)                         |
|  tap = submit now (digits, letters) / letter gap (words)        |
+-----------------------------------------------------------------+

Swipes and the 2-second hold work anywhere, including the bottom strip.
```

How long a tap lasts does not matter, only where it starts: the left half is always a dot and the right half always a dash. A press on the exact middle is a dash.

### Gestures

| Gesture | Where | Action |
|---------|-------|--------|
| **Tap** | Left half | Dot |
| **Tap** | Right half | Dash |
| **Tap** | Bottom strip | Digits and letters: check the answer now instead of waiting 1 s. Words: add a letter gap after the dots and dashes tapped so far. Confirmed with a short buzz. Ignored until the first dot or dash, so a stray touch never stops the item playing. |
| *(no tap for 1 s)* | | The answer is checked |
| **Swipe right / left** | Anywhere | Next / previous item in the level. Stops at the first and last item (no wrap-around). |
| **Swipe up / down** | Anywhere | Next / previous level (digits → letters → words), starting at its first item. Stops at digits and at words. |
| **Hold 2 seconds** | Anywhere | Back to the first item of the current level (0, A, ا or А, or the first word). Triggers while the finger is still down. |
| **Shake** | | Home: the digits level, on 0. The language stays. |
| **Double shake** | | Back to the language picker (shake, stop for about a second, shake again). |

Details, with the values from the code:

- **Tap:** any press that is not a swipe and is released within 2 seconds. Only the first finger counts; other fingers touching at the same time are ignored.
- **Swipe:** the finger moves at least 50 logical pixels, at least 200 pixels per second. The direction is the axis it moved further along. A slower or shorter movement is a tap where it started. A swipe or hold discards the dots and dashes tapped so far.
- **Shake:** the acceleration, minus gravity, reaches 15 m/s². A shake goes home at most once per second.
- **Double shake:** the second shake starts 0.7 to 1.5 seconds after the first one ends. The first shake has already gone home; the second one opens the language picker.
- Gestures only act while the lesson is running. When the app leaves the foreground the lesson stops, so nothing vibrates in the background; when the user comes back, the current item starts again from the beginning. The screen stays on during lessons.
- **Screen readers:** while TalkBack or VoiceOver is on, the screen reader takes taps and swipes for itself, so they never reach the lesson screen. Use the screen reader's pass-through gesture (double tap and hold, then gesture) or turn it off for lessons.

### Signal Vibrations

Morse timing:

| Element | Duration |
|---------|----------|
| Dot | 100 ms vibration |
| Dash | 300 ms vibration |
| Gap between the dots and dashes of one character | 100 ms |
| Gap between the letters of a word | 300 ms |
| Gap between the letters of a word when it is spelled | 1 s |
| Pause before the item repeats | 3 s |

Distinct patterns the app uses that are separate from Morse:

| Pattern | Meaning |
|---------|---------|
| `·····` five 50 ms taps, 40 ms apart (410 ms) | Correct |
| `━━━━━` one 500 ms buzz | Wrong, try again |
| One 50 ms buzz | Bottom-strip tap accepted (answer submitted, or letter gap added) |
| `·` / `· − · −` / `· − ·` | Language identifiers in the picker: Morse E (English), ع (Arabic), Р (Russian) |

The correct taps are shorter than a dot with gaps shorter than any Morse gap, and the wrong buzz is longer than a dash, so neither can be mistaken for Morse. On a phone whose motor reports no amplitude control, the app uses duration-only versions: the five taps are 60 ms apart (490 ms) and the wrong buzz lasts 700 ms. After either signal the app waits 0.5 s before repeating the item.

### Choosing a Language

The language picker appears on the first launch (when no language is saved) and after a double shake. It has three columns, left to right: **English**, **العربية**, **Русский**. One language is highlighted at a time, and every gesture answers with the identifier vibration of the language it leaves highlighted, so the picker works without sight:

1. When the picker appears, the highlighted language's identifier plays once. It starts on the saved language, or English if none is saved.
2. **Tap** a column to highlight that language, or **swipe right / left** anywhere (at least 50 pixels) to move to the next / previous language, wrapping around. A shorter drag replays the current identifier.
3. **Hold 1 second**, anywhere, to start the highlighted language, i.e. the last identifier felt.

Starting a language plays its identifier, saves it for the next launch and opens the lessons at the digits level, on 0. The lessons open only after the identifier has finished and half a second of silence has passed, so the first lesson pattern never cuts the identifier short or runs into it. Until then the picker ignores every gesture. Shaking does nothing in the picker.

For a sighted helper, the highlighted column is drawn inverted and a line at the bottom reads *"Tap a language, then hold anywhere for 1 second to start"*. Screen readers see one button per language, spoken in that language; activating a button starts that language directly.

### No Vibration Motor

Vibration is the only output, so on a device that reports it has **no vibration motor** the app shows a "No vibration motor" screen with an explanation for a sighted helper, instead of the picker or the lessons. Release builds offer no way past it. Debug builds add a *Continue anyway (debug build)* button for developers, since the iOS simulator (and possibly an Android emulator) reports no motor. If the app cannot tell whether there is a motor, it assumes there is one.

On an iPhone without Core Haptics (iPhone 7 and older) every vibration is the same fixed system buzz, so Morse timing is lost. The app still runs; the helper overlay shows `custom: no` in amber.

### For Sighted Helpers

The lesson screen is black for the user, with a dim overlay for anyone watching: the zone lines and labels (`DOT`, `DASH`, `SUBMIT` or `GAP`), the current item in large type with its Morse pattern, the level name, the position (e.g. `3/26`), the phase (`PLAYING`, `LISTENING`, `FEEDBACK`), the dots and dashes tapped so far, and a vibration readout in the bottom-left corner (e.g. `Vibration: OK · amplitude: yes · custom: yes`, amber when something is missing). Screen readers get a spoken summary instead: level, item, pattern, position, phase and the input so far.

### Design Principles

- **User controls the pace.** The app just repeats and listens. It never advances by itself.
- **Skip anything, anytime.** Swipe left or right to move between items, up or down to change level.
- **Lost? Reset.** A 2-second hold goes back to the start of the level, a shake to the very start (digit 0). You can always re-anchor.
- **Almost no state.** The app saves only the language. Level and position live in memory.
- **Closer to a musical instrument than a language app.** Like a metronome that plays a note: you listen, you play along when ready, you move on when you decide.

## Future Phases

Phase 1 teaches the language. Future phases use it:

- Words and sentences
- Speech-to-Morse (hear the world through vibration)
- Text-to-Morse (read messages through vibration)
- Morse-to-Text (type by tapping Morse)
- Real-time conversation

See [ROADMAP.md](ROADMAP.md) for what is done and what is open.

## Development

The Flutter app lives in [`app/`](app/). See [app/README.md](app/README.md) for how to build, run and test it.

## License

[MIT](LICENSE)
