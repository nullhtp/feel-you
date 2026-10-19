import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// End to end, for each language added after English, Arabic and Russian:
// the whole app opens on the language picker (nothing saved), the user
// chooses the language, then learns its own letter and a word with real
// pointer events on the lesson surface. The motor is answered at the
// platform channels; vibration is recorded instead of played.

/// One language's flow.
typedef _Flow = ({
  /// The language to choose.
  MorseLanguage language,

  /// Its column label in the picker.
  String label,

  /// The letter whose Morse pattern identifies it in the picker.
  String identifier,

  /// A letter only this language's letters level has.
  String letter,

  /// A word of its words level, spelled and then answered.
  String word,
});

const _flows = <_Flow>[
  (
    language: MorseLanguage.spanish,
    label: 'Español',
    identifier: 'Ñ',
    letter: 'Ñ',
    word: 'BAÑO',
  ),
  (
    language: MorseLanguage.french,
    label: 'Français',
    identifier: 'É',
    letter: 'É',
    word: 'ÇA',
  ),
];

/// A swipe right across the middle of the lesson surface.
Future<void> _swipeRight(WidgetTester tester) async {
  await tester.dragFrom(surfacePoint(tester, 0.3, 0.4), const Offset(200, 0));
  await tester.pump();
}

/// A swipe up across the middle of the lesson surface.
Future<void> _swipeUp(WidgetTester tester) async {
  await tester.dragFrom(surfacePoint(tester, 0.5, 0.7), const Offset(0, -150));
  await tester.pump();
}

/// Taps [signals] on the left (dot) and right (dash) halves.
Future<void> _tapSignals(WidgetTester tester, List<MorseSignal> signals) async {
  for (final signal in signals) {
    await tapAt(
      tester,
      signal == MorseSignal.dot ? dotPoint(tester) : dashPoint(tester),
    );
  }
}

/// Swipes right until the session is on item [index] of its level,
/// clearing the recorded vibration before each swipe, so it ends up
/// holding only what played on that item.
Future<void> _swipeRightTo(
  WidgetTester tester,
  E2EApp app,
  RecordingVibrationService vibration,
  int index,
) async {
  while (app.session(tester).positionIndex < index) {
    final next = app.session(tester).positionIndex + 1;
    vibration.reset();
    await _swipeRight(tester);
    await waitUntil(
      tester,
      () => app.session(tester).positionIndex == next,
      reason: 'a swipe right moves to item $next',
    );
  }
}

/// The calls that played Morse: single patterns and word patterns.
List<VibrationCall> _morseCalls(RecordingVibrationService vibration) => [
  for (final call in vibration.calls)
    if (call.type == VibrationCallType.playMorsePattern ||
        call.type == VibrationCallType.playMorseTokenPattern)
      call,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final flow in _flows) {
    testWidgets('${flow.language.name}: choose it, learn ${flow.letter} and '
        '${flow.word}', (tester) async {
      FakeVibrationPlatform().install(tester);
      final vibration = RecordingVibrationService();
      final app = E2EApp(vibration: vibration);
      await app.launch(tester);

      // Nothing is saved, so the app opens on the picker, which announces
      // the highlighted language, English.
      await waitUntil(
        tester,
        () => vibration.patterns.isNotEmpty,
        reason: 'the picker announces English',
      );
      expect(find.byType(LanguagePickerSurface), findsOneWidget);
      expect(vibration.patterns, [encodeLetter('E', MorseLanguage.english)]);

      // Tap the language: its identifier vibrates, encoded by its codec.
      final codec = app
          .container(tester)
          .read(tactileCodecProvider(flow.language));
      final identifier = encodeLetter(flow.identifier, flow.language)!;
      vibration.reset();
      await tester.tap(find.text(flow.label));
      await tester.pump();
      expect(vibration.patterns, [identifier]);
      expect(vibration.calls.single.played, codec.encode(flow.identifier));

      // Hold anywhere for a second: the identifier again, then the lesson
      // opens on digit 0 and the language is saved.
      final hold = await tester.startGesture(
        tester.getCenter(find.byType(LanguagePickerSurface)),
      );
      await tester.pump(
        LanguagePickerSurface.confirmHoldDuration +
            const Duration(milliseconds: 300),
      );
      await hold.up();
      await waitUntil(
        tester,
        () => find.byType(LanguagePickerSurface).evaluate().isEmpty,
        reason: 'the lesson surface replaces the picker',
      );
      await waitUntil(
        tester,
        () => vibration.hasPattern(digitZero),
        reason: 'digit 0 plays',
      );
      expect(vibration.patterns.take(2), [identifier, identifier]);
      expect(app.session(tester).language, flow.language);
      expect(app.session(tester).levelIndex, 0);
      expect(app.session(tester).currentCharacter, '0');
      expect(
        app.container(tester).read(languagePreferenceStoreProvider).read(),
        flow.language,
      );

      // Swipe up to the letters level, then right to the language's own
      // letter: its pattern plays.
      await _swipeUp(tester);
      await waitUntil(
        tester,
        () => app.session(tester).levelIndex == 1,
        reason: 'a swipe up opens the letters level',
      );
      final letters = app.session(tester).currentLevel;
      expect(letters.name, '${flow.language.name}-letters');
      expect(app.session(tester).currentCharacter, 'A');

      await _swipeRightTo(
        tester,
        app,
        vibration,
        letters.characters.indexOf(flow.letter),
      );
      expect(app.session(tester).currentCharacter, flow.letter);
      final pattern = encodeLetter(flow.letter, flow.language)!;
      await waitUntil(
        tester,
        () => vibration.hasPattern(pattern),
        reason: 'the pattern of ${flow.letter} plays',
      );
      expect(vibration.patterns, everyElement(pattern));

      // Tap it back: success, and the letter is learned and saved.
      vibration.reset();
      await _tapSignals(tester, pattern);
      await waitUntil(
        tester,
        () => vibration.callTypes.contains(VibrationCallType.playSuccess),
        reason: 'the success signal for ${flow.letter}',
      );
      expect(vibration.callTypes, isNot(contains(VibrationCallType.playError)));
      expect(
        app
            .container(tester)
            .read(learnedItemsProvider)
            .of(flow.language, letters),
        contains(flow.letter),
      );
      expect(
        app
            .container(tester)
            .read(learnedItemsStoreProvider)
            .read(flow.language, letters),
        contains(flow.letter),
      );

      // Swipe up to the words level and right to the word: it is spelled
      // letter by letter, then played as a word.
      vibration.reset();
      await _swipeUp(tester);
      await waitUntil(
        tester,
        () => app.session(tester).levelIndex == 2,
        reason: 'a swipe up opens the words level',
      );
      final words = app.session(tester).currentLevel;
      expect(words.name, '${flow.language.name}-words');
      expect(words.kind, LevelKind.words);
      await _swipeRightTo(
        tester,
        app,
        vibration,
        words.characters.indexOf(flow.word),
      );
      expect(app.session(tester).currentCharacter, flow.word);

      final tokens = words.wordPatterns![flow.word]!;
      final spelled = [
        for (final letter in flow.word.split(''))
          encodeLetter(letter, flow.language)!,
      ];
      expect(tokens, [
        for (var i = 0; i < spelled.length; i++) ...[
          if (i > 0) const CharGap(),
          for (final signal in spelled[i]) Signal(signal),
        ],
      ]);
      await waitUntil(
        tester,
        () => vibration.callTypes.contains(
          VibrationCallType.playMorseTokenPattern,
        ),
        reason: 'the word ${flow.word} plays',
      );
      final played = _morseCalls(vibration);
      expect([
        for (final call in played.take(spelled.length)) call.signals,
      ], spelled);
      expect(
        played[spelled.length].type,
        VibrationCallType.playMorseTokenPattern,
      );
      expect(played[spelled.length].tokens, tokens);
      expect(played[spelled.length].played, codec.encode(flow.word));

      // Tap the word back, with a bottom-strip tap between letters.
      vibration.reset();
      for (var i = 0; i < spelled.length; i++) {
        if (i > 0) await tapAt(tester, bottomStripPoint(tester));
        await _tapSignals(tester, spelled[i]);
      }
      await waitUntil(
        tester,
        () => vibration.callTypes.contains(VibrationCallType.playSuccess),
        reason: 'the success signal for ${flow.word}',
      );
      expect(vibration.callTypes, isNot(contains(VibrationCallType.playError)));
      expect(
        app
            .container(tester)
            .read(learnedItemsProvider)
            .of(flow.language, words),
        contains(flow.word),
      );

      await app.close(tester);
    });
  }
}
