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

A session starts at the digits level, on 0. The level and position are not saved, so every launch starts at 0 again. The language is saved, and so are the items the user has learned, which [the quiz](#the-quiz) draws from.

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

#### The quiz

In the lessons the user always knows which item is playing: they counted their way to it. To read Morse they must also recognise an item they did not choose. That is what the quiz is for.

Every level ends with a quiz, one swipe right past its last item (after 9, after Z, after the last word). The app announces it with Morse `?` (`· · − − · ·`), waits 1 second and plays a random item of the level, which repeats like a lesson item. The user taps back what they felt, and the answer is checked as in the lessons.

- **Correct:** the *correct* signal, half a second, then a **new** random item. The quiz moves on only after a correct answer.
- **Wrong:** the *wrong* signal, half a second, then the same item again.
- **Swipe right:** skip to another item. **Swipe left:** back to the last item of the level. Hold, swipe up or down and shake leave the quiz as usual.

```
Phone:  · · − − · ·  ...1 s...  · · · · −   (?, then a random digit: 4)
        ...3 s pause...
Phone:  · · · · −                           (repeats)
User:   · · · · −
        ...1 s without a tap: the answer is checked...
Phone:  ·····                               (correct)
        ...0.5 s...
Phone:  − − · · ·                           (a new item: 7, without ?)
```

The quiz draws from the items the user has **learned**: an item is learned the first time it is answered correctly in the lessons, and it stays learned. While fewer than two items of the level are learned, the quiz draws from the whole level. It never plays the same item twice in a row. Words are not spelled first in the quiz: working out which word it is, is the exercise. Answers in the quiz do not change what is learned.

Learned items are saved on the phone for each language and level, so the quiz grows from one day to the next even though every launch starts at 0.

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
| **Swipe right / left** | Anywhere | Next / previous item in the level. Swipe right on the last item opens the level's [quiz](#the-quiz); in the quiz, swipe right plays another item and swipe left goes back to the last item. Stops at the first item (no wrap-around). |
| **Swipe up / down** | Anywhere | Next / previous level (digits → letters → words), starting at its first item. Stops at digits and at words. |
| **Hold 2 seconds** | Anywhere | Back to the first item of the current level (0, A, ا or А, or the first word). Triggers while the finger is still down. |
| **Shake** | | Home: the digits level, on 0. The language stays. |
| **Double shake** | | Back to the language picker (shake, stop for about a second, shake again). |

Where the swipes lead (English shown; every language has the same layout):

```
              swipe left <--      --> swipe right

  words       HI    OK    ...   THANK    [?]      ^ swipe up
  letters     A     B     ...   Z        [?]      |
  digits      0     1     ...   9        [?]      v swipe down
              ^
            shake: digits, on 0
```

`[?]` is the level's quiz: it comes after the last item, so swiping right until the Morse `?` is felt always reaches it, without counting. Hold, swipe up or down, shake and double shake leave it as they leave any item. At the top and bottom levels, swipe up or down does nothing, so the quiz stays.

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
| `· · − − · ·` Morse `?` (1500 ms), then 1 s of silence | Entering a level's quiz |
| `━━━━━━━ ━━━━━━━` two 700 ms buzzes, 300 ms apart (1700 ms) | Cloud off: the cloud key was deleted (see [The cloud key](#the-cloud-key)) |

The correct taps are shorter than a dot with gaps shorter than any Morse gap, and the wrong buzz is longer than a dash, so neither can be mistaken for Morse. On a phone whose motor reports no amplitude control, the app uses duration-only versions: the five taps are 60 ms apart (490 ms) and the wrong buzz lasts 700 ms. After either signal the app waits 0.5 s before repeating the item (in the quiz, before a new item after a correct answer). The `?` has 6 elements, more than any digit or letter (5 at most), so it cannot be mistaken for an item. The cloud-off signal is the same on every motor: each of its buzzes is more than twice a dash, so it is not Morse, and it has two buzzes where *wrong* has one.

### Choosing a Language

The language picker appears on the first launch (when no language is saved) and after a double shake. It has three columns, left to right: **English**, **العربية**, **Русский**. One language is highlighted at a time, and every gesture answers with the identifier vibration of the language it leaves highlighted, so the picker works without sight:

1. When the picker appears, the highlighted language's identifier plays once. It starts on the saved language, or English if none is saved.
2. **Tap** a column to highlight that language, or **swipe right / left** anywhere (at least 50 pixels) to move to the next / previous language, wrapping around. A shorter drag replays the current identifier.
3. **Hold 1 second**, anywhere, to start the highlighted language, i.e. the last identifier felt.

Starting a language plays its identifier, saves it for the next launch and opens the lessons at the digits level, on 0. The lessons open only after the identifier has finished and half a second of silence has passed, so the first lesson pattern never cuts the identifier short or runs into it. Until then the picker ignores every gesture. Shaking does nothing in the picker.

For a sighted helper, the highlighted column is drawn inverted and a line at the bottom reads *"Tap a language, then hold anywhere for 1 second to start"*. Screen readers see one button per language, spoken in that language; activating a button starts that language directly.

### No Vibration Motor

Vibration is the only output, so on a device that reports it has **no vibration motor** the app shows a "No vibration motor" screen with an explanation for a sighted helper, instead of the picker or the lessons. Release builds offer no way past it. Debug builds add a *Continue anyway (debug build)* button for developers, since the iOS simulator reports no motor. Android emulators report one, so they open on the picker. If the app cannot tell whether there is a motor, it assumes there is one.

On an iPhone without Core Haptics (iPhone 7 and older) every vibration is the same fixed system buzz, so Morse timing is lost. The app still runs; the helper overlay shows `custom: no` in amber.

### For Sighted Helpers

The lesson screen is black for the user, with a dim overlay for anyone watching: the zone lines and labels (`DOT`, `DASH`, `SUBMIT` or `GAP`), the current item in large type with its Morse pattern, the level name, the position (e.g. `3/26`) with the number of learned items of the level under it (e.g. `learned 11/26`), the phase (`PLAYING`, `LISTENING`, `FEEDBACK`), the dots and dashes tapped so far, a vibration readout in the bottom-left corner (e.g. `Vibration: OK · amplitude: yes · custom: yes`, amber when something is missing), and the [cloud key](#the-cloud-key) in the bottom-right corner, masked (`Cloud key: sk-or-...a1b2`, or `Cloud key: none`). Screen readers get a spoken summary instead: level, item, pattern, position, learned count, phase, the input so far and, last, the masked cloud key (`cloud key none`).

In the quiz the position reads `QUIZ`, and the item and its pattern are replaced by `?` until the user has answered: they appear during the *correct* or *wrong* signal. A user with some sight left cannot read the answer off the screen, and a helper still sees what it was. The spoken summary says "quiz" and leaves the item out in the same way.

### The Cloud Key

Phase 2 adds cloud features (see the [roadmap](ROADMAP.md#the-road-ahead)): the assistant enters their own [OpenRouter](https://openrouter.ai) key once, and the app uses it. The app can already keep that key; the screen to enter or delete it comes with the assistant screen ([#63](https://github.com/nullhtp/feel-you/issues/63)), so for now the overlay reads `Cloud key: none`.

- **Where:** in the phone's secure storage: the iOS Keychain, or on Android encrypted with a key held in the Android Keystore. Never in the app's preferences.
- **On this phone only:** on iOS the Keychain item is "this device only" and not synchronized, so it is neither in iCloud Keychain nor restored to another iPhone. On Android it is left out of cloud backup and device-to-device transfer. The language and learned items are backed up as before.
- **Never shown or logged in full:** the overlay shows `sk-or-` and the last 4 characters (`sk-or-...a1b2`), and only `sk-or-...` or `...` for a short key or one without the `sk-or-` prefix.
- **Deleting it** plays the *cloud off* signal (two 700 ms buzzes), so the user knows the cloud is off.
- iOS keeps Keychain items when an app is deleted, so reinstalling on the same iPhone finds the key again. Delete the key in the app, or erase the phone, to remove it.

### Design Principles

- **User controls the pace.** The app just repeats and listens. It never advances by itself: even the quiz moves on only after a correct answer or a swipe.
- **Skip anything, anytime.** Swipe left or right to move between items, up or down to change level.
- **Lost? Reset.** A 2-second hold goes back to the start of the level, a shake to the very start (digit 0). You can always re-anchor.
- **Almost no state.** The app saves only the language and the items the user has learned, and the assistant's [cloud key](#the-cloud-key) in the phone's secure storage. Level and position live in memory.
- **Closer to a musical instrument than a language app.** Like a metronome that plays a note: you listen, you play along when ready, you move on when you decide.

## Future Phases

Phase 1 teaches the language. Future phases use it:

- Words and sentences
- Speech-to-Morse (hear the world through vibration)
- Text-to-Morse (read messages through vibration)
- Morse-to-Text (type by tapping Morse)
- Real-time conversation

See [ROADMAP.md](ROADMAP.md) for the full plan: seven phases, each a GitHub milestone with a tracking issue, from the text reader and face-to-face conversation to cloud features and safety.

## Development

The Flutter app lives in [`app/`](app/). See [app/README.md](app/README.md) for how to build, run and test it.

## Contributing

Issues, pull requests and accessibility feedback are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md), the [Code of Conduct](CODE_OF_CONDUCT.md) and the [good first issues](https://github.com/nullhtp/feel-you/issues?q=is%3Aissue%20is%3Aopen%20label%3A%22good%20first%20issue%22). Security problems: [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
