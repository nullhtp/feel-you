## Why

Commits from 15 and 16 October shipped behaviour without an OpenSpec change. Since then the main specs say less than the app does, and in places the opposite ([#32](https://github.com/nullhtp/feel-you/issues/32)). Phase 0 ([#33](https://github.com/nullhtp/feel-you/issues/33)) changes the gestures, the signals and the navigation. Its changes can only MODIFY a requirement that exists and says what the app does today, so the specs have to catch up first.

## What Changes

The items from #32:

- **Signals contradicted** (`vibration-engine`): success is five 50 ms taps 40 ms apart (410 ms), not a rising 400 ms ramp. Error is one 500 ms buzz, not a falling ramp. On a motor without amplitude control both have duration-only versions: five taps 60 ms apart (490 ms), and a 700 ms buzz. The stale *Configurable signal vibration timing* goes: `MorseTimingConfig` has no signal duration or steps.
- **Tap feedback** (`vibration-engine`, `bottom-input-zone`): `playTapFeedback()`, a 50 ms buzz that the teaching loop plays for a bottom-strip tap while listening, before it submits or adds a gap.
- **Russian word list** (`russian-morse-data`): grouped by length and chosen for daily needs, as the English and Arabic lists are. Not sorted by frequency.
- **Double shake** (`shake-gesture`, `gesture-recognition`, `touch-surface`): the second shake, starting 0.7 to 1.5 s after the first ends, emits `ChangeLanguage`, and the lesson surface opens the picker. The event hierarchy gains `ChangeLanguage`. `TouchCancel` gets a requirement.
- **Background suspension** (new `app-lifecycle`): leaving the foreground stops the loop, releases the wakelock and cancels a press in progress. Coming back restarts the current item.
- **Vibration capability check** (new `vibration-capability-gate`): detection, the gate over every route, the "No vibration motor" screen, its debug-only bypass, and the helper overlay's `Vibration:` readout.
- **Screen readers** (`touch-surface`, `companion-overlay`): the lesson surface's label and hint, and the overlay's live-region summary.
- **Picker** (`language-selection`): a swipe changes the highlight too, and plays the identifier.

Found while checking the specs these items touch. These are also behaviour shipped without a change, or contradictions:

- `shake-gesture`: *Shake after cooldown triggers again* says a shake 1 s after another goes home twice. That is now a double shake.
- `gesture-recognition`: `MorseInput` carries a `MorseSignal` and `InputComplete` a `List<MorseToken>` (`MorseSymbol` is gone). The timing config has `bottomZoneFraction` (0.15).
- `bottom-input-zone`: a gap is inserted without a `MorseInput(charGap)` event, and the words level is found by `Level.kind`, not by index 2.
- `teaching-loop`: success is not "3 quick pulses". After an error the loop replays the item, with no separate replay. The charGap threshold requirements contradict `gesture-recognition` and the code. Events are ignored while the loop is stopped. A swipe past the first or last item or level keeps the loop or the feedback going. Buffered input is discarded whenever the loop starts over.
- `integration-testing`: the app starts on digit 0, not "A". Taps are left and right, not short and long. Swiping right on Z enters the quiz. The new end-to-end tests get requirements.
- `vibration-engine`: Morse patterns are sent with explicit 0/255 intensities, so iOS keeps the gaps.

## Non-goals

- No change to the app: `app/lib/` is not touched. The specs follow the code. Where the code looks wrong, the spec says what it does and the problem is reported separately.
- No change to the double shake itself. It is specced as it works today, in its own requirements, so #41 (double shake to the home menu) can MODIFY them.
- No rewrite of specs that this change does not otherwise touch. `tuning-config` describes a file deleted in February. `app-identity` names a 1024 px icon source the repo does not have. Both are reported for follow-up issues.
- No new signals, timings or gestures.

## Accessibility

Nothing changes for the user. Every signal timing the user feels is now written down, which a deaf-blind user needs: the specs are where "no two signals are the same" can be checked. The new requirements state that nothing vibrates in the background and that the user comes back to the start of the item they were on. They also cover what a screen-reader user can and cannot do on the lesson surface, and what a sighted helper sees when a phone cannot vibrate.

## Capabilities

### New Capabilities

- `app-lifecycle`: what the lessons do when the app leaves and returns to the foreground.
- `vibration-capability-gate`: detecting the motor's capabilities, refusing to run without a motor, the debug bypass and the helper's readout.

### Modified Capabilities

- `vibration-engine`: success, error and tap-feedback signals with exact timings, their amplitude fallbacks, Morse intensities; the stale signal config removed.
- `russian-morse-data`: word list ordering and content.
- `shake-gesture`: double shake, settle and window config, pause and resume, the cooldown scenario.
- `gesture-recognition`: `ChangeLanguage` in the event hierarchy, `TouchCancel`, `bottomZoneFraction`.
- `bottom-input-zone`: when the tap feedback plays; no `MorseInput(charGap)`.
- `language-selection`: a swipe changes the highlight and plays the identifier.
- `touch-surface`: double shake to the picker; screen-reader description.
- `companion-overlay`: screen-reader summary.
- `teaching-loop`: feedback sequences, ignored events, boundary swipes, discarded input, start and stop; charGap threshold removed.
- `integration-testing`: stale scenarios corrected; requirements for the new end-to-end tests.

## Impact

- **Specs**: 10 modified capabilities and 2 new ones, through delta specs in this change. They reach `openspec/specs/` when the change is archived after merge.
- **Tests**: new end-to-end tests in `app/integration_test/` pin the new requirements on a device, and a unit test pins the Russian word list. Existing unit and widget tests already pin most of the requirements and stay as they are.
- **Docs**: `CHANGELOG.md` and the #32 line in `ROADMAP.md`.
- **Code**: none.
