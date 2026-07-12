import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'journal_models.dart';

const _kKey = 'journal_entries_v1';

class JournalService {
  JournalService._();
  static final JournalService instance = JournalService._();

  List<JournalEntry>? _cache;

  Future<List<JournalEntry>> getAll() async {
    _cache ??= await _load();
    return List.unmodifiable(_cache!);
  }

  Future<void> add(JournalEntry entry) async {
    final all = List<JournalEntry>.from(await getAll());
    all.insert(0, entry);
    _cache = all;
    await _save(all);
  }

  Future<void> update(JournalEntry entry) async {
    final all = List<JournalEntry>.from(await getAll());
    final idx = all.indexWhere((e) => e.id == entry.id);
    if (idx == -1) return;
    all[idx] = entry;
    // Keep sorted newest first
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = all;
    await _save(all);
  }

  Future<void> delete(String id) async {
    final all = List<JournalEntry>.from(await getAll());
    all.removeWhere((e) => e.id == id);
    _cache = all;
    await _save(all);
  }

  void invalidateCache() => _cache = null;

  Future<List<JournalEntry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];
    final entries = raw.map((s) {
      try {
        return JournalEntry.fromJson(json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<JournalEntry>().toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> _save(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, entries.map((e) => json.encode(e.toJson())).toList());
  }
}
