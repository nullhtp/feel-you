## ADDED Requirements

### Requirement: Cloud key end-to-end test
An end-to-end test SHALL run the app with the real secure storage plugin, as `main` injects it, and check `cloud-key-storage` on the device: a saved key is read back by the platform and after a restart, the overlay and its summary show it only masked, the app's preferences never contain it, and deleting it plays the cloud-off signal and leaves no key. The test SHALL remove the key from the secure storage before and after it runs.

#### Scenario: Save, restart and delete
- **WHEN** a key is saved, the app is restarted and the key is deleted, with the vibration recorded
- **THEN** a new store SHALL read the key back before the deletion and none after it
- **AND** the overlay SHALL show `Cloud key: sk-or-...` with the key's last 4 characters, then `Cloud key: none`
- **AND** no preference value SHALL contain the key
- **AND** the cloud-off signal SHALL be recorded once

#### Scenario: Cloud-off reaches the plugin on every motor
- **WHEN** the key is deleted with the app's own vibration service, once on a motor with amplitude control and once without
- **THEN** the `vibration` plugin SHALL be sent `[0, 700, 300, 700]` ms with the intensities `[0, 255, 0, 255]` both times
