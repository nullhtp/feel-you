## ADDED Requirements

### Requirement: English store description
A store description in English SHALL be provided in `store/description-en.md`. It SHALL include a short description (max 80 characters for Google Play, max 30 characters subtitle for App Store) and a full description. The description SHALL communicate that the app teaches Morse code to deaf-blind users through vibration and touch.

#### Scenario: English description file exists
- **WHEN** the store metadata is inspected
- **THEN** `store/description-en.md` contains a short description and full description suitable for both App Store and Google Play

### Requirement: Arabic store description
A store description in Arabic SHALL be provided in `store/description-ar.md` with the same structure as the English description.

#### Scenario: Arabic description file exists
- **WHEN** the store metadata is inspected
- **THEN** `store/description-ar.md` contains an Arabic short description and full description

### Requirement: Store keywords
A keywords file SHALL be provided in `store/keywords.md` listing relevant search terms for both stores. Keywords SHALL cover: accessibility, deaf-blind, Morse code, vibration, communication, and learning.

#### Scenario: Keywords file exists
- **WHEN** the store metadata is inspected
- **THEN** `store/keywords.md` contains a list of relevant keywords in both English and Arabic

### Requirement: Store listing information
A store info file SHALL be provided in `store/store-info.md` documenting: app category (Education or Accessibility), content rating (Everyone / 4+), supported languages (English, Arabic), contact email, and any required declarations (e.g., no ads, no in-app purchases, no data collection).

#### Scenario: Store info file is complete
- **WHEN** the store listing is prepared
- **THEN** `store/store-info.md` contains all required metadata fields for both App Store and Google Play submissions

### Requirement: Privacy policy
A privacy policy document SHALL be provided in `store/privacy-policy.md`. It SHALL state that the app does not collect, store, or transmit any personal data. It SHALL list the device permissions used (vibration, accelerometer for shake detection, wake lock) and explain their purpose. The privacy policy MUST be suitable for both App Store and Google Play requirements.

#### Scenario: Privacy policy covers data collection
- **WHEN** the privacy policy is reviewed
- **THEN** it clearly states no personal data is collected, stored, or transmitted

#### Scenario: Privacy policy covers permissions
- **WHEN** the privacy policy is reviewed
- **THEN** it lists all device permissions used and explains each one's purpose in the app

#### Scenario: Privacy policy is store-compliant
- **WHEN** the privacy policy is submitted to App Store Connect or Google Play Console
- **THEN** it satisfies the minimum privacy policy requirements for both stores
