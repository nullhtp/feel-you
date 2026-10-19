## MODIFIED Requirements

### Requirement: The chosen language is saved
Starting a language in the picker SHALL save it on the device (`SharedPreferences`, key `selected_language`) for the next launch. A launch that finds a saved language SHALL skip the picker and start the session in that language. Apart from the learned items (see `learned-items`), the language SHALL be the only setting saved. Saving is best effort: when the storage cannot be loaded or written, the app SHALL still run, and the picker SHALL appear again on the next launch.

#### Scenario: Next launch skips the picker
- **WHEN** the user started Arabic in the picker and the app is restarted
- **THEN** the lesson surface SHALL open in Arabic, at the digits level on 0, without the picker

#### Scenario: Picker starts on the saved language
- **WHEN** the picker is reopened with a double shake after Russian was started
- **THEN** Russian SHALL be highlighted when the picker appears

#### Scenario: Unknown stored value
- **WHEN** the stored value is not the name of a `MorseLanguage`
- **THEN** it SHALL be treated as no saved language, and the picker SHALL appear

#### Scenario: Storage unavailable
- **WHEN** the platform storage cannot be loaded at launch
- **THEN** the choice SHALL be kept in memory for the current run only, and the picker SHALL appear on every launch
