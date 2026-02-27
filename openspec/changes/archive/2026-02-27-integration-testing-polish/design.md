## Context

Phase 1 feature code is complete across four layers: Morse data model, gesture recognition, vibration engine, session state, teaching orchestrator, and touch UI. Each layer has unit/widget tests (~100+ test cases), but no test exercises the full provider-wired flow end-to-end. Timing constants live in three separate config classes (`GestureTimingConfig`, `MorseTimingConfig`, `TeachingTimingConfig`), each with sensible defaults, but there is no single reference documenting what to adjust during real-device tuning.

## Goals / Non-Goals

**Goals:**
- Validate the full learning flow as an integration test: app starts → orchestrator plays letter A → user taps Morse input → feedback vibration → swipe to next letter → repeat
- Cover edge cases at the integration level: rapid swipes, double taps during playback, quick input-then-navigate sequences
- Create a centralized tuning reference that maps every timing constant to its config class, documents its role, and marks values needing real-device validation
- Verify both platforms produce clean release builds

**Non-Goals:**
- Calibrating actual timing values (requires physical devices)
- Testing background/foreground lifecycle transitions
- Release signing or store preparation
- Modifying any existing feature behavior

## Decisions

### 1. Integration test architecture: mock vibration, real providers

**Decision:** Integration tests will use Flutter's `integration_test` package with a real Riverpod provider graph, but override `VibrationService` with a recording mock. The mock captures all vibration calls (pattern, success, error, cancel) for assertion without triggering device haptics.

**Why:** The `GestureClassifier`, `SessionNotifier`, and `TeachingOrchestrator` are the critical wiring to validate. Vibration is a device-only side effect — mocking it lets tests run on any host and verify the correct sequences were requested.

**Alternatives considered:**
- Full device vibration testing: Requires physical device, can't assert on haptic output programmatically. Deferred to manual tuning.
- Pure widget tests in `test/`: Already exist for individual layers. Integration tests add value by using the real provider graph and testing cross-layer interactions.

### 2. Simulating user input via GestureClassifier directly

**Decision:** Integration tests will inject `RawTouchEvent` (TouchDown/TouchUp) directly into the `GestureClassifier` rather than using `WidgetTester.tap()` or pointer simulation. For swipes, tests will inject appropriately-spaced touch events with position deltas exceeding the swipe threshold.

**Why:** The `TouchSurface` widget forwards pointer events to the classifier, which is already tested in `touch_surface_test.dart`. Testing the classifier → orchestrator → session pipeline directly is more reliable and deterministic than simulating screen coordinates. Timing can be precisely controlled.

**Alternatives considered:**
- `WidgetTester` pointer simulation: Works but couples tests to screen geometry and pointer pipeline, adding fragility without testing new code. The classifier is the real boundary.

### 3. Timing in tests: fast configs with controlled async

**Decision:** Integration tests will override all timing configs with very short durations (e.g., 1-10ms) to keep tests fast. Tests will use `await Future.delayed()` and `pump()` to advance through async sequences.

**Why:** Default timings (100-3000ms) would make integration tests take seconds per scenario. Short durations exercise the same code paths without wall-clock delays.

### 4. Tuning config: documentation file, not runtime code

**Decision:** The tuning config will be a Dart file (`tuning_reference.dart`) containing a documented constant that aggregates all three existing config classes' defaults into a single reference. It will include TODO markers for values needing device validation. It does NOT replace the existing configs — it references them.

**Why:** The existing three config classes are well-designed with constructor-parameter overrides. A fourth "master" config that replaces them would add indirection. A reference file that documents what each value does and where it lives is more useful for the tuning workflow.

**Alternatives considered:**
- Single unified config class: Would require changing all provider references. Higher coupling for little benefit since values are set once at startup.
- Markdown document: Wouldn't be co-located with code. A Dart file with doc comments stays with the codebase and can import the actual types.

### 5. Test file organization

**Decision:** One test file per test category in `app/integration_test/`:
- `learning_flow_test.dart` — happy path end-to-end flow
- `edge_cases_test.dart` — rapid navigation, double taps, timing edge cases

**Why:** Two focused files are easier to run selectively than one monolith or many tiny files.

## Risks / Trade-offs

- **[Risk] Integration tests may be flaky due to async timing** → Mitigation: Use very short timing configs and explicit pump/settle calls. Avoid relying on wall-clock delays.
- **[Risk] Mock vibration service may not catch real-device vibration bugs** → Mitigation: This is accepted; the mock validates call sequences. Real-device testing is a separate manual step.
- **[Risk] Release builds may fail on CI without Xcode/Android SDK** → Mitigation: Build verification is documented as a manual step (run locally), not a CI gate.
- **[Trade-off] Testing via classifier injection vs. pointer simulation** → We trade some coverage of the pointer-to-classifier path for deterministic, fast tests. The pointer forwarding is already tested in widget tests.
