# vibration-capability-gate Specification

## Purpose
How the app finds out what the phone's vibration motor can do, refuses to run on a phone that cannot vibrate, and shows a sighted helper what was found.

## Requirements

### Requirement: Vibration capabilities are detected once per run
Once per run, without delaying the first frame, the app SHALL ask the device whether it has a vibration motor, whether the motor has amplitude control, and whether it can play custom patterns. An answer that is missing or fails SHALL be unknown, and an unknown capability SHALL be treated as present: only a definite "no" changes what the app does. Until the answers arrive, all three SHALL be treated as present.

#### Scenario: Answers are used as reported
- **WHEN** the device reports a motor without amplitude control that can play custom patterns
- **THEN** the app SHALL treat the motor and custom patterns as present and amplitude control as absent

#### Scenario: A failed question
- **WHEN** the question about amplitude control fails with an error
- **THEN** amplitude control SHALL be unknown, and treated as present
- **AND** the answers to the other two questions SHALL still be used

#### Scenario: Where the answers come from
- **WHEN** the app runs on Android or iOS
- **THEN** the motor and amplitude control SHALL be asked of the hardware through the app's own platform channel `feel_you/vibrator`
- **AND** custom patterns SHALL be asked of the `vibration` plugin, which answers yes on Android and asks Core Haptics on iOS
- **AND** so a motorless Android tablet, every iPad and the iOS simulator report no motor, and an Android emulator reports its virtual motor

#### Scenario: Other platforms
- **WHEN** the app runs anywhere else, such as a desktop test host
- **THEN** every capability SHALL be unknown

#### Scenario: Still checking
- **WHEN** the first frame is drawn before detection has finished
- **THEN** the language picker or the home menu SHALL be shown, as on a device with a motor

### Requirement: No screen runs without a vibration motor
On a device that definitely has no vibration motor, the No vibration screen SHALL replace every route of the app, including routes opened after launch (the home menu after a language is chosen or a double shake, the lessons and the picker opened from it). When detection reports no motor after a lesson has started, the teaching loop SHALL stop at once and the whole route stack SHALL be replaced. The picker and the menu SHALL wait for detection before they play their first identifier.

#### Scenario: No motor, language saved
- **WHEN** the app is launched with a saved language on a device without a motor
- **THEN** the No vibration screen SHALL be shown instead of the home menu
- **AND** no identifier SHALL be played, since the menu waits for detection, and no teaching loop SHALL run once detection has answered, though the lessons MAY have been opened from the menu before the answer arrived

#### Scenario: No motor, no language saved
- **WHEN** the app is launched without a saved language on a device without a motor
- **THEN** the No vibration screen SHALL be shown instead of the language picker
- **AND** no identifier SHALL be played, since the picker waits for detection

#### Scenario: Detection ends after the lesson started
- **WHEN** the lesson surface is running its loop and detection then reports no motor
- **THEN** the teaching loop SHALL stop
- **AND** the No vibration screen SHALL replace the lesson surface

#### Scenario: Detection ends after a route change
- **WHEN** detection reports no motor after the picker was replaced by the menu, after the menu was replaced by the lessons or by the picker, or after a double shake opened the menu again
- **THEN** the No vibration screen SHALL replace whichever route is shown, and any running loop SHALL stop

#### Scenario: A motor found later
- **WHEN** detection reports a motor after the lessons have started
- **THEN** the lessons SHALL keep running

#### Scenario: The picker waits for detection
- **WHEN** the language picker appears before detection has finished
- **THEN** it SHALL play the highlighted identifier only once detection has finished without reporting "no motor"

#### Scenario: The menu waits for detection
- **WHEN** the home menu appears before detection has finished
- **THEN** it SHALL play the highlighted mode's identifier only once detection has finished without reporting "no motor"

### Requirement: The No vibration screen explains why the app cannot run
The No vibration screen SHALL be black, with the heading "No vibration motor" and the text "This device cannot vibrate, so Feel You cannot work on it." followed on a new line by "Feel You communicates only through vibration. Please use a phone with a vibration motor.", in white and centred. Release and profile builds SHALL offer no way past it. For screen readers it SHALL be its own route.

#### Scenario: What the helper reads
- **WHEN** the No vibration screen is shown
- **THEN** it SHALL show the heading "No vibration motor" and the explanation

#### Scenario: Release builds
- **WHEN** the No vibration screen is shown in a release or profile build
- **THEN** it SHALL show no button, and no session SHALL be able to start

#### Scenario: Screen readers
- **WHEN** a screen reader is on and the No vibration screen is shown
- **THEN** the screen SHALL be announced as a route of its own, as a screen opened by the navigator is

### Requirement: Debug builds can bypass the gate
Debug builds SHALL add a button "Continue anyway (debug build)" to the No vibration screen, so developers can reach the lessons on the iOS simulator and on motorless test devices. Tapping it SHALL open the gate for the rest of the run, in memory only. The motor SHALL then count as unknown, the other two capabilities SHALL keep their detected values, and the app SHALL start over from its first screen.

#### Scenario: The button
- **WHEN** the No vibration screen is shown in a debug build
- **THEN** it SHALL show the button "Continue anyway (debug build)", with the screen-reader hint "Opens the language picker although nothing will vibrate"

#### Scenario: The gate stays closed until the button is tapped
- **WHEN** the No vibration screen is shown in a debug build and the button has not been tapped
- **THEN** no other screen SHALL be shown

#### Scenario: Tapping the button
- **WHEN** the button is tapped
- **THEN** the app SHALL show its first screen: the language picker when no language is saved, the home menu otherwise
- **AND** the success and error signals SHALL still follow the detected amplitude control

#### Scenario: The bypass is not saved
- **WHEN** the app is launched again after a bypass
- **THEN** the No vibration screen SHALL be shown again

### Requirement: The helper sees what the motor can do
The companion overlay SHALL show in its bottom-left corner a one-line readout of what the device reported, as `Vibration: <motor> · amplitude: <answer> · custom: <answer>`, with the motor as `OK`, `NONE` or `unknown` and each answer as `yes`, `no` or `unknown`. It SHALL read `Vibration: checking…` while detection runs. It SHALL be dim white, and amber when a capability is definitely missing or the gate is bypassed.

#### Scenario: Everything works
- **WHEN** the device reports a motor with amplitude control and custom patterns
- **THEN** the readout SHALL be `Vibration: OK · amplitude: yes · custom: yes`, in white at half opacity

#### Scenario: A capability is missing
- **WHEN** the device reports a motor without amplitude control
- **THEN** the readout SHALL be `Vibration: OK · amplitude: no · custom: yes`, in amber

#### Scenario: Detection fails
- **WHEN** every question fails
- **THEN** the readout SHALL be `Vibration: unknown · amplitude: unknown · custom: unknown`

#### Scenario: Detection still running
- **WHEN** the overlay is drawn before detection has finished
- **THEN** the readout SHALL be `Vibration: checking…`

#### Scenario: Gate bypassed
- **WHEN** a debug build bypasses the gate on a device without a motor
- **THEN** the readout SHALL still show the real answers, `Vibration: NONE · …`, followed by ` · gate bypassed (debug)`, in amber
