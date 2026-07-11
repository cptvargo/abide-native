import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_models.dart';

const _kPrefsKey = 'abide_dictionary';

class DictionaryService {
  DictionaryService._();
  static final DictionaryService instance = DictionaryService._();

  List<DictionaryEntry>? _cache;

  Future<List<DictionaryEntry>> getAll() async {
    _cache ??= await _load();
    return List.unmodifiable(_cache!);
  }

  Future<bool> isSaved(String query) async {
    final all = await getAll();
    final key = query.toLowerCase();
    return all.any((e) => (e.result.word ?? e.query).toLowerCase() == key);
  }

  Future<DictionaryEntry> save(SeekResult result, String query) async {
    final all = List<DictionaryEntry>.from(await getAll());
    final key = (result.word ?? query).toLowerCase();
    final existingIdx = all.indexWhere(
      (e) => (e.result.word ?? e.query).toLowerCase() == key,
    );

    late DictionaryEntry entry;
    if (existingIdx != -1) {
      // Update in place, preserve personalNote
      entry = DictionaryEntry(
        id: all[existingIdx].id,
        savedAt: DateTime.now(),
        query: query,
        result: result,
        personalNote: all[existingIdx].personalNote,
      );
      all[existingIdx] = entry;
    } else {
      entry = DictionaryEntry(
        id: 'dict-${DateTime.now().millisecondsSinceEpoch}',
        savedAt: DateTime.now(),
        query: query,
        result: result,
      );
      all.insert(0, entry);
    }

    _cache = all;
    await _save(all);
    return entry;
  }

  Future<void> delete(String id) async {
    final all = List<DictionaryEntry>.from(await getAll());
    all.removeWhere((e) => e.id == id);
    _cache = all;
    await _save(all);
  }

  Future<void> updateNote(String id, String note) async {
    final all = List<DictionaryEntry>.from(await getAll());
    final idx = all.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    all[idx] = all[idx].copyWith(personalNote: note);
    _cache = all;
    await _save(all);
  }

  Future<List<DictionaryEntry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kPrefsKey) ?? [];
    return raw.map((s) {
      try {
        return DictionaryEntry.fromJson(json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<DictionaryEntry>().toList();
  }

  Future<void> _save(List<DictionaryEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kPrefsKey,
      items.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  void invalidateCache() => _cache = null;
}
