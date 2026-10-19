# cloud-key-storage Specification

## Purpose
Where and how the assistant's cloud (OpenRouter) key is kept on the phone: in the platform's secure storage, on this device only, never shown in full and never logged, and how deleting it is confirmed to the user.

## Requirements

### Requirement: The key is kept in the platform's secure storage
The app SHALL keep the cloud key only in the platform's secure storage: the iOS Keychain, and on Android a value encrypted with a key held in the Android Keystore. It SHALL NOT write the key to `SharedPreferences` (`UserDefaults` on iOS) or to any other app file. A saved key SHALL be read back on later launches until it is deleted.

#### Scenario: Key survives a restart
- **WHEN** a key is saved and the app is restarted
- **THEN** reading the key SHALL return the same key

#### Scenario: Nothing saved
- **WHEN** no key has been saved
- **THEN** reading the key SHALL return no key

#### Scenario: Key not in the app's preferences
- **WHEN** a key is saved
- **THEN** no value in the app's `SharedPreferences` (`UserDefaults` on iOS) SHALL contain the key

### Requirement: The key stays on this device
The saved key SHALL NOT leave the phone through the platform's sync, backup or transfer features. On iOS the Keychain item SHALL be readable only while the phone is unlocked, SHALL be tied to this device ("this device only"), and SHALL NOT be synchronizable. On Android the secure storage files SHALL be left out of cloud backup and device-to-device transfer (see `release-build-config`).

#### Scenario: iOS Keychain item attributes
- **WHEN** the key is saved on iOS
- **THEN** its Keychain item SHALL have the accessibility "when unlocked, this device only"
- **AND** it SHALL NOT be synchronizable through iCloud Keychain

#### Scenario: Restored to another iPhone
- **WHEN** a backup of the iPhone is restored to another iPhone
- **THEN** the app on the other iPhone SHALL have no key

#### Scenario: Restored to another Android phone
- **WHEN** the app's data is restored from a cloud backup or transferred to another Android phone
- **THEN** the app there SHALL have no key
- **AND** the saved language and learned items SHALL be restored as before

### Requirement: A cloud key is a single printable token
Input SHALL be trimmed of surrounding whitespace and accepted as a key only if it is then 1 to 512 characters long and every character is printable ASCII other than a space (`!` to `~`). Input that is not accepted SHALL NOT be saved, and the rejection SHALL NOT contain the input.

#### Scenario: Pasted key with a line break
- **WHEN** the input is `  sk-or-v1-abc` followed by a line break
- **THEN** the key SHALL be `sk-or-v1-abc`

#### Scenario: Empty input
- **WHEN** the input is empty or only whitespace
- **THEN** it SHALL be rejected

#### Scenario: Space or non-ASCII character inside
- **WHEN** the input contains a space, a tab or a non-ASCII character between other characters
- **THEN** it SHALL be rejected

#### Scenario: Too long
- **WHEN** the input is 513 printable ASCII characters
- **THEN** it SHALL be rejected
- **AND** 512 such characters SHALL be accepted

### Requirement: Masked form of the key
Wherever the app shows the key it SHALL show only its masked form: `sk-or-` when the key starts with it, then `...`, then the key's last 4 characters. The last 4 characters SHALL be shown only when at least 12 characters, not counting the `sk-or-` prefix, stay hidden; otherwise the masked form SHALL end at `...`. A key that does not start with `sk-or-` SHALL show no prefix.

#### Scenario: OpenRouter key
- **WHEN** the key is `sk-or-v1-` followed by 60 hexadecimal characters ending in `a1b2`
- **THEN** the masked form SHALL be `sk-or-...a1b2`

#### Scenario: Shortest OpenRouter key with its last characters shown
- **WHEN** the key is `sk-or-` followed by 16 characters ending in `a1b2`
- **THEN** the masked form SHALL be `sk-or-...a1b2`
- **AND** with 15 characters after `sk-or-` it SHALL be `sk-or-...`

#### Scenario: Other key
- **WHEN** the key is `custom-key-0123456a1b2` (22 characters, no `sk-or-` prefix)
- **THEN** the masked form SHALL be `...a1b2`

#### Scenario: Short other key
- **WHEN** the key has 15 characters and does not start with `sk-or-`
- **THEN** the masked form SHALL be `...`

### Requirement: The key is never logged
The app SHALL NOT write the key, beyond its masked form, to the console, the system log or an error message. Turning a key value into text SHALL give its masked form. Failures of the secure storage SHALL be logged and reported without the key or the stored value.

#### Scenario: Key turned into text
- **WHEN** a key value is turned into a string, for example inside a log message
- **THEN** the string SHALL contain the masked form
- **AND** it SHALL NOT contain the key

#### Scenario: Storage failure
- **WHEN** saving, reading or deleting the key fails
- **THEN** the logged message and the error given to the caller SHALL NOT contain the key or any stored value

### Requirement: The current key is observable
The app SHALL expose the current key, or none, to the rest of the app. It SHALL read it from the secure storage once per run, when first needed, and update it as soon as the key is saved or deleted. When the secure storage cannot be read, the current key SHALL be none for that run, and the app SHALL keep working offline.

#### Scenario: Save updates the current key
- **WHEN** a key is saved
- **THEN** the current key SHALL be the saved key without a restart

#### Scenario: Storage cannot be read
- **WHEN** reading the secure storage fails at launch
- **THEN** the current key SHALL be none
- **AND** the language picker and the lessons SHALL work as usual

#### Scenario: Failed save
- **WHEN** saving a key fails
- **THEN** the caller SHALL get an error
- **AND** the current key and the stored key SHALL stay as they were

### Requirement: Deleting the key plays the cloud-off signal
Deleting the key SHALL remove it from the secure storage, set the current key to none, and then play the cloud-off signal, so the user feels that the cloud is off. Deleting when no key is saved SHALL also play the signal. When the deletion fails, the key SHALL stay, the caller SHALL get an error, and no signal SHALL play.

#### Scenario: Delete a saved key
- **WHEN** a key is saved and it is deleted
- **THEN** reading the key SHALL return no key
- **AND** the current key SHALL be none
- **AND** the cloud-off signal SHALL play once

#### Scenario: Delete with no key saved
- **WHEN** no key is saved and the key is deleted
- **THEN** the cloud-off signal SHALL play once

#### Scenario: Failed deletion
- **WHEN** deleting the key fails
- **THEN** the caller SHALL get an error
- **AND** the current key SHALL stay as it was
- **AND** no cloud-off signal SHALL play
