import 'package:feel_you/cloud/cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What [describeCloudKey] says when no key is saved.
const cloudKeyNoneLabel = 'none';

/// What [describeCloudKey] says while the key is still being read.
const cloudKeyCheckingLabel = 'checking…';

/// The cloud key as the companion overlay shows it: its masked form (e.g.
/// `sk-or-...a1b2`), [cloudKeyNoneLabel] when none is saved, or
/// [cloudKeyCheckingLabel] while it is still being read.
///
/// Never more of the key than its masked form.
String describeCloudKey(AsyncValue<CloudKey?> key) => switch (key) {
  AsyncData(:final value) => value?.masked ?? cloudKeyNoneLabel,
  // The provider never fails; if it did, there would be no usable key.
  AsyncError() => cloudKeyNoneLabel,
  _ => cloudKeyCheckingLabel,
};

/// Small cloud key readout for the companion overlay, e.g.
/// `Cloud key: sk-or-...a1b2` or `Cloud key: none`.
///
/// Lets a sighted helper check which key is set without ever seeing it.
/// Sits dimmed in the bottom-right corner, across from the vibration
/// readout, and follows [cloudKeyProvider], so it changes as soon as the key
/// is saved or deleted. Meant as a child of the overlay's [Stack].
class CloudKeyStatus extends ConsumerWidget {
  const CloudKeyStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 8),
          child: Text(
            'Cloud key: ${describeCloudKey(ref.watch(cloudKeyProvider))}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
