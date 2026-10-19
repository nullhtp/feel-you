import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The files `flutter_secure_storage` keeps the cloud key in, under
/// `shared_prefs/`, with its default options (no `storageNamespace`).
const _secureStorageFiles = {
  'FlutterSecureStorage.xml',
  'FlutterSecureKeyStorage.xml',
  'FlutterSecureStorageConfiguration:FlutterSecureStorage.xml',
};

const _res = 'android/app/src/main/res/xml';

String _read(String path) => File(path).readAsStringSync();

/// The `domain:path` of every `<exclude>` in [xml].
Set<String> _excludes(String xml) => {
  for (final match in RegExp(
    r'<exclude\s+domain="([^"]+)"\s+path="([^"]+)"\s*/>',
  ).allMatches(xml))
    '${match[1]}:${match[2]}',
};

/// The content of the `<tag>` section of [xml].
String _section(String xml, String tag) {
  final match = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml);
  expect(match, isNotNull, reason: '<$tag> is missing');
  return match![1]!;
}

/// Drops XML comments, so rules mentioned in them don't count.
String _withoutComments(String xml) =>
    xml.replaceAll(RegExp('<!--.*?-->', dotAll: true), '');

void main() {
  final expected = {for (final file in _secureStorageFiles) 'sharedpref:$file'};

  group('Android backup rules', () {
    test('the manifest declares both rule sets and keeps backup on', () {
      final manifest = _withoutComments(
        _read('android/app/src/main/AndroidManifest.xml'),
      );
      expect(
        manifest,
        contains('android:fullBackupContent="@xml/backup_rules"'),
      );
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(manifest, isNot(contains('android:allowBackup="false"')));
    });

    test('Android 11 and lower: only the secure storage files are left '
        'out', () {
      final rules = _withoutComments(_read('$_res/backup_rules.xml'));
      expect(_section(rules, 'full-backup-content'), isNotEmpty);
      expect(_excludes(rules), expected);
      expect(rules, isNot(contains('<include')));
    });

    test('Android 12 and higher: only the secure storage files are left out '
        'of cloud backup and device transfer', () {
      final rules = _withoutComments(_read('$_res/data_extraction_rules.xml'));
      for (final section in ['cloud-backup', 'device-transfer']) {
        expect(_excludes(_section(rules, section)), expected, reason: section);
      }
      expect(rules, isNot(contains('<include')));
      expect(_excludes(rules), expected);
    });
  });
}
