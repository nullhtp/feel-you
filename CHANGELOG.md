# Changelog

Notable changes to Feel You. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/). How to cut a release is described in [app/README.md](app/README.md#release).

## [Unreleased]

### Added

- Secure storage for the assistant's OpenRouter key, ahead of the cloud features: it is kept in the iOS Keychain or the Android Keystore, stays on the phone (not synced to iCloud, left out of Android backup and device transfer), is shown on the helper overlay only masked (`Cloud key: sk-or-...a1b2`) and is never logged. Deleting it plays a new *cloud off* signal, two 700 ms buzzes. There is no screen to enter the key yet ([#61](https://github.com/nullhtp/feel-you/issues/61)).
- Spanish: the letters A-Z and Ñ (`−−·−−`, after N, as in the Spanish alphabet), 20 everyday words and **Español** in the language picker, identified by Morse Ñ. The word list awaits a native speaker's review ([#91](https://github.com/nullhtp/feel-you/issues/91)).
- French: the letters A-Z, then À (`·−−·−`), Ç (`−·−··`), É (`··−··`) and È (`·−··−`) after Z, 20 everyday words and **Français** in the language picker, identified by Morse É. The word list awaits a native speaker's review ([#91](https://github.com/nullhtp/feel-you/issues/91)).
- German: the letters A-Z, then Ä (`·−·−`), Ö (`−−−·`) and Ü (`··−−`) after Z, 20 everyday words and **Deutsch** in the language picker, identified by Morse Ü. ß is not taught: it has no ITU code, and its extension code would be longer than the quiz marker `?`. The word list awaits a native speaker's review ([#91](https://github.com/nullhtp/feel-you/issues/91)).
- A contributing guide, a code of conduct, a security policy, issue and pull request templates, and a roadmap of seven phases tracked as GitHub milestones with epics.
- A quiz at the end of every level, one swipe right past its last item. It is announced with Morse `?`, plays random items the user has learned, and moves to a new item after each correct answer, so the user practises recognising Morse they did not choose.
- Learned items (each item answered correctly once in the lessons) are saved per language and level, so the quiz grows from one launch to the next. Every launch still starts at digit 0.
- The helper overlay shows how many items of the level are learned, and hides the quiz item until the user has answered.
- Each word is spelled letter by letter before it is drilled, so the user knows which word they are on without counting ([#8](https://github.com/nullhtp/feel-you/issues/8)).
- The chosen language is saved, so later launches skip the picker and go straight to the lessons.
- The language picker can be used without sight: it vibrates the highlighted language's identifier, and the user moves and chooses by touch.
- A double shake returns from a session to the language picker.
- A "No vibration motor" screen on devices that can't vibrate. Debug builds can continue past it.
- Success and error signals that differ by duration alone, for vibration motors without amplitude control.
- Screen-reader labels for the language picker, the lesson surface and the helper overlay.

### Changed

- The behaviour specs in `openspec/specs/` now describe what earlier commits shipped without an OpenSpec change: the double shake, background suspension, the vibration gate and its debug bypass, screen-reader labels, and the exact timings of the success, error and tap-feedback signals. They also no longer contradict the app ([#32](https://github.com/nullhtp/feel-you/issues/32)).
- Swiping right on the last item of a level opens the level's quiz instead of doing nothing.
- iPhone only: the iOS build no longer installs on iPad, which has no vibration motor.
- The minimum OS versions are now iOS 15 and Android 7.0 (API 24).
- Licensed under the MIT licence.
- Internal: text now reaches the vibration engine through a `TactileCodec`, with Morse as its first codec, so later modes (the reader, a braille codec) can play text without knowing it is Morse. Every vibration is unchanged ([#40](https://github.com/nullhtp/feel-you/issues/40)).

### Fixed

- On iOS, the pauses inside a Morse pattern vibrated too, so a letter or word felt like one continuous buzz.
- The teaching loop kept vibrating while the app was in the background.
- On some Android devices every tap counted as a dash, and the dot/dash halves didn't follow split screen or display size changes.
- System gestures (edge back, notification shade, an incoming call) could count as a tap or a swipe.
- A tap made just before a swipe, a shake or the end of the feedback signal was added to the next answer.
- The loop stopped vibrating after a swipe past the first or last item or level, or after a bottom-strip tap during playback.
- The first lesson pattern cut off the language identifier on Android.
- The "No vibration motor" screen didn't appear when motor detection finished after a language was chosen.

## [0.0.2] - 2026-03-24

### Added

- Russian Morse: digits, the 32-letter alphabet and 20 words.

## [0.0.1] - 2026-03-05

First test release, an Android APK on GitHub.

### Added

- English and Arabic Morse, each with a digits, a letters and a words level.
- Landscape-only lesson surface: a tap on the left half is a dot, on the right half a dash; a bottom strip submits the answer or marks a letter gap.
- A language picker and a companion overlay for sighted helpers.

The APKs attached to the 0.0.1 and 0.0.2 GitHub releases were built as version 1.0.0 (build 1); `pubspec.yaml` was not bumped for either of them.

[Unreleased]: https://github.com/nullhtp/feel-you/compare/v.0.0.2...HEAD
[0.0.2]: https://github.com/nullhtp/feel-you/compare/v0.0.1...v.0.0.2
[0.0.1]: https://github.com/nullhtp/feel-you/releases/tag/v0.0.1
