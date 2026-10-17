## Why

`openspec validate --specs --strict` passed only 4 of the 29 main specs, and some specs no longer said what the app does ([#31](https://github.com/nullhtp/feel-you/issues/31)):

- 25 main specs had no `## Purpose` / `## Requirements` headers. 15 of them started with a delta header (`## ADDED Requirements` or `## MODIFIED Requirements`): a change's delta had been copied over the main spec instead of merged into it, and the requirements the delta didn't mention were lost.
- Strict validation also rejects requirement text over 500 characters. Ten requirements were longer, mostly because they carried a full letter table or a field list.
- `flutter-app-scaffold` still required an empty placeholder screen, and `openspec/config.yaml` told every proposal that no application code exists yet.

Replaying every archived change in commit order shows which requirements were lost. While checking them against the code, more statements turned out stale: the Arabic letter table had 6 wrong patterns (ص ض ظ ع ه ي), the English and Arabic word lists were the ones from before the 2026-03-01 word-list update, and the touch surface no longer decides about bottom-strip taps itself.

## What Changes

**Headers.** Every main spec gets `# <name> Specification`, a one-sentence `## Purpose` and `## Requirements`; leftover delta headers go.

**Lost requirements**, one decision each:

| Spec | Lost requirement | Decision |
|------|------------------|----------|
| `arabic-morse-data` | Arabic word Morse patterns data file | Dropped: renamed to *Arabic word Morse patterns data*, which this change brings up to date |
| `language-selection` | MorseLanguage enum | Restored, with Russian |
| `language-selection` | Language picker screen | Restored as the picker works today: tap, swipe and hold, usable without sight |
| `language-selection` | Language picker is non-persistent | Dropped: no longer true. Replaced by *The chosen language is saved* |
| `learning-session` | Session state tracks current phase | Restored unchanged |
| `learning-session` | Navigate to next letter | Restored as *Navigate to next item* |
| `learning-session` | Navigate to previous letter | Restored as *Navigate to previous item* |
| `learning-session` | Reset to letter A | Restored as *Reset to the first item of the level* |
| `learning-session` | State is exposed via Riverpod provider | Restored, with the saved language as the initial one |
| `level-system` | Ordered levels registry | Dropped: there is no top-level `levels` list; each alphabet defines its levels (*Levels defined within MorseAlphabet*) |
| `level-system` | Language-filtered level list | Dropped: renamed to *Language-filtered level list from registry* |
| `split-input` | Screen width provided to classifier | Restored: the width is now fed in on every touch |
| `word-morse-data` | MorseSymbol charGap value | Dropped: renamed to *MorseToken charGap representation* (`MorseSymbol` is gone) |
| `word-morse-data` | Word Morse patterns data file | Dropped: renamed to *Word Morse patterns data*, which this change brings up to date |

`split-input` was not in the issue's list: its *Screen width provided to classifier* was lost the same way, when `add-chargap-input-zone` rewrote the spec.

**Stale requirements** brought up to date:

- `learning-session`: *State is in-memory only* said the picker reappears on every launch. Replaced by *Level, position and phase are not saved*. *Session state tracks current letter* starts in the saved language.
- `flutter-app-scaffold`: *App displays a minimal placeholder screen* is replaced by *App starts on the language picker or the lessons*.
- `touch-surface`: the classifier, not the touch surface, turns a bottom-strip tap into a `BottomZoneAction`; only the first finger counts; a press taken over by the OS is cancelled. *App entry point integration* no longer calls the touch surface the only screen.
- `split-input`: bottom-strip taps are the classifier's job.
- `arabic-morse-data`: the six wrong letter patterns, the current word list, and the أ / ى aliases used to build word patterns.
- `word-morse-data`: the current English word list.
- `level-system`: `Level` has a `kind` and `wordPatterns`.
- `openspec/config.yaml`: the `context` describes the shipped app instead of a greenfield plan.

**Over-long requirements** are shortened by moving letter tables into scenarios and field lists into one sentence: `digit-morse-data`, `russian-morse-data`, `morse-alphabet-registry`, and the ones above.

## Non-goals

- No change to the app. The specs catch up with what is already shipped.
- No full audit of the specs that #31 did not name. Behaviour shipped without an OpenSpec change and still missing from the specs (the double shake in `shake-gesture`, background suspension, the vibration capability check and the no-vibration screen, screen-reader semantics) is left for [#32](https://github.com/nullhtp/feel-you/issues/32).

## Accessibility

Nothing changes for the user. The restored picker requirements state that every picker gesture is answered with a vibration, so the picker keeps working without sight.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `arabic-morse-data`, `digit-morse-data`, `russian-morse-data`: letter tables moved into scenarios; Arabic patterns, words and aliases corrected.
- `flutter-app-scaffold`: the app shell instead of a placeholder screen.
- `language-selection`: the language enum, the picker and the saved language.
- `learning-session`: phase, position navigation, reset, provider and what is saved.
- `level-system`: `Level` fields.
- `morse-alphabet-registry`: `MorseAlphabet` fields in one sentence.
- `split-input`: screen width and bottom-strip taps.
- `touch-surface`: what the touch surface forwards, the overlay, how the lesson screen is reached.
- `word-morse-data`: the current English words.

## Impact

- **Specs**: all 25 main specs without headers, and the 11 capabilities above.
- **OpenSpec config**: `openspec/config.yaml` `context`.
- **Code, builds, store files**: none.
