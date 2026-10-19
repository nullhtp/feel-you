## Context

See proposal.md for why. The relevant current state:

- **Screens.** `LaunchScreen` (in `app.dart`) shows `LanguagePickerSurface` when `launchLanguageProvider` is null and `TouchSurface` otherwise. The picker replaces itself with the lessons after a hold; `TouchSurface` replaces itself with the picker on a double shake. Every switch is a `pushReplacement`, so the navigator never holds more than one screen, and `VibrationGate` (above the navigator) swaps all of it for `NoVibrationScreen` on a device without a motor.
- **The picker pattern.** `LanguagePickerSurface` uses Flutter's own recognizers, not the lessons' `GestureClassifier`: a `HorizontalDragGestureRecognizer` (50 px threshold, measured from touch-down), a 1-second `LongPressGestureRecognizer`, and a `GestureDetector` per column for taps. It encodes each language's identifier letter with that language's codec (`tactileCodecProvider`) and plays it with `VibrationService.playTokens`, once after `vibrationCapabilitiesProvider` resolves, ignores everything while a language starts (`_started`), and changes the route only after the identifier has finished plus `TeachingTimingConfig.postFeedbackPause` (issue #28). It has no wakelock and no lifecycle handling, and it never reads the shake detector.
- **Shakes.** `ShakeDetector` emits `Home` for every shake and `ChangeLanguage` for the second shake of a double shake (`shake-gesture`). `TeachingOrchestrator.start()` resumes detection and `stop()` / `stopFromDispose()` pause it, so today shakes are only detected while the lessons run. `TouchSurface` listens for `ChangeLanguage` itself, ignores it while the loop is stopped, and keeps `_leaving` so a resume during the route transition does not restart the loop.
- **Wakelock.** `TouchSurface` enables it on mount and on resume, and disables it on dispose and in the background. `WakelockPlus` is a global on/off switch, not reference counted, and the outgoing route is disposed only after the incoming one has mounted (when the transition ends).
- **Landed before this change.** #32 specified the double shake (`shake-gesture`, `touch-surface`), the background (`app-lifecycle`) and the gate (`vibration-capability-gate`), and added the `E2EApp` end-to-end harness. #40 put a `TactileCodec` between text and vibration (`MorseCodec`, `tactileCodecProvider`, `playTokens`). #91 took the picker to six languages (English, Arabic, Russian, Spanish, French, German).

## Goals / Non-Goals

**Goals:**
- One hub that later modes (#44 Read, #51 Talk, #45 Settings list) join by adding an entry, without touching the menu's gesture code.
- Behave exactly like the picker wherever the two overlap, so nothing new has to be learned.
- Keep the lessons, the orchestrator, the session and the vibration service unchanged.

**Non-Goals:**
- A navigation framework or named routes. Three screens and `pushReplacement` are enough.
- Moving shake-detection ownership out of the orchestrator (see decision 5).

## Decisions

### 1. Modes are an enum; the menu maps each to its screen with an exhaustive switch

`HomeMenuMode` (`lib/ui/home_menu_mode.dart`) is an enum whose order is the menu's order. Each value carries its letter, its display name and its screen-reader hint; `HomeMenuMode.identifierLanguage` (English) names the codec that plays the letters. `HomeMenuSurface` builds a mode's screen with a `switch` over the enum:

```dart
Widget _screenFor(HomeMenuMode mode) => switch (mode) {
  HomeMenuMode.learn => const TouchSurface(),
  HomeMenuMode.settings => const LanguagePickerSurface(fromMenu: true),
};
```

Adding R or T is a new enum value (its place in the list is its place on the screen) plus one `case`; the compiler points at the switch. #45 changes only the `settings` case.

Alternative: *a list of item objects holding a `WidgetBuilder`.* Rejected for now: the enum keeps the data testable without widgets, gives the screens that return to the menu a value to pass back (decision 3), and the exhaustive switch makes a forgotten screen a compile error.

### 2. Identifiers are International Morse letters, independent of the lesson language

The menu encodes L and S with the English codec, `tactileCodecProvider(MorseLanguage.english)`, plays them with `playTokens` and writes the helper's pattern with the codec's `describe`, as the picker does with each language's own codec. The session language's codec is not used: it may not have the Latin letter (the Arabic and Russian codecs reject `L`). Arabic ل and Russian Л have the same pattern as L, and س and С the same as S, and both are letters of Spanish, French and German, so a user learning any of the six languages feels a letter they will learn. A unit test checks this with each language's codec, and that the identifiers of all modes differ. Future letters are checked the same way: R (`· − ·`) is also ر/Р, T (`−`) is also ت/Т.

The identifiers are only played on the menu, which never plays anything else, so they cannot be confused with the language identifiers (E, ع, Р, Ñ, É, Ü on the picker) or with lesson items, which repeat every 3 s.

### 3. Routes stay one-at-a-time; the menu is told which mode to highlight

Every switch remains a `pushReplacement`. `HomeMenuSurface({HomeMenuMode highlighted = HomeMenuMode.learn})`. `TouchSurface` returns with `learn`; the picker opened from Settings returns with `settings` (after a choice or a double shake); `LaunchScreen` and the first-launch picker use the default, `learn`.

Alternative: *the menu as the root route, modes pushed on top and a double shake popping back.* Rejected: it keeps two live screens (the menu's shake listener and the lesson's would both run), `VibrationGate` already restarts the navigator from its first route, and the existing specs promise one screen at a time.

### 4. The menu copies the picker's gesture code instead of sharing it

`HomeMenuSurface` has the same structure as `LanguagePickerSurface` (raw recognizers, per-column tap, `_entering` like `_started`, the announce after capability detection, the wait for the identifier plus `postFeedbackPause`). The picker is changed only where its behaviour changes (decision 7).

Alternative: *extract a generic chooser widget used by both.* Deferred: #91 is changing the picker in parallel and a refactor would collide with it; the settings list (#45) will be the third user and shows what the shared part really is. Extracting it then is a follow-up.

### 5. Shake detection on screens without a teaching loop: a small foreground helper

The orchestrator keeps pausing detection when the lessons stop and resuming it when they start. The menu and the picker opened from Settings use `ForegroundShakeListener` (`lib/ui/foreground_shake_listener.dart`), which:

- resumes detection and subscribes when the screen mounts (the lessons have just paused it);
- pauses detection when the app leaves the foreground (`inactive`, `hidden`, `paused`, `detached`, as `TouchSurface` does) and resumes it on `resumed`, calling the screen's `onBackground` / `onForeground`;
- forwards events only while the app is in the foreground;
- on `handOver()` (called right before the screen navigates away) stops forwarding and stops resuming: the next screen owns detection from then on;
- on dispose, pauses detection only if it never handed over (removed by `VibrationGate`, or a test tearing the tree down), because after a hand-over the next screen has already mounted and may have resumed it.

Ordering, for the transitions that matter: lessons → menu: `stop()` pauses, the menu mounts and resumes. Menu → lessons: the menu hands over, `TouchSurface` starts the loop (resume, a no-op), the menu's dispose leaves it alone. Menu → picker → menu: each hands over, each new screen resumes.

Alternative: *move pause/resume out of the orchestrator into one app-level owner.* Better in the long run, but it changes the orchestrator's contract, which `app-lifecycle` and `touch-surface` now specify ("shake detection SHALL be paused until the loop starts again"), and its tests. Kept as a follow-up.

### 6. Shakes on the menu: a double shake replays, a single shake does nothing

The double shake is the global "take me to the menu" gesture, so on the menu it answers "you are here, on X" with the highlighted identifier. A double shake also emits `Home` for its first shake; ignoring `Home` on the menu means the double shake is answered exactly once, not twice, and a single shake keeps its only meaning, the lessons' home. This also matches the picker, where a single shake does nothing.

Alternative: *answer every shake with the identifier.* Rejected: a double shake would then vibrate the identifier twice, about a second apart.

### 7. Picker changes: `fromMenu`, the destination after a choice, the double shake

`LanguagePickerSurface({bool fromMenu = false})`:
- After a choice it saves the language and selects it on the session as today, then replaces itself with `HomeMenuSurface(highlighted: fromMenu ? settings : learn)` instead of `TouchSurface`.
- Only when `fromMenu` does it listen for shakes (decision 5): `ChangeLanguage` replaces it with the menu (Settings highlighted) at once, without saving or selecting anything. It is ignored while a language starts. The first-launch picker never reads the shake detector, so shakes do nothing there, as today: there is no menu to return to before a language is chosen.
- Texts: the hint becomes "Tap a language, then hold anywhere for 1 second to choose it" (with ". Double shake: back to the menu" when `fromMenu`), and the screen-reader hint "Chooses <English name> for the lessons".

### 8. Where the lessons start

Entering Learn does not touch the session. The session is at digit 0 after a launch and after `selectLanguage`, and a double shake out of the lessons goes through `Home` first, so in practice Learn always opens on digit 0, as the lessons did before. Nothing new is remembered.

### 9. Lifecycle: no wakelock, cancel in the background, replay on return

- **No wakelock**, like the picker. The menu is a short stop between modes, every touch resets the system's idle timer, and a wakelock would be released anyway by the outgoing `TouchSurface`'s `dispose`, which runs after the menu has mounted.
- **Leaving the foreground** cancels a vibration in progress (`VibrationService.cancel`) and pauses detection.
- **Coming back** replays the highlighted identifier (not while a mode is opening), so a user whose screen locked, or who took a call, feels where they are, as the lessons replay their item.

### 10. Helper visuals and semantics

Each column: the letter (large, bold), the name and the pattern in the overlay's notation (`·`, `—`), drawn inverted when highlighted, with the hint line at the bottom; all in `ExcludeSemantics` / `IgnorePointer` where the picker uses them. Screen readers get a container that names the route ("Home menu") and one button per mode (label = name, hint, `selected`), whose activation enters the mode directly, as the picker's buttons choose a language directly.

### 11. The double-shake event keeps its name

`ChangeLanguage` now means "back to the menu". Renaming it touches the shake detector, the orchestrator, a dozen tests and the specs #32 wrote (`shake-gesture`, `gesture-recognition`, `teaching-loop`), which say what the detector emits, not where it leads. Only its documentation changes here; a rename (e.g. `OpenMenu`) is a follow-up.

### 12. End-to-end tests open the lessons from the menu

The `E2EApp` harness launches the whole app with a saved language or none; with a saved language the app now lands on the menu. `E2EApp.openLessons` holds on the menu (Learn is highlighted at launch) and waits for the lesson surface, and every end-to-end test that started on the lessons calls it first, so what they assert about the lessons is unchanged. `doubleShake`, `holdToConfirm` and the menu's identifiers (`menuLearn`, `menuSettings`) are shared there too. The menu's own end-to-end test runs on the same harness, with the real shake detector fed accelerometer readings, so the suite has one way to launch the app.

### Vibration sequences

Default timing (`MorseTimingConfig`: dot 100 ms, dash 300 ms, 100 ms between elements; `TeachingTimingConfig.postFeedbackPause` 500 ms):

| Moment | Vibration | Duration |
|---|---|---|
| Menu appears (launch, after a choice, after a double shake), app returns to the foreground | highlighted identifier, once | L `· − · ·` 900 ms, S `· · ·` 500 ms |
| Tap, swipe (≥ 50 px), shorter drag | identifier of the mode left highlighted | 900 / 500 ms |
| Hold 1 s | identifier, then silence, then the mode opens | L 900 + 500 ms, S 500 + 500 ms |
| Double shake on the menu | identifier on the second shake; nothing on the first | 900 / 500 ms |
| Single shake on the menu | nothing | |
| Double shake in the lessons | first shake: the lesson goes home (digit 0 `− − − − −` starts again); second: the loop stops, the menu plays L | |
| Double shake in the picker from Settings | second shake: the menu plays S | |
| App leaves the foreground | vibration cancelled | |

```
launch (English saved):
  menu   · − · ·                                   (L: Learn highlighted)
  swipe  · · ·                                     (S)
  hold   · · ·  ...0.5 s...                        (S again, then Settings opens)
  picker ·                                         (E: the saved language)
  tap Русский · − ·                                (Р)
  hold   · − ·  ...0.5 s...                        (Russian saved, back to the menu)
  menu   · · ·                                     (S: Settings highlighted)
  swipe  · − · ·                                   (L)
  hold   · − · ·  ...0.5 s...                      (Learn opens)
  lesson − − − − −  ...3 s...  − − − − −  ...      (Russian digit 0)
  shake, ~1 s, shake:
         − − − − −   (first shake: home)   then the menu: · − · ·
```

## Risks / Trade-offs

- [Users who learned "double shake = change language" now land on the menu] → changing the language is S, hold, as easy to reach; README and CHANGELOG say so. Phase 1 has few users.
- [Launch no longer goes straight into the lessons] → Learn is highlighted at launch, so one hold opens the lessons; the menu's L tells the user where they are.
- [The screen can sleep on the menu] → every touch resets the timer, and the menu announces itself when the app comes back. Revisit if testers get lost (open question for the user).
- [Duplicated gesture code in the picker and the menu] → deliberate (decision 4), with the extraction planned for #45.
- [Shake ownership is split between the orchestrator and the helper] → the hand-over rule is documented on the helper, and widget tests cover each transition and the background.
- [The accelerometer now runs while the menu is shown] → as during the lessons; paused in the background.
- [A vigorous second shake lasting more than a second may emit `Home` on the menu] → ignored there (decision 6).

## Migration Plan

No data migration: the saved language and learned items are read as before. A user who updates simply opens on the menu. Rolling back restores the old flow; nothing new is stored.

## Open Questions

- Should the menu keep the screen on like the lessons (needs a reference-counted wakelock, decision 9)? Decide after the first blindfold tests (#50).
- Should the first-launch picker answer a double shake with the highlighted language's identifier, so the gesture is never unanswered? Kept silent for now, as before.
