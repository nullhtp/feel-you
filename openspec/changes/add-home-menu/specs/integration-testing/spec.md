## MODIFIED Requirements

### Requirement: End-to-end tests run the real app on a device
The end-to-end tests below SHALL launch `FeelYouApp` on a device or simulator with its real screens, gesture classifier, teaching loop and plugins, and drive it with pointer events. They SHALL replace only what a simulator cannot provide or a test must fix: the saved language, the timing configs, the vibration output (recorded, or caught at the plugin's platform channel), the motor's answers where a test needs a particular motor, and the accelerometer readings.

#### Scenario: What runs for real
- **WHEN** an end-to-end test runs
- **THEN** the lesson surface, the home menu, the language picker, the vibration gate, the classifier, the orchestrator, the session and the wakelock plugin SHALL be the app's own

### Requirement: Double shake end-to-end test
An end-to-end test SHALL feed the app's shake detector accelerometer readings in real time, with the default `ShakeConfig`, and check the double-shake window: two shakes 0.9 s apart open the home menu, on Learn, which plays Morse L; two shakes 1.8 s apart only go home twice, and the lesson stays.

#### Scenario: Inside the window
- **WHEN** the lesson, opened from the menu, runs in Russian and the phone is shaken twice, 0.9 s apart
- **THEN** the home menu SHALL replace the lesson surface with Learn highlighted, the teaching loop SHALL be stopped, the session SHALL be on digit "0" in Russian, and Morse "L" SHALL be played

#### Scenario: Outside the window
- **WHEN** the phone is shaken twice, 1.8 s apart
- **THEN** the lesson surface SHALL stay, on digit "0", with the loop running

### Requirement: Vibration gate end-to-end test
An end-to-end test SHALL check `vibration-capability-gate` on the device: with the device's own answers on the iOS simulator, which has no motor, the No vibration screen replaces the picker and the home menu, and the debug button opens the first screen. With a detection that ends late, the No vibration screen SHALL replace a route opened after launch and stop its loop.

#### Scenario: iOS simulator
- **WHEN** the app is launched on the iOS simulator, with or without a saved language
- **THEN** the No vibration screen SHALL be shown, and neither the picker, the menu nor the lessons, and no identifier SHALL be played

#### Scenario: Debug bypass
- **WHEN** the debug button is tapped on the No vibration screen
- **THEN** the app's first screen SHALL be shown, and with a saved language the menu's Learn SHALL open the lessons

#### Scenario: Late detection after a route change
- **WHEN** a language is started in the picker and Learn entered on the menu before detection ends, and detection then reports no motor
- **THEN** the No vibration screen SHALL replace the lessons and the teaching loop SHALL be stopped

### Requirement: Language flow end-to-end test
An end-to-end test SHALL launch the app with no saved language and, for each language added after English, Arabic and Russian, drive it from the language picker to a learned letter and word: choose the language, open Learn on the home menu, learn a letter only that language has, then hear a word spelled and answer it. Vibration SHALL be recorded, and the motor answered at the platform channels.

#### Scenario: One flow per new language
- **WHEN** the flows run
- **THEN** they SHALL cover, with the identifier letter, the letter and the word:
  - Spanish: Ñ, Ñ, BAÑO
  - French: É, É, ÇA
  - German: Ü, Ö, MÜDE

#### Scenario: Choosing the language
- **WHEN** the picker opens and the user taps the language's column
- **THEN** its identifier SHALL be played, encoded with the language's codec
- **AND** after a 1 s hold the language SHALL be saved and the home menu SHALL open on Learn
- **AND** after a 1 s hold on the menu, Morse L SHALL be played and the lesson SHALL open on digit "0", in that language

#### Scenario: Learning the language's own letter
- **WHEN** the user swipes up to the letters and right to the letter
- **THEN** its pattern SHALL play, and tapping it back SHALL play the success signal and make it a learned item, saved

#### Scenario: Spelling and answering a word
- **WHEN** the user swipes up to the words and right to the word
- **THEN** its letters SHALL be played one at a time, then the word with its letter gaps
- **AND** tapping it back with a bottom-strip tap between letters SHALL play the success signal and make it a learned item

## ADDED Requirements

### Requirement: Home menu flow end-to-end test
An end-to-end test SHALL launch the app on the end-to-end harness (real screens, real shake detector fed accelerometer readings, the motor answered at the platform channels, vibration recorded) and drive it with real touches and shakes from launch through the home menu, Settings, the language picker, Learn and the double shake back to the menu, asserting every vibration call in order. A second test SHALL cover the first launch.

#### Scenario: Saved language, through Settings and Learn and back
- **WHEN** the app is launched with English saved, and the user swipes to Settings, holds, taps Russian and holds, swipes to Learn and holds, then double-shakes in the lesson
- **THEN** the vibrations SHALL be, in order: L (menu appears), S (swipe), S (hold), E (picker appears), Р (tap), Р (hold), S (menu appears), L (swipe), L (hold), digit 0 (the lesson starts), a cancel and digit 0 again (first shake: home), a cancel (second shake: the lesson stops), L (menu appears)
- **AND** Russian SHALL be saved, the menu SHALL end with Learn highlighted, and a further double shake on the menu SHALL play L once

#### Scenario: First launch, from the picker to the menu
- **WHEN** the app is launched with no saved language and the user holds on the picker
- **THEN** the vibrations SHALL be, in order: E (picker appears), E (hold), L (menu appears)
- **AND** English SHALL be saved and the menu SHALL show Learn highlighted
