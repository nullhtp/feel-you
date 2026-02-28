import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fraction of the screen height reserved for the bottom input zone.
/// Matches the constant in touch_surface.dart.
const _bottomZoneFraction = 0.15;

/// Visual companion overlay for sighted observers.
///
/// Displays zone boundaries, labels, current symbol/word, Morse pattern,
/// level, progress, input buffer, and session phase on top of the black
/// touch surface. Wrapped in [IgnorePointer] so all touches pass through.
class CompanionOverlay extends ConsumerWidget {
  const CompanionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider);
    final size = MediaQuery.of(context).size;
    final bottomZoneTop = size.height * (1 - _bottomZoneFraction);
    final midX = size.width / 2;

    final character = session.currentCharacter;
    final level = session.currentLevel;
    final pattern = level.patterns[character] ?? [];
    final isWordsLevel = session.levelIndex == 2;

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            // --- Zone dividers ---
            // Vertical divider (center, top to bottom zone boundary)
            Positioned(
              left: midX - 0.5,
              top: 0,
              bottom: size.height - bottomZoneTop,
              child: Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            // Horizontal divider (bottom zone boundary, full width)
            Positioned(
              left: 0,
              right: 0,
              top: bottomZoneTop,
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),

            // --- Zone labels ---
            // DOT label (left zone, centered vertically)
            Positioned(
              left: 0,
              top: 0,
              bottom: size.height - bottomZoneTop,
              width: midX,
              child: Center(
                child: Text(
                  'DOT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            // DASH label (right zone, centered vertically)
            Positioned(
              left: midX,
              top: 0,
              bottom: size.height - bottomZoneTop,
              width: midX,
              child: Center(
                child: Text(
                  'DASH',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            // SUBMIT / GAP label (bottom zone, centered)
            Positioned(
              left: 0,
              right: 0,
              top: bottomZoneTop,
              bottom: 0,
              child: Center(
                child: Text(
                  isWordsLevel ? 'GAP' : 'SUBMIT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),

            // --- Current symbol/word (large, bold, centered) ---
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: size.height - bottomZoneTop,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      character,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _symbolFontSize(character),
                        fontWeight: FontWeight.bold,
                        letterSpacing: character.length > 1 ? 4 : 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // --- Morse pattern display ---
                    Text(
                      _formatMorsePattern(pattern),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Level indicator (top-left) ---
            Positioned(
              left: 16,
              top: 12,
              child: Text(
                level.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // --- Position progress (top-right) ---
            Positioned(
              right: 16,
              top: 12,
              child: Text(
                '${session.positionIndex + 1}/${level.characters.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // --- Phase indicator (top-center) ---
            Positioned(
              left: 0,
              right: 0,
              top: 12,
              child: Center(
                child: Text(
                  session.phase.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            // --- Input buffer display (above bottom zone) ---
            Positioned(
              left: 0,
              right: 0,
              bottom: size.height - bottomZoneTop + 8,
              child: ValueListenableBuilder<List<MorseSymbol>>(
                valueListenable: ref.watch(inputBufferProvider),
                builder: (context, buffer, _) {
                  if (buffer.isEmpty) return const SizedBox.shrink();
                  return Center(
                    child: Text(
                      _formatInputBuffer(buffer),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a font size for the current character.
  /// Single chars (digits/letters) get 72sp; words scale down.
  static double _symbolFontSize(String character) {
    if (character.length <= 1) return 72;
    if (character.length <= 3) return 56;
    if (character.length <= 5) return 48;
    return 40;
  }

  /// Formats a Morse pattern as readable notation.
  /// Dots → "·", dashes → "—", charGaps → "/", separated by spaces.
  static String _formatMorsePattern(List<MorseSymbol> pattern) {
    return pattern
        .map((s) {
          switch (s) {
            case MorseSymbol.dot:
              return '\u00B7';
            case MorseSymbol.dash:
              return '\u2014';
            case MorseSymbol.charGap:
              return '/';
          }
        })
        .join(' ');
  }

  /// Formats the user's input buffer for display.
  static String _formatInputBuffer(List<MorseSymbol> buffer) {
    return buffer
        .map((s) {
          switch (s) {
            case MorseSymbol.dot:
              return '\u00B7';
            case MorseSymbol.dash:
              return '\u2014';
            case MorseSymbol.charGap:
              return '/';
          }
        })
        .join(' ');
  }
}
