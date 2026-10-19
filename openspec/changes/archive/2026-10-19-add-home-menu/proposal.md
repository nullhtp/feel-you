## Why

Phase 0 adds modes the user must reach without sight: the text reader (#44), Talk (#51), a settings list (#45) and more later. Today the app has only two screens, the language picker and the lessons, and a double shake jumps from the lessons to the picker, so there is nowhere to put a new mode. The picker already shows a pattern the user knows: swipe moves a highlight, every move is answered with a Morse identifier, a hold confirms. A home menu built the same way gives every mode one place to live and one way back (#41).

## What Changes

- **A home menu of modes.** A full-screen row of modes, left to right. For now there are two: **L = Learn** (the lessons, as today) and **S = Settings**. Each mode is announced by its International Morse letter, encoded with the English (International Morse) codec: L `· − · ·` (900 ms), S `· · ·` (500 ms). These are also the patterns of Arabic ل/س and Russian Л/С, and letters of the Spanish, French and German alphabets, so the identifiers are the same whatever language the user learns.
- **Navigation mirrors the picker.** The highlighted mode's letter plays once when the menu appears. A tap on a column highlights that mode; a swipe right/left of at least 50 px moves to the next/previous mode, wrapping around; a shorter drag replays the letter. Every touch is answered with the letter of the mode it leaves highlighted. A 1-second hold anywhere enters the highlighted mode: its letter plays, then 0.5 s of silence, then the mode opens. Gestures are ignored while it opens.
- **Learn** opens the lessons, which work exactly as today. **Settings** opens the language picker directly until the settings list (#45) exists.
- **BREAKING (gesture): a double shake returns to the menu** from any mode (the lessons, and the picker opened from Settings), with that mode highlighted. It replaces today's double shake to the language picker. On the menu itself a double shake is answered with the highlighted letter. A single shake in the lessons keeps its meaning (home: digits, 0); on the menu and in the picker it still does nothing.
- **Launch flow.** With a saved language the app opens on the menu with Learn highlighted, instead of going straight into the lessons. On the first launch (no saved language) it opens on the picker as today, and choosing a language opens the menu (Learn highlighted). Choosing a language in the picker opened from Settings saves it and returns to the menu (Settings highlighted); a double shake there returns without changing the language.
- **Picker texts.** Confirming a language no longer starts the lessons, so the helper hint becomes "Tap a language, then hold anywhere for 1 second to choose it" (plus "Double shake: back to the menu" when opened from Settings) and the screen-reader hint "Chooses <language> for the lessons".
- **For sighted helpers and screen readers.** Each menu column shows the letter, the mode's name and its Morse pattern; the highlighted one is drawn inverted, and a line at the bottom explains the gestures. Screen readers see one button per mode (activating it opens the mode directly) on a route named "Home menu".
- **Background.** While the menu is shown, shake detection runs only in the foreground. Leaving the foreground cancels a letter in progress; coming back replays the highlighted letter. The menu does not keep the screen on, like the picker.

## Accessibility

- No new gesture: tap, swipe, hold and double shake mean on the menu what they mean on the picker and in the lessons. The double shake becomes the one way back from anywhere, which is what the Phase 0 gate needs ("returns to the menu without help").
- The only new vibrations are two Morse letters, which the user can learn and use later, in line with the language identifiers being Morse letters. No signal is reused with a different meaning on the same screen.
- The menu tells the user where they are when it appears, on every gesture, after a double shake and when the app comes back to the foreground.
- Daily use costs one hold more than before (launch → menu → hold on L). Learn is highlighted at launch, so that hold is all it takes.

## Non-goals

- No Read, Talk or other modes, and no settings list: S opens the language picker directly until #45. The menu is built so those modes are a new entry each, not a redesign.
- No change to the lessons' gestures, signals or timings beyond where the double shake leads.
- No change to shake detection (threshold, cooldown, the double-shake window, `shake-gesture`) or to the event it emits; only where the double shake leads changes.
- No change to the first-launch picker's shakes: there is no menu to return to yet, so shaking still does nothing there.
- No remembering the highlighted mode between launches: every launch highlights Learn.
- No "menu opened" prosign or other new service signal (prosigns are #43).
- No wakelock on the menu.
- No shared chooser widget for the picker and the menu yet (see design.md).

## Capabilities

### New Capabilities

- `home-menu`: the home menu: its modes and their Morse identifiers, touch navigation and the hold that enters a mode, the double shake back to it, its lifecycle, the helper visuals and screen-reader semantics.

### Modified Capabilities

- `language-selection`: the picker is shown on the first launch and from Settings (no longer after a double shake), confirming a language opens the menu instead of the lessons, a double shake in the picker opened from Settings returns to the menu, a saved language makes the app open on the menu, and the screen-reader hint says the button chooses the language.
- `touch-surface`: the lesson screen is opened from the menu's Learn, and a double shake replaces it with the menu instead of the picker ("Double shake returns to the language picker" becomes "Double shake returns to the home menu").
- `app-lifecycle`: a trip to the background during the transition to the menu (no longer the picker) does not restart the lesson (the requirement is replaced to rename its scenario).
- `vibration-capability-gate`: the first screen with a saved language is the menu, the menu waits for detection like the picker, and the gate covers the routes the menu opens.
- `flutter-app-scaffold`: the first screen is the language picker or the home menu, no longer the lessons.
- `integration-testing`: the end-to-end tests go through the menu (double shake, vibration gate, language flow), and a new one walks the menu, Settings, the picker, Learn and the double shake back.

## Impact

- **UI** (`app/lib/ui/`): a new home menu surface and the list of modes; `app.dart` launches on the menu; `touch_surface.dart` returns to the menu on a double shake; `language_picker_surface.dart` learns whether it was opened from the menu, goes to the menu after a choice and handles the double shake from Settings. A small helper keeps shake detection running only in the foreground for the screens without a teaching loop.
- **Gestures**: no new event. The double-shake event keeps its name; its documentation says it now returns to the menu.
- **No change** to the teaching orchestrator, the session, the vibration service, the codecs, the Morse data or the stores. The menu plays its letters through `tactileCodecProvider` and `VibrationService.playTokens`, like the picker.
- **Tests**: widget tests for the menu (announce, tap, swipe, short drag, hold, the identifier finishing before the route changes, shakes, lifecycle, the vibration gate, semantics), updated picker, launch and double-shake tests, and an end-to-end test of the whole flow on a device, on the shared `E2EApp` harness, which gains a way to open the lessons from the menu. The end-to-end tests that launch with a saved language open the lessons from the menu first.
- **Docs**: README (the screens, gestures, signals, the menu section, the picker section), CHANGELOG, `openspec/config.yaml` context, `store/` texts that describe the double shake, `app/README.md`, the ROADMAP note about what the app opens on.
