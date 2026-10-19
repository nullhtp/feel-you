## MODIFIED Requirements

### Requirement: Debug builds can bypass the gate
Debug builds SHALL add a button "Continue anyway (debug build)" to the No vibration screen, so developers can reach the lessons on the iOS simulator and on motorless test devices. Tapping it SHALL open the gate for the rest of the run, in memory only. The motor SHALL then count as unknown, the other two capabilities SHALL keep their detected values, and the app SHALL start over from its first screen.

#### Scenario: The button
- **WHEN** the No vibration screen is shown in a debug build, with or without a saved language
- **THEN** it SHALL show the button "Continue anyway (debug build)", with the screen-reader hint "Continues into the app although nothing will vibrate"
- **AND** the hint SHALL name no screen, since the first screen is the language picker or the home menu depending on the saved language

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
