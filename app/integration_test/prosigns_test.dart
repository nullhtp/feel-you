import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

// The prosigns end to end (`morse-prosigns`, `tactile-codec`): the whole
// app in each language, with the default Morse timing and its own
// DeviceVibrationService. The motor is answered, and what reaches the
// `vibration` plugin caught, at the platform channels. No screen plays a
// prosign yet, so the test plays them through the app's own codec and
// vibration service, the path the reader (#44) will take.

/// The prosigns of `morse-prosigns` and the segments each one is sent as
/// with the default timing, written out rather than taken from the app.
const _prosigns = <(Prosign, String, List<int>)>[
  (
    Prosign.endOfMessage,
    'AR',
    [0, 100, 100, 300, 100, 100, 100, 300, 100, 100],
  ),
  (Prosign.wait, 'AS', [0, 100, 100, 300, 100, 100, 100, 100, 100, 100]),
  (
    Prosign.sos,
    'SOS',
    [
      0, 100, 100, 100, 100, 100, 100, 300, 100, 300, 100, 300, //
      100, 100, 100, 100, 100, 100,
    ],
  ),
  (
    Prosign.error,
    'error',
    [
      0, 100, 100, 100, 100, 100, 100, 100, 100, //
      100, 100, 100, 100, 100, 100, 100,
    ],
  ),
];

/// Morse `?`, the quiz marker: `· · − − · ·`, 1500 ms.
const _questionMark = [
  0, 100, 100, 100, 100, 300, //
  100, 300, 100, 100, 100, 100,
];

/// Morse L, which the home menu plays on launch: `· − · ·`, 900 ms.
const _menuLearn = [0, 100, 100, 300, 100, 100, 100, 100];

/// Each language, its identifier letter in the picker, and that letter's
/// segments with the default timing.
const _languages = <(MorseLanguage, String, List<int>)>[
  (MorseLanguage.english, 'E', [0, 100]),
  (MorseLanguage.arabic, 'ع', [0, 100, 100, 300, 100, 100, 100, 300]),
  (MorseLanguage.russian, 'Р', [0, 100, 100, 300, 100, 100]),
  (
    MorseLanguage.spanish,
    'Ñ',
    [0, 300, 100, 300, 100, 100, 100, 300, 100, 300],
  ),
  (MorseLanguage.french, 'É', [0, 100, 100, 100, 100, 300, 100, 100, 100, 100]),
  (MorseLanguage.german, 'Ü', [0, 100, 100, 100, 100, 300, 100, 300]),
];

/// The intensities sent with [segments]: 0 for every wait, 255 for every
/// vibration.
List<int> _intensities(List<int> segments) => [
  for (var i = 0; i < segments.length; i++)
    if (i.isOdd) 255 else 0,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final (language, letter, letterSegments) in _languages) {
    testWidgets('in ${language.name}, every prosign reaches the plugin as one '
        'character, and ? and $letter as before', (tester) async {
      final platform = FakeVibrationPlatform()..install(tester);
      final app = E2EApp(
        savedLanguage: language,
        overrides: [
          morseTimingConfigProvider.overrideWithValue(
            const MorseTimingConfig(),
          ),
        ],
      );
      await app.launch(tester);

      // The menu opens and announces Learn with Morse L, as before.
      await waitUntil(
        tester,
        () => find.byType(HomeMenuSurface).evaluate().isNotEmpty,
        reason: 'the home menu is shown',
      );
      await waitUntil(
        tester,
        () => platform.indexOfPattern(_menuLearn) >= 0,
        reason: 'the menu plays L',
      );
      expect(platform.patterns, [_menuLearn]);
      // Let L play out: from here on, only the test plays.
      await waitFor(tester, const Duration(milliseconds: 1000));
      expect(platform.vibrateCalls, hasLength(1));

      // The app's own codec for the session's language, and its own
      // vibration service.
      final container = app.container(tester);
      final session = app.session(tester);
      expect(session.language, language);
      final codec = container.read(tactileCodecProvider(session.language));
      final vibration = container.read(vibrationServiceProvider);
      expect(vibration, isA<DeviceVibrationService>());

      for (final (prosign, _, _) in _prosigns) {
        await vibration.playTokens(codec.encodeProsign(prosign));
      }
      await vibration.playTokens(codec.encode('?'));
      await vibration.playTokens(codec.encode(letter));
      await tester.pump();

      final sent = platform.patterns.skip(1).toList();
      final expected = [
        for (final (_, _, segments) in _prosigns) segments,
        _questionMark,
        letterSegments,
      ];
      expect(sent, expected);
      expect(platform.intensities.skip(1).toList(), [
        for (final segments in expected) _intensities(segments),
      ]);

      // One character each: only the 100 ms gap between the pulses of a
      // prosign, never the 300 ms letter gap.
      for (final (index, (_, name, _)) in _prosigns.indexed) {
        final pauses = [
          for (var i = 2; i < sent[index].length; i += 2) sent[index][i],
        ];
        expect(pauses, everyElement(100), reason: '$name in $language');
      }

      await app.close(tester);
    });
  }
}
