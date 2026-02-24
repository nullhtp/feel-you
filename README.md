# Feel You

A mobile app for deaf-blind people to communicate with the real world using only a phone.

**Platform:** Flutter (iOS & Android)

## Vision

The phone is the bridge between a deaf-blind person and the world. The entire interface is two channels:

- **Input:** Touch (tap, hold, swipe)
- **Output:** Vibration (short, long, patterns)

No sight needed. No hearing needed.

## Phase 1: Learn Vibro Morse

The first step is a Morse code learning tool that works through vibration alone, with minimal external help.

### How It Works

The app is a patient, tireless teacher. It plays a Morse pattern through vibration, waits, and repeats — infinitely — until the user is ready to try.

**Prerequisites:** The user knows the alphabet (A-Z) and can count letter positions (A=1, B=2, C=3...).

**No other help needed.** Someone presses "start," and the app takes it from there.

### The Learning Flow

Letters are introduced in alphabetical order. The user always knows which letter they're on by counting from A.

```
Phone:  ·−        (plays pattern for A)
        ...pause...
Phone:  ·−        (repeats)
        ...pause...
Phone:  ·−        (repeats, no rush, forever)
        ...pause...
User:   ·−        (taps the pattern back)
Phone:  · · ·     (success!)
```

Wrong attempt:

```
User:   ·         (wrong pattern)
Phone:  −−−−−     (nope)
Phone:  ·−        (here it is again, keep trying)
```

The user decides when to move to the next letter. The app never rushes, never quizzes, never locks progress.

### Gestures

| Gesture | Action |
|---------|--------|
| **Tap** | Input Morse (short tap = dot, long tap = dash) |
| **Swipe right** | Next letter |
| **Swipe left** | Previous letter |
| **Long hold** | Reset to A |

### Signal Vibrations

Distinct patterns the app uses that are separate from Morse:

| Pattern | Meaning |
|---------|---------|
| `· · ·` (3 quick pulses) | Correct |
| `−−−−−` (one long buzz) | Wrong, try again |

### Design Principles

- **User controls the pace.** The app just repeats and listens.
- **Skip anything, anytime.** Swipe forward to skip a letter, swipe back to revisit one.
- **Lost? Reset.** Long hold goes back to A. You can always re-anchor.
- **Almost no state.** The app only needs to know: which letter are you on.
- **Closer to a musical instrument than a language app.** Like a metronome that plays a note — you listen, you play along when ready, you move on when you decide.

## Future Phases

Phase 1 teaches the language. Future phases use it:

- Words and sentences
- Speech-to-Morse (hear the world through vibration)
- Text-to-Morse (read messages through vibration)
- Morse-to-Text (type by tapping Morse)
- Real-time conversation

## License

TBD
