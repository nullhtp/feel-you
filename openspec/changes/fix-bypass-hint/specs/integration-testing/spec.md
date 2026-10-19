## MODIFIED Requirements

### Requirement: Vibration gate end-to-end test
An end-to-end test SHALL check `vibration-capability-gate` on the device: with the device's own answers on the iOS simulator, which has no motor, the No vibration screen replaces the picker and the home menu, and the debug button, whose screen-reader hint names no screen, opens the first screen. With a detection that ends late, the No vibration screen SHALL replace a route opened after launch and stop its loop.

#### Scenario: iOS simulator
- **WHEN** the app is launched on the iOS simulator, with or without a saved language
- **THEN** the No vibration screen SHALL be shown, and neither the picker, the menu nor the lessons, and no identifier SHALL be played

#### Scenario: Debug bypass
- **WHEN** the No vibration screen is shown, with or without a saved language, and the debug button is tapped
- **THEN** the button SHALL have been a screen-reader button with the hint "Continues into the app although nothing will vibrate"
- **AND** the app's first screen SHALL be shown, and with a saved language the menu's Learn SHALL open the lessons

#### Scenario: Late detection after a route change
- **WHEN** a language is started in the picker and Learn entered on the menu before detection ends, and detection then reports no motor
- **THEN** the No vibration screen SHALL replace the lessons and the teaching loop SHALL be stopped
