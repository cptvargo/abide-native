import 'dart:convert';
import 'package:flutter/services.dart';

class BibDictEntry {
  final String id;
  final String term;
  final String category;
  final String summary;
  final String definition;
  final String? historicalBackground;
  final String? biblicalSignificance;
  final List<String> related;
  final List<String> refs;
  final List<String> strongs;
  final List<String> sources;

  const BibDictEntry({
    required this.id,
    required this.term,
    required this.category,
    required this.summary,
    required this.definition,
    this.historicalBackground,
    this.biblicalSignificance,
    required this.related,
    required this.refs,
    required this.strongs,
    required this.sources,
  });

  factory BibDictEntry.fromJson(Map<String, dynamic> j) => BibDictEntry(
        id: j['id'] as String,
        term: j['term'] as String,
        category: j['category'] as String,
        summary: j['summary'] as String,
        definition: j['definition'] as String,
        historicalBackground: j['historical_background'] as String?,
        biblicalSignificance: j['biblical_significance'] as String?,
        related: List<String>.from(j['related'] as List? ?? []),
        refs: List<String>.from(j['refs'] as List? ?? []),
        strongs: List<String>.from(j['strongs'] as List? ?? []),
        sources: List<String>.from(j['sources'] as List? ?? []),
      );
}

class BibDictService {
  BibDictService._();
  static final BibDictService instance = BibDictService._();

  List<BibDictEntry>? _cache;

  Future<List<BibDictEntry>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle
        .loadString('assets/data/bible_dictionary/entries.json');
    final list = json.decode(raw) as List;
    _cache = list
        .map((e) => BibDictEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache!.sort((a, b) => a.term.compareTo(b.term));
    return _cache!;
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  List<BibDictEntry> search(String query, List<BibDictEntry> all) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    final exact = <BibDictEntry>[];
    final startsWith = <BibDictEntry>[];
    final contains = <BibDictEntry>[];

    for (final e in all) {
      final termL = e.term.toLowerCase();
      if (termL == q) {
        exact.add(e);
      } else if (termL.startsWith(q)) {
        startsWith.add(e);
      } else if (termL.contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.summary.toLowerCase().contains(q)) {
        contains.add(e);
      }
    }
    return [...exact, ...startsWith, ...contains];
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Map<String, int> categoryCounts(List<BibDictEntry> all) {
    final counts = <String, int>{};
    for (final e in all) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    return counts;
  }

  BibDictEntry? byId(String id, List<BibDictEntry> all) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  void invalidate() => _cache = null;
}
