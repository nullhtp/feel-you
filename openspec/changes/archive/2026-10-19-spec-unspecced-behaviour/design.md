# Design

## Context

See proposal.md for why. The behaviour in question was shipped by these commits, none of which had an OpenSpec change:

| Commit | What it shipped | Where it is specced now |
|---|---|---|
| b9d524d | stop the loop in the background | `app-lifecycle` |
| 2745499 | drop cancelled pointers | `gesture-recognition` |
| 6b645ac | ignore events while the loop is stopped | `teaching-loop`, `app-lifecycle` |
| c50bd6c, d3eaa25, e1f8217, 532244a | capability check, the gate, the debug bypass, native motor detection | `vibration-capability-gate`, `vibration-engine` |
| fda97a4 | screen-reader semantics | `touch-surface`, `companion-overlay`, `vibration-capability-gate` |
| 509eb87 | explicit Morse intensities for iOS | `vibration-engine` |
| ae75eed, 4062d4b | bottom-strip action and tap feedback races | `bottom-input-zone` |
| 7d1f6b6 | double shake | `shake-gesture`, `touch-surface`, `gesture-recognition` |
| fb56b06, aed7541 | keep the loop playing after a swipe past the first or last item or level | `teaching-loop` |
| 23b6eb3 | discard buffered input when the loop starts over | `teaching-loop` |
| f9edbb0 | words level found by `Level.kind` | `bottom-input-zone` |

The success and error signals were changed in 6accea7 (February) without a spec update. `MorseTimingConfig` lost its signal fields at the same time.

`openspec/config.yaml` asks for every vibration pattern and timing to be documented. These are the ones the user feels, all from the code as it is:

| Signal | Motor with amplitude control (or unknown) | Motor without amplitude control |
|---|---|---|
| Dot / dash | 100 ms / 300 ms at 255 | same |
| Gap between symbols / letters | 100 ms / 300 ms at 0 | same |
| Success | 5 × 50 ms taps, 40 ms gaps: `[50, 40, 50, 40, 50, 40, 50, 40, 50]`, 410 ms | `[0, 50, 60, 50, 60, 50, 60, 50, 60, 50]`, 490 ms |
| Error | `[500]` at 255, 500 ms | `[0, 700]`, 700 ms |
| Tap feedback (bottom strip, while listening) | one 50 ms vibration at default strength | same |
| Quiz marker `?` | `··−−··`, 1500 ms, then 1000 ms silence | same |
| Picker identifiers | E `·`, ع `·−·−`, Р `·−·` | same |

The silences and gestures that frame them:

| Timing | Value |
|---|---|
| Repeat pause | 3000 ms |
| Post-feedback pause (also between a started language's identifier and the first lesson) | 500 ms |
| Spelling letter gap | 1000 ms |
| Silence timeout | 1000 ms |
| Long hold (reset), picker hold | 2000 ms, 1000 ms |
| Shake threshold / cooldown | 15 m/s² after gravity / 1000 ms |
| Shake settle / double-shake window | 700 ms / 1500 ms: shake, pause 0.7 to 1.5 s, shake |

## Goals / Non-Goals

**Goals:**
- Every item of #32 is in a delta spec, with its timings as numbers.
- After archive, `openspec validate --specs --strict` passes and no existing requirement or scenario is lost.
- The new requirements are pinned by tests. Existing unit and widget tests cover most of them. New end-to-end tests run the real app on a simulator.

**Non-Goals:**
- Fixing anything in `app/lib/`, even where the spec now records odd behaviour (see Risks).
- Rewriting specs that this change does not otherwise touch.

## Decisions

**1. Specs follow the code.** Every statement was checked against `app/lib` at 94cc0b3. Where the code and an earlier intention differ, the spec says what the code does, and the difference is listed under Risks. The alternative was to spec the intention and fix the code here. That would mix a behaviour change into a docs change that is supposed to change nothing users feel.

**2. Two new capabilities, no catch-all.**
- `app-lifecycle` holds background suspension. It is not part of `touch-surface`: Phase 0 adds more screens with loops (the reader, the home menu), and they will need the same rule. They can add to this capability instead of copying it.
- `vibration-capability-gate` holds detection, the gate, the No vibration screen, the debug bypass and the overlay's `Vibration:` readout. The readout is drawn by the companion overlay, but it is about the capabilities and changes with them, so it lives with them. `flutter-app-scaffold` keeps its one-sentence mention of the gate. Its scenarios still hold.

**3. Screen-reader semantics live with their widget.** #31 put the picker's semantics in `language-selection`. The same pattern puts the lesson surface's in `touch-surface`, the overlay's summary in `companion-overlay` (beside the quiz summary that is already there), and the No vibration screen's in `vibration-capability-gate`. A separate `screen-reader` capability would split each screen's behaviour across two specs.

**4. The double shake is two self-contained requirements.** Detection (`shake-gesture`: *Double shake emits ChangeLanguage*) carries its own timing. The reaction (`touch-surface`: *Double shake returns to the language picker*) covers the stop, the picker, and what is ignored. #41 changes where the double shake leads, so it can MODIFY the `touch-surface` requirement alone, plus the two places #31 already mentions the picker (`touch-surface` *App entry point integration*, `language-selection` *Language picker screen*). Those mentions are left as they are, because this change has nothing to add to them.

**5. MODIFIED keeps names, REMOVED only for behaviour that is gone.** Requirements and scenarios keep their names when the behaviour still exists, even where a name reads oddly now: *Success signal with default config* now means "a motor with amplitude control, or unknown". Renaming would drop the scenario. REMOVED is used for the three requirements whose behaviour does not exist at all: *Configurable signal vibration timing*, and the two charGap-threshold requirements in `teaching-loop`, which `gesture-recognition` contradicts.

**6. Scope beyond the issue.** Contradictions in the specs this change touches are fixed here, and so is behaviour shipped by the same 15 and 16 October commits (the table above). Leaving them would mean a MODIFIED delta that copies a false scenario forward. `integration-testing` is fixed because the new tests add to it. These are left out and reported for follow-up issues:
- `tuning-config`: describes a file deleted in 3067616. Removing a capability needs its own decision, and OpenSpec has no delta that deletes a spec.
- `app-identity`: the icon source is 895×684 with alpha, not a 1024 px square.
- `release-build-config`: the missing `key.properties` falls back to debug signing silently, without the warning the spec names.
- `morse-encoder` and `morse-pattern-utils`: scenario names contradict their own THEN lines. `morse-word-builder` and `word-pattern-composition` name a `morseAlphabet` that does not exist.

**7. Tests: reuse the unit and widget tests, add end-to-end ones.** The existing tests already pin almost every scenario: the lifecycle, double shake, cancel, gate, bypass, diagnostics, semantics, signal selection and bottom-zone race tests. They stay as they are. New tests:
- `app/integration_test/`: `testWidgets` tests that launch `FeelYouApp` on the simulator with real widgets, classifier, orchestrator and wakelock plugin. Each test replaces only what it must:
  - a recording vibration service, or the `vibration` and `feel_you/vibrator` channels answered in the test, where the signal shape matters;
  - a broadcast accelerometer stream fed in real time;
  - an in-memory saved language;
  - fast timing configs.
- `test/morse/russian_alphabet_test.dart`: the Russian word list content, which no test pins today.

The vibration gate test uses the device's own probe. On the iOS simulator it must report no motor. On other devices it checks that the gate matches what was detected.

**8. Real time in end-to-end tests.** The integration binding runs real timers, and it draws no frames while the app is hidden or paused. So a test that sends the app to the background waits with real delays and pumps only once the app is back in the foreground. Shake timing uses clear margins: 0.9 s is inside the 0.7 to 1.5 s window, and 1.8 s is outside it.

## Risks / Trade-offs

- [The specs now pin behaviour that may be a bug] → Each case is reported, not silently specced as intended:
  - The debug bypass's screen-reader hint says it "opens the language picker". With a saved language it opens the lessons.
  - The success signal is five equal elements, like the digit 5, and only twice as fast. The spec states the timing contrast, so a later change can decide whether that is enough.
- [The change touches 12 capabilities, which makes review harder] → One delta per capability; the context table maps each commit to its spec; the proposal splits the issue's items from the extras.
- [#41 edits the same specs in parallel] → The double-shake requirements are self-contained (Decision 4). Whichever change archives second may need to re-copy a MODIFIED block from the main spec.
- [Real-time end-to-end tests can be flaky on a loaded simulator] → Generous margins and condition-based waits rather than fixed frame counts.
- [The gate end-to-end test depends on the platform] → It asserts no motor only on the iOS simulator. Elsewhere it asserts that the gate follows what was detected.

## Migration Plan

None for the app. The change is archived after the pull request is merged (CONTRIBUTING.md). Archiving was rehearsed on a copy of `openspec/`. It applies cleanly, `openspec validate --specs --strict` passes afterwards, and no existing requirement or scenario is lost.

## Open Questions

- Should `tuning-config` be deleted, or rewritten to say timing lives in the config classes? Follow-up issue; no effect on this change.
