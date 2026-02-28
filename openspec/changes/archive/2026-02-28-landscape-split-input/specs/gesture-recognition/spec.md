## MODIFIED Requirements

### Requirement: Configurable gesture timing thresholds
The system SHALL define gesture timing through a configuration object (`GestureTimingConfig`) with the following defaults: reset hold minimum 2000ms, silence timeout 1000ms, minimum swipe distance 50px, minimum swipe velocity 200px/s. All values SHALL be overridable at construction time. The `dotMaxDuration` and `dashMaxDuration` parameters SHALL be removed since dot/dash classification is now position-based.

#### Scenario: Default timing values
- **WHEN** a `GestureTimingConfig` is created with no arguments
- **THEN** reset min is 2000ms, silence timeout is 1000ms, min swipe distance is 50px, and min swipe velocity is 200px/s

#### Scenario: Custom timing values
- **WHEN** a `GestureTimingConfig` is created with silence timeout=1500ms
- **THEN** that custom value is used and all other values remain at defaults

#### Scenario: No dot/dash duration parameters exist
- **WHEN** a developer inspects `GestureTimingConfig`
- **THEN** there SHALL be no `dotMaxDuration` or `dashMaxDuration` properties

## REMOVED Requirements

### Requirement: Classify tap as dot
**Reason**: Dot classification is no longer duration-based. Dots are now determined by tap position (left half of screen) as defined in the `split-input` capability.
**Migration**: Use position-based classification from `split-input` spec instead.

### Requirement: Classify tap as dash
**Reason**: Dash classification is no longer duration-based. Dashes are now determined by tap position (right half of screen) as defined in the `split-input` capability.
**Migration**: Use position-based classification from `split-input` spec instead.
