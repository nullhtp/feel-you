## Context

On a words level the loop plays the word as one token pattern: the letters' dots and dashes with a 300 ms gap between letters, then a 3 s pause, forever. Nothing tells the user which word it is. #8 listed four options; option 1 (spell the word first) was chosen because it needs no sighted help and fits the "patient teacher" model: the app tells the user what it is about to drill, in letters they already know.

## Goals / Non-Goals

**Goals:** a user who knows the letters can tell which word is playing, every time they arrive at one, with no outside help.

**Non-Goals:** see the proposal.

## Decisions

### Timing

```
arrive on HI:  ····   (1 s)   ··   (3 s)   ···· ··   (3 s)   ···· ··   ...
               H              I            HI (drill)        HI
```

| Element | Duration |
|---------|----------|
| Gap between spelled letters (`spellingLetterGap`) | 1000 ms |
| Pause after the spelling, before the first drill | 3000 ms (`repeatPause`) |
| Gap between the letters of a drilled word | 300 ms (unchanged) |

1 s sits between the 300 ms letter gap of the drilled word and the 3 s repeat pause, by a factor of about three on each side (roughly their geometric mean). It is long enough to decode one letter before the next starts, and short enough that the letters still feel like one word rather than separate items. Each letter is played with the normal Morse timing, so it feels exactly as on the letters level.

### When the word is spelled

Whenever the loop starts on a word: `start()` (the lessons open, or come back to the foreground) and every navigation that restarts the loop, including a swipe past the first or last word while listening, which restarts the loop for the same word. Not when the loop resumes after feedback: the user is still on the same word.

### Interruption

The spelling is the first iteration of the loop, in the `playing` phase. Every gap is a cancellable pause (the same mechanism as the repeat pause), and after every letter and every gap the loop checks that it is still current. So a tap stops it and the app listens; navigation, `stop()` and dispose abandon it; a bottom-strip tap is ignored as while the word plays. A user who already knows the word can answer during the spelling.

### Per-letter playback

Each spelled letter is a separate `playMorsePattern` call, with the gap timed by the orchestrator. Building one native pattern with 1 s gaps would need a new `VibrationService` method; the gaps are long enough that Dart timer precision does not matter. The letters come from splitting the word's own token pattern at its char gaps, so they always match the drilled word.

### The pause completer

A loop superseded during a pause can resume after the new loop has started its own pause. The shared `_pause` only clears `_pauseCompleter` if it is still its own, so the new loop's pause stays cancellable.

## Risks / Trade-offs

- Arriving at a word takes longer (a 5-letter word: five letters, four 1 s gaps, then 3 s before the drill). Swiping through words to find one is slower. The user can tap at any time to answer.
- The spelling and the drill differ only in their gaps. A user who loses track can swipe away and back, or hold to return to the first word.
