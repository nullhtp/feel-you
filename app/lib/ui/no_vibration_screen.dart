import 'package:flutter/material.dart';

/// Shown instead of the language picker on a device without a vibration
/// motor.
///
/// Feel You speaks only through vibration, so on such a device a session
/// would run while the user feels nothing. This screen tells the sighted
/// helper why the app can't be used and offers no way to start a session.
class NoVibrationScreen extends StatelessWidget {
  const NoVibrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No vibration motor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This device cannot vibrate, so Feel You cannot work on '
                  'it.\nFeel You communicates only through vibration. '
                  'Please use a phone with a vibration motor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
