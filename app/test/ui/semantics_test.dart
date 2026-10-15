import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

const _dot = Signal(MorseSignal.dot);
const _dash = Signal(MorseSignal.dash);

/// Wraps [home] in a [ProviderScope] with the usual test doubles.
Widget _buildApp({
  required Widget home,
  required FakeGestureClassifier classifier,
  MockVibrationService? vibration,
  SessionState? initialState,
}) {
  return ProviderScope(
    overrides: [
      gestureClassifierProvider.overrideWithValue(classifier),
      vibrationServiceProvider.overrideWithValue(
        vibration ?? MockVibrationService(),
      ),
      shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
      teachingTimingConfigProvider.overrideWithValue(
        const TeachingTimingConfig(repeatPause: _testRepeatPause),
      ),
      if (initialState != null)
        sessionNotifierProvider.overrideWith(
          (ref) => _PresetSessionNotifier(initialState),
        ),
    ],
    child: MaterialApp(home: home),
  );
}

/// A [SessionNotifier] that starts with a custom initial state.
class _PresetSessionNotifier extends SessionNotifier {
  _PresetSessionNotifier(SessionState initial) : super(initial.language) {
    state = initial;
  }
}

/// Stops the teaching loop (if a [TouchSurface] is mounted), removes the
/// widget tree and flushes the loop's pending pause timer.
Future<void> _cleanUp(WidgetTester tester) async {
  final finder = find.byType(TouchSurface);
  if (finder.evaluate().isNotEmpty) {
    final container = ProviderScope.containerOf(tester.element(finder));
    await container.read(teachingOrchestratorProvider.notifier).stop();
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(_testRepeatPause);
}

void main() {
  // -------------------------------------------------------------------------
  // Language picker
  // -------------------------------------------------------------------------
  group('LanguagePickerSurface semantics', () {
    const buttons = {
      'English': 'English',
      'العربية': 'Arabic',
      'Русский': 'Russian',
    };

    testWidgets('each language is one button node with label and hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      await tester.pumpWidget(
        _buildApp(home: const LanguagePickerSurface(), classifier: classifier),
      );

      for (final MapEntry(key: label, value: englishName) in buttons.entries) {
        // Exactly one node carries the label: the inner Text is excluded,
        // so it is not announced a second time.
        final finder = find.bySemanticsLabel(label);
        expect(finder, findsOneWidget, reason: label);

        final node = tester.getSemantics(finder);
        expect(
          node,
          isSemantics(
            label: label,
            hint: 'Starts Morse lessons in $englishName',
            isButton: true,
            hasTapAction: true,
          ),
          reason: label,
        );
        expect(node.childrenCount, 0, reason: label);
      }

      await _cleanUp(tester);
      classifier.dispose();
      handle.dispose();
    });

    testWidgets('only the highlighted language is selected', (tester) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      await tester.pumpWidget(
        _buildApp(home: const LanguagePickerSurface(), classifier: classifier),
      );

      // English is highlighted when no language is saved.
      expect(
        tester.getSemantics(find.bySemanticsLabel('English')),
        isSemantics(isSelected: true),
      );
      for (final label in ['العربية', 'Русский']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(isSelected: false),
          reason: label,
        );
      }

      // A touch tap moves the highlight without starting a session.
      await tester.tap(find.text('Русский'));
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Русский')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('English')),
        isSemantics(isSelected: false),
      );
      expect(find.byType(TouchSurface), findsNothing);

      await _cleanUp(tester);
      classifier.dispose();
      handle.dispose();
    });

    testWidgets('each label is tagged with its language locale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      await tester.pumpWidget(
        _buildApp(home: const LanguagePickerSurface(), classifier: classifier),
      );

      const locales = {
        'English': Locale('en'),
        'العربية': Locale('ar'),
        'Русский': Locale('ru'),
      };
      for (final MapEntry(key: label, value: locale) in locales.entries) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        final attribute = data.attributedLabel.attributes.single;
        expect(attribute, isA<LocaleStringAttribute>(), reason: label);
        attribute as LocaleStringAttribute;
        expect(attribute.locale, locale, reason: label);
        expect(
          attribute.range,
          TextRange(start: 0, end: label.length),
          reason: label,
        );
      }

      await _cleanUp(tester);
      classifier.dispose();
      handle.dispose();
    });

    testWidgets('screen-reader activation selects the language', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        _buildApp(
          home: const LanguagePickerSurface(),
          classifier: classifier,
          vibration: vibration,
        ),
      );
      // Drop the highlighted identifier the picker plays when it appears.
      await tester.pump();
      vibration.reset();

      // One activation starts the language: no highlight-then-hold step.
      tester.semantics.tap(find.semantics.byLabel('Русский'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The Russian identifier (Р = · — ·) was vibrated first.
      expect(vibration.patterns.first, [
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dot,
      ]);
      expect(find.byType(TouchSurface), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TouchSurface)),
      );
      expect(
        container.read(sessionNotifierProvider).language,
        MorseLanguage.russian,
      );

      await _cleanUp(tester);
      classifier.dispose();
      handle.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Touch surface
  // -------------------------------------------------------------------------
  group('TouchSurface semantics', () {
    testWidgets('input area has a label and hint and names the route', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      await tester.pumpWidget(
        _buildApp(home: const TouchSurface(), classifier: classifier),
      );

      final finder = find.bySemanticsLabel('Morse input surface');
      expect(finder, findsOneWidget);

      final node = tester.getSemantics(finder);
      expect(node, isSemantics(label: 'Morse input surface', namesRoute: true));
      expect(
        node.hint,
        allOf(
          contains('left half for a dot'),
          contains('right half for a dash'),
          contains('bottom strip to submit'),
          contains('letter gap'),
          contains('Swipe'),
        ),
      );

      await _cleanUp(tester);
      classifier.dispose();
      handle.dispose();
    });

    testWidgets('touches still reach the classifier with semantics on', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      await tester.pumpWidget(
        _buildApp(home: const TouchSurface(), classifier: classifier),
      );

      final gesture = await tester.startGesture(const Offset(100, 200));
      await gesture.up();

      expect(classifier.touchEvents, hasLength(2));
      expect(classifier.touchEvents[0], isA<TouchDown>());
      expect(classifier.touchEvents[1], isA<TouchUp>());

      await _cleanUp(tester);
      classifier.dispose();
      handle.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Companion overlay
  // -------------------------------------------------------------------------
  group('CompanionOverlay semantics', () {
    /// Renders only the overlay (no teaching loop) on the letters level.
    Future<SessionNotifier> pumpOverlay(
      WidgetTester tester,
      FakeGestureClassifier classifier,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          home: const CompanionOverlay(),
          classifier: classifier,
          initialState: const SessionState(
            language: MorseLanguage.english,
            levelIndex: 1,
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CompanionOverlay)),
      );
      return container.read(sessionNotifierProvider.notifier);
    }

    SemanticsNode overlayNode(WidgetTester tester) =>
        tester.getSemantics(find.byType(CompanionOverlay));

    testWidgets('exposes one live-region summary node', (tester) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      await pumpOverlay(tester, classifier);

      const summary = 'Letters level, A, dot dash, 1 of 26, playing';
      expect(find.bySemanticsLabel(summary), findsOneWidget);
      expect(
        overlayNode(tester),
        isSemantics(label: summary, isLiveRegion: true),
      );
      expect(overlayNode(tester).childrenCount, 0);

      await tester.pumpWidget(const SizedBox());
      classifier.dispose();
      handle.dispose();
    });

    testWidgets('decorative labels and text fragments are not nodes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      await pumpOverlay(tester, classifier);

      // The fragments are still drawn for sighted observers...
      expect(find.text('DOT'), findsOneWidget);
      expect(find.text('DASH'), findsOneWidget);
      expect(find.text('SUBMIT'), findsOneWidget);

      // ...but no semantics node reads them, either as a node of its own or
      // merged into another node's label.
      for (final fragment in [
        'DOT',
        'DASH',
        'SUBMIT',
        'LETTERS',
        'PLAYING',
        '1/26',
        '·',
        '—',
      ]) {
        expect(
          find.semantics.byPredicate((node) => node.label.contains(fragment)),
          findsNothing,
          reason: fragment,
        );
      }
      // The current character is only read as part of the summary.
      expect(find.bySemanticsLabel('A'), findsNothing);
      expect(overlayNode(tester).childrenCount, 0);

      await tester.pumpWidget(const SizedBox());
      classifier.dispose();
      handle.dispose();
    });

    testWidgets('summary follows character, phase, level and input', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final classifier = FakeGestureClassifier();

      final notifier = await pumpOverlay(tester, classifier);
      String label() => overlayNode(tester).label;

      expect(label(), 'Letters level, A, dot dash, 1 of 26, playing');

      notifier.nextPosition();
      await tester.pump();
      expect(label(), 'Letters level, B, dash dot dot dot, 2 of 26, playing');

      notifier.setPhase(SessionPhase.listening);
      await tester.pump();
      expect(label(), 'Letters level, B, dash dot dot dot, 2 of 26, listening');

      classifier.inputBufferNotifier.value = const [_dash, _dot];
      await tester.pump();
      expect(
        label(),
        'Letters level, B, dash dot dot dot, 2 of 26, listening, '
        'input dash dot',
      );

      classifier.inputBufferNotifier.value = const [];
      notifier.nextLevel();
      await tester.pump();
      expect(
        label(),
        'Words level, HI, dot dot dot dot gap dot dot, 1 of 20, playing',
      );
      expect(overlayNode(tester), isSemantics(isLiveRegion: true));

      await tester.pumpWidget(const SizedBox());
      classifier.dispose();
      handle.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Summary builder
  // -------------------------------------------------------------------------
  group('companionOverlaySummary', () {
    const level = Level(
      name: 'arabic-letters',
      characters: ['ا', 'ب'],
      patterns: {
        'ا': [MorseSignal.dot, MorseSignal.dash],
        'ب': [MorseSignal.dash, MorseSignal.dot, MorseSignal.dot],
      },
    );

    test('reads level, character, pattern, position and phase', () {
      expect(
        companionOverlaySummary(
          level: level,
          character: 'ب',
          pattern: const [_dash, _dot, _dot],
          positionIndex: 1,
          phase: SessionPhase.feedback,
        ),
        'Arabic letters level, ب, dash dot dot, 2 of 2, feedback',
      );
    });

    test('appends the input only when it is not empty', () {
      String summary(List<MorseToken> input) => companionOverlaySummary(
        level: level,
        character: 'ا',
        pattern: const [_dot, _dash],
        positionIndex: 0,
        phase: SessionPhase.listening,
        input: input,
      );

      expect(summary(const []), endsWith('1 of 2, listening'));
      expect(
        summary(const [_dot, CharGap(), _dash]),
        endsWith('1 of 2, listening, input dot gap dash'),
      );
    });

    test('omits an empty pattern', () {
      expect(
        companionOverlaySummary(
          level: level,
          character: 'ا',
          pattern: const [],
          positionIndex: 0,
          phase: SessionPhase.playing,
        ),
        'Arabic letters level, ا, 1 of 2, playing',
      );
    });
  });
}
