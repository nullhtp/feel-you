# Roadmap

The first part of this file is the original Phase 1 plan (*Learn Vibro Morse*), kept as history. Later changes replaced parts of it: dots and dashes are now told apart by where the tap lands (left half = dot, right half = dash), not by how long it lasts, and there are digits and words levels and six languages. See [After Phase 1](#after-phase-1-complete) for what changed, [The road ahead](#the-road-ahead) for the plan, and the [README](README.md) for how the app works today.

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
- [x] Start button: one large tap target for a sighted person to press once to begin. *Not built: the change dropped it and the loop starts automatically (`openspec/changes/archive/2026-02-27-touch-ui-layer`). The app now opens on the language picker, or on the home menu once a language is saved, and the lessons start when Learn is chosen there.*
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
- [x] Main specs repaired: all 29 pass `openspec validate --specs --strict`, requirements lost when deltas were copied over main specs are restored or recorded as dropped, and stale requirements found on the way are brought up to date (Arabic letter patterns, word lists, the placeholder screen, the touch surface) ([#31](https://github.com/nullhtp/feel-you/issues/31), `repair-main-specs`). The behaviour shipped without a change (the double shake, background suspension, the vibration gate, screen-reader labels, the signal timings) is specced too, and the specs that contradicted the app are corrected ([#32](https://github.com/nullhtp/feel-you/issues/32), `spec-unspecced-behaviour`).
- [x] A quiz at the end of every level, so the user practises recognising Morse they did not choose: swipe right past the last item, Morse `?` announces it, and it plays random learned items for the user to echo. Learned items (answered correctly once in the lessons) are saved per language and level; every launch still starts at 0 (`add-quiz-slot`).

## The road ahead

Feel You today teaches the language. The phases below build everything the language is for: reading any text, talking face to face, hearing and seeing the world through the cloud, everyday information and safety. Each phase is a [milestone](https://github.com/nullhtp/feel-you/milestones) with a tracking issue (epic) that lists its tasks; tasks carry `Depends on` / `Blocks` links and the milestone's gate says when the phase is done. No dates are set: every phase delivers something usable on its own.

Principles that hold in every phase:

- **The offline core always works.** Learning, talking to a sighted person, quick phrases and the emergency gesture need no network, no keys and no downloaded models. The cloud only adds.
- **The user sets the pace.** The app repeats and waits; it never moves on by itself. Long text is read word by word on a swipe, not as a stream.
- **Every action is confirmed by vibration.** Settings opened, a request sent to the cloud, the key out of credit, no network: each has its own signal, distinct from Morse.
- **One input channel, one output channel.** Tap, swipe, hold and shake in; vibration timing out. Amplitude never carries meaning, because some motors have none.
- **The sighted helper sees, the user does not.** Any screen someone has to look at (settings, overlay, the key) is for the assistant and comes with a tactile signal to the user.
- **AI answers fit the channel.** Morse reads at about 12 words per minute, so an answer is tens of characters, not paragraphs; more detail on request, by gesture.

| Phase | Milestone | Epic | What it delivers | Gate |
|-------|-----------|------|------------------|------|
| 0 | [Foundation](https://github.com/nullhtp/feel-you/milestone/1) | #33 | `TactileCodec`, word-by-word text reader, tactile home menu, settings without sight, prosigns, speed | A blindfolded developer with earplugs reads a 20-word text and returns to the menu without help |
| 1 | [Face-to-face conversation](https://github.com/nullhtp/feel-you/milestone/2) | #34 | Talk mode (a sighted person types, the user feels Morse), Morse-to-text, TTS, quick phrases, assistant screen. All offline | Two people, one blindfolded, agree on a time and place through Talk in five minutes; first external test |
| 2 | [Cloud via OpenRouter](https://github.com/nullhtp/feel-you/milestone/3) | #35 | The assistant enters their own OpenRouter key once; Listen, Look and Ask stream model answers into Morse with tactile network statuses. No server | First word of a photo description within 3 s on LTE; losing the network gives a signal, never silence |
| 3 | [Offline fallbacks](https://github.com/nullhtp/feel-you/milestone/4) | #36 | Backend router, ML Kit OCR and labels, raw speech, answer cache | In airplane mode every mode still answers, with the right source signal |
| 4 | [Everyday life and safety](https://github.com/nullhtp/feel-you/milestone/5) | #37 | Time and battery by gesture, incoming messages, emergency gesture, vibration alarm. All offline | Emergency flow passes on Android and iPhone; zero false triggers in a day |
| 5 | [Dialogue, live mode, translation, documents](https://github.com/nullhtp/feel-you/milestone/6) | #38 | Follow-up questions with context, live Look, translation, structured documents, in-app messages | Five deafblind users use the app for a week |
| 6 | [Extensions](https://github.com/nullhtp/feel-you/milestone/7) | #39 | Braille codec, optional on-device LLM, wearables, more languages, community sharing | Ordered by the Phase 5 pilot |

Phases 0, 1, 3, 4 and 6 work without network or keys; phases 2 and 5 add cloud features on top of them, never instead of them.

Work that runs alongside the phases, labelled by track:

- `track: users` - user research, pilot users, the blindfold self-test protocol (#49, #50, #58, #87). The team has no deafblind testers yet; this track is the most urgent.
- `track: content` - phrase sets, prompts and their evaluation set, store texts, privacy policy (#59, #70, #71).
- `track: devices` - device matrix and vibration timing measurements, store releases (#48, #60).

Open bugs: see the [open `bug` issues](https://github.com/nullhtp/feel-you/issues?q=is%3Aissue%20is%3Aopen%20label%3Abug). How to pick up a task: [CONTRIBUTING.md](CONTRIBUTING.md).
