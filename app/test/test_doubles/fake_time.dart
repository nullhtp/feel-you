import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;

/// How far fake time moves between two checks of whether a test body has
/// finished.
const _step = Duration(milliseconds: 1);

/// The fake time after which a body that has not finished fails, for
/// example because it waits for something that never happens.
const _limit = Duration(minutes: 1);

/// Defines a test like `flutter_test`'s `test`, but runs its [body] in fake
/// time.
///
/// A test file uses it in place of `flutter_test`'s by importing
/// `package:flutter_test/flutter_test.dart` with `hide test`, so every test
/// in the file runs in fake time.
///
/// Every timer started while the body runs, by the body itself (`await
/// Future.delayed(...)`) or by the code under test (the teaching loop's
/// pauses, the gesture classifier's silence and long-hold timers), fires in
/// fake time in the order of its deadline. The microtasks a timer schedules
/// (stream events, the next step of an async loop) run before the next timer
/// fires. So a body that waits and then acts sees everything due by the end
/// of its wait done, and acts before anything due later.
///
/// Real time under `flutter test` gives no such order. The engine runs all
/// overdue timers in one batch and only then their microtasks. On a loaded
/// machine a test's wait could end in the same batch as a pause of the
/// teaching loop: the test cleared the recorded vibrations and tapped, and
/// the loop, resumed by the next timer of the batch, played the item once
/// more before the tap reached it (#94).
///
/// Fake time moves only while the body waits, so a long wait costs nothing.
/// Only timers started inside the body are fake: one started by `setUp`
/// runs in real time, and a body waiting for it fails after [_limit]. Fake
/// time stops when the body ends, so what is still pending in it then (a
/// timer, or a platform channel's late reply) never runs.
void test(String description, FutureOr<void> Function() body) {
  flutter_test.test(description, () async {
    final time = FakeAsync();
    var finished = false;
    Object? error;
    StackTrace? stackTrace;
    time.run((_) {
      unawaited(
        Future<void>.sync(body).then<void>(
          (_) => finished = true,
          onError: (Object e, StackTrace s) {
            error = e;
            stackTrace = s;
            finished = true;
          },
        ),
      );
    });
    while (!finished) {
      if (time.elapsed >= _limit) {
        flutter_test.fail(
          'The test did not finish within $_limit of fake time.',
        );
      }
      time.elapse(_step);
      // Lets the body resume from a future completed outside fake time,
      // e.g. by cancelling a stream subscription made in `setUp`.
      await Future<void>.value();
    }
    if (error case final error?) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  });
}
