import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'highlights_service.dart';
import 'journal_service.dart';
import 'dictionary_service.dart';

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  static const _version = 1;

  Future<void> export({Rect? sharePositionOrigin}) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode({
      'version': _version,
      'exportDate': DateTime.now().toIso8601String(),
      'highlights': prefs.getStringList('highlights_v1') ?? [],
      'journals': prefs.getStringList('journal_entries_v1') ?? [],
      'bookmarks': prefs.getStringList('bookmarks') ?? [],
      'dictionary': prefs.getStringList('abide_dictionary') ?? [],
    });

    final dir = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/abide-backup-$date.abide');
    await file.writeAsString(payload);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'ABIDE Backup — $date',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  // Returns true if data was restored, false if user cancelled.
  Future<bool> import() async {
    const typeGroup = XTypeGroup(label: 'ABIDE backup', extensions: ['abide', 'json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return false;

    final raw = await file.readAsString();
    final data = json.decode(raw) as Map<String, dynamic>;

    if ((data['version'] as int?) != _version) {
      throw const FormatException('Unsupported backup version');
    }

    // Validate all fields before any write so a bad backup can't leave data half-replaced.
    final highlights = (data['highlights'] as List?)?.cast<String>()
        ?? (throw const FormatException('Missing highlights'));
    final journals = (data['journals'] as List?)?.cast<String>()
        ?? (throw const FormatException('Missing journals'));
    final bookmarks = (data['bookmarks'] as List?)?.cast<String>()
        ?? (throw const FormatException('Missing bookmarks'));
    final dictionary = (data['dictionary'] as List?)?.cast<String>();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('highlights_v1', highlights);
    await prefs.setStringList('journal_entries_v1', journals);
    await prefs.setStringList('bookmarks', bookmarks);
    if (dictionary != null) {
      await prefs.setStringList('abide_dictionary', dictionary);
      DictionaryService.instance.invalidateCache();
    }

    HighlightsService.instance.invalidateCache();
    JournalService.instance.invalidateCache();
    return true;
  }
}
