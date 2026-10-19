## MODIFIED Requirements

### Requirement: Store listing information
A store info file SHALL be provided in `store/store-info.md` documenting: app category (Education or Accessibility), content rating (Everyone / 4+), supported languages (English, Arabic, Russian, Spanish), contact email, and any required declarations (e.g., no ads, no in-app purchases, no data collection).

#### Scenario: Store info file is complete
- **WHEN** the store listing is prepared
- **THEN** `store/store-info.md` contains all required metadata fields for both App Store and Google Play submissions

#### Scenario: Every taught language is listed
- **WHEN** the supported languages in `store/store-info.md` are reviewed
- **THEN** they list English, Arabic, Russian and Spanish, the languages offered in the in-app language picker
