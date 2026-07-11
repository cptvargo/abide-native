import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_models.dart';

const _kPrefsKey = 'highlights_v1';

class HighlightsService {
  HighlightsService._();
  static final HighlightsService instance = HighlightsService._();

  List<Highlight>? _cache;

  Future<List<Highlight>> getAll() async {
    _cache ??= await _load();
    return List.unmodifiable(_cache!);
  }

  Future<List<Highlight>> getForChapter(String book, int chapter) async {
    final all = await getAll();
    return all.where((h) => h.book == book && h.chapter == chapter).toList();
  }

  Future<void> add(Highlight h) async {
    final all = List<Highlight>.from(await getAll());
    all.add(h);
    _cache = all;
    await _save(all);
  }

  Future<void> remove(String groupId) async {
    final all = List<Highlight>.from(await getAll());
    all.removeWhere((h) => h.groupId == groupId);
    _cache = all;
    await _save(all);
  }

  Future<void> update(Highlight updated) async {
    final all = List<Highlight>.from(await getAll());
    final idx = all.indexWhere((h) => h.groupId == updated.groupId);
    if (idx == -1) return;
    all[idx] = updated;
    _cache = all;
    await _save(all);
  }

  // Updates a single highlight matched by book+chapter+verse (for recolor/regroup).
  Future<void> updateByVerse(Highlight updated) async {
    final all = List<Highlight>.from(await getAll());
    final idx = all.indexWhere(
      (h) => h.book == updated.book && h.chapter == updated.chapter && h.verse == updated.verse,
    );
    if (idx == -1) return;
    all[idx] = updated;
    _cache = all;
    await _save(all);
  }

  // Updates colorId and/or tags for all highlights sharing a groupId.
  Future<void> updateGroup(String groupId, {String? colorId, List<String>? tags}) async {
    final all = List<Highlight>.from(await getAll());
    bool changed = false;
    for (int i = 0; i < all.length; i++) {
      if (all[i].groupId == groupId) {
        all[i] = all[i].copyWith(colorId: colorId, tags: tags);
        changed = true;
      }
    }
    if (!changed) return;
    _cache = all;
    await _save(all);
  }

  Future<List<Highlight>> search(String query) async {
    if (query.trim().isEmpty) return getAll();
    final q = query.toLowerCase();
    final all = await getAll();
    return all
        .where((h) =>
            h.text.toLowerCase().contains(q) ||
            h.book.toLowerCase().contains(q) ||
            h.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  Future<List<Highlight>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kPrefsKey) ?? [];
    return raw.map((s) {
      try {
        return Highlight.fromJson(json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Highlight>().toList();
  }

  Future<void> _save(List<Highlight> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefsKey, items.map((h) => json.encode(h.toJson())).toList());
  }

  void invalidateCache() => _cache = null;
}
