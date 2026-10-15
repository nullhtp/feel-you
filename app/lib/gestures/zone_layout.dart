import 'dart:ui' show Size;

import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Where the input zones of the touch surface are, for one surface size.
///
/// The surface is split into:
/// - the bottom input zone, the lower
///   [GestureTimingConfig.bottomZoneFraction] of the height, starting at
///   [bottomZoneTop];
/// - above it, the left half (dots) and the right half (dashes), split at
///   [midX].
///
/// This is the single source of truth for the zone geometry: the gesture
/// classifier uses it to decide what a press means, and the companion
/// overlay uses it to draw the zone dividers and labels, so the two always
/// agree.
@immutable
class ZoneLayout {
  /// Computes the zones of a surface of [size] (in logical pixels), with the
  /// bottom-zone height taken from [config].
  ZoneLayout(Size size, GestureTimingConfig config)
    : midX = size.width / 2,
      bottomZoneTop = size.height * (1 - config.bottomZoneFraction);

  /// The x-coordinate of the dot/dash boundary, in logical pixels.
  ///
  /// A press starting left of it is a dot; one starting on it or to its
  /// right is a dash.
  final double midX;

  /// The y-coordinate of the top edge of the bottom input zone, in logical
  /// pixels.
  ///
  /// A press starting on or below it is in the bottom zone.
  final double bottomZoneTop;

  /// Whether a press starting at [y] is in the bottom input zone.
  bool isInBottomZone(double y) => y >= bottomZoneTop;

  /// Whether a press starting at [x] is on the left (dot) half.
  bool isInLeftHalf(double x) => x < midX;
}
