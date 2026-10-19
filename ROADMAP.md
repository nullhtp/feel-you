# Roadmap

The first part of this file is the original Phase 1 plan (*Learn Vibro Morse*), kept as history. Later changes replaced parts of it: dots and dashes are now told apart by where the tap lands (left half = dot, right half = dash), not by how long it lasts, and there are digits and words levels and three languages. See [After Phase 1](#after-phase-1-complete) for what changed, [Next](#next) for open work, and the [README](README.md) for how the app works today.

## Foundation (Complete)

- [x] Monorepo + Flutter scaffold
- [x] Morse data model (A-Z alphabet, encode/decode, validation)
- [x] Gesture recognition (tap/swipe/hold classifier, stream-based)
- [x] Vibration engine (Morse pattern, success/error signal playback)

## Completed Changes

### Change 1: Learning Session State (Complete)

Core state machine tracking the user's learning session.

- [x] Current letter index tracking (A-Z position)
- [x] Session state enum: `playing`, `listening`, `feedback`
- [x] Navigation handling (swipe right/left moves between letters, long hold resets to A)
- [x] Riverpod providers for session state
- [x] In-memory only, no persistence needed

### Change 2: Teaching Loop (Orchestrator) (Complete)

The brain that connects gesture input, vibration output, and session state.

- [x] Play-wait-repeat loop: continuously vibrate the current letter's Morse pattern with pauses, infinitely, until the user taps
- [x] Input evaluation: on `InputComplete`, compare user's pattern against current letter via `patternsEqual`
- [x] Correct answer: play success vibration (`· · ·`), resume repeat loop
- [x] Wrong answer: play error vibration (`−−−−−`), replay correct pattern, resume loop
- [x] Interrupt handling: stop playback when user starts tapping, resume after feedback
- [x] Navigation integration: on `NavigateNext`/`NavigatePrevious`/`Reset`, update letter, restart loop

### Change 3: Touch UI Layer (Complete)

Single full-screen widget connecting real touch events to the gesture classifier.

- [x] Full-screen `GestureDetector` capturing all taps, holds, and swipes
- [x] Feed raw touch events (`onPanDown`/`onPanEnd`/`onPanUpdate`) into `RawTouchEvent` for the classifier
- [x] No visual elements (blank screen — the user is deaf-blind)
- [x] Start button: one large tap target for a sighted person to press once to begin. *Not built: the change dropped it and the loop starts automatically (`openspec/changes/archive/2026-02-27-touch-ui-layer`). The app now opens on the language picker, or straight into the lessons once a language is saved.*
- [x] Accessibility metadata / semantics

### Change 4: Integration Testing & Polish (Complete)

End-to-end validation and platform-specific tuning.

- [x] Integration tests: full learning flow (start → play A → user taps → success → swipe to B → ...)
- [x] Vibration tuning on real iOS and Android devices
- [x] Timing calibration: adjust gesture thresholds and vibration durations from real-device feedback
- [x] Edge cases: rapid swipes, double taps, background/foreground transitions
- [x] Clean release builds for both platforms

## Dependency Order

```
Change 1 (State) → Change 2 (Teaching Loop) → Change 3 (UI Layer) → Change 4 (Testing)
```

## Effort Estimates

| # | Change | Effort | Key Deliverable |
|---|--------|--------|-----------------|
| 1 | Learning Session State | Small | State machine + providers for current letter and session phase |
| 2 | Teaching Loop | Medium | Orchestrator: play patterns, evaluate input, give feedback |
| 3 | Touch UI Layer | Small | Full-screen gesture capture + start button |
| 4 | Integration & Polish | Medium | Real-device tested, release-ready Phase 1 |

## After Phase 1 (Complete)

OpenSpec changes, archived in `openspec/changes/archive/`:

- [x] Level system and the digits level, 0-9 (`2026-02-28-add-digit-level`)
- [x] Words level: 20 common English words (`2026-02-28-add-words-level`)
- [x] Bottom input zone: submit on digits and letters, letter gap on words (`2026-02-28-add-chargap-input-zone`)
- [x] Landscape only, and position-based dot/dash: left half = dot, right half = dash (`2026-02-28-landscape-split-input`)
- [x] Companion overlay for sighted helpers (`2026-02-28-visual-companion-overlay`)
- [x] Arabic Morse and the language picker (`2026-03-01-add-arabic-morse`)
- [x] Store publishing setup and metadata (`2026-03-01-prepare-store-publish`)
- [x] Russian Morse (`2026-03-24-add-russian-morse`)
- [x] Refactors (`2026-02-28-refactor-clean-solid-dry`, `2026-03-01-refactor-morse-language`, `2026-03-01-refactor-morse-word-lesson`)

Later commits, without an OpenSpec change:

- [x] CI: format check, analyze and tests on every push to `master` and every pull request
- [x] iOS build restricted to iPhone
- [x] Teaching loop stops while the app is in the background
- [x] Vibration capability check: "No vibration motor" screen, and duration-only success/error signals for motors without amplitude control
- [x] Screen-reader semantics for the language picker, lesson surface and overlay
- [x] The chosen language is saved, so later launches skip the picker
- [x] Language picker usable without sight
- [x] Double shake returns from a session to the language picker
- [x] Words are spelled letter by letter before they are drilled, so the user knows which word they are on without counting ([#8](https://github.com/nullhtp/feel-you/issues/8), `spell-words-before-drill`)
- [x] Housekeeping: no empty `packages/` folder, a [changelog](CHANGELOG.md) and release steps, and [`run.sh`](run.sh) for Android and iOS ([#13](https://github.com/nullhtp/feel-you/issues/13), `repo-housekeeping`). The empty skeleton of an `expanded-word-levels` change, which never had a proposal, is gone; more word levels would start from a new change.
- [x] Main specs repaired: all 29 pass `openspec validate --specs --strict`, requirements lost when deltas were copied over main specs are restored or recorded as dropped, and stale requirements found on the way are brought up to date (Arabic letter patterns, word lists, the placeholder screen, the touch surface) ([#31](https://github.com/nullhtp/feel-you/issues/31), `repair-main-specs`). Behaviour still missing from the specs: [#32](https://github.com/nullhtp/feel-you/issues/32).
- [x] A quiz at the end of every level, so the user practises recognising Morse they did not choose: swipe right past the last item, Morse `?` announces it, and it plays random learned items for the user to echo. Learned items (answered correctly once in the lessons) are saved per language and level; every launch still starts at 0 (`add-quiz-slot`).

## Next

Open work that already exists. No dates have been set.

- **Open bugs**: see the [open `bug` issues](https://github.com/nullhtp/feel-you/issues?q=is%3Aissue%20is%3Aopen%20label%3Abug).
- **Future phases**: the README's [Future Phases](README.md#future-phases) (words and sentences, speech-to-Morse, text-to-Morse, Morse-to-text, real-time conversation) have no plan yet.
