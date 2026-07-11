import 'dart:convert';
import 'package:flutter/services.dart';
import 'search_models.dart';

// Offline Q&A lookup using biblical_qa.json.
// Scores each entry by keyword overlap against the query.
// Returns a SeekResult when confidence >= 0.35, null otherwise.

class BiblicalQaService {
  BiblicalQaService._();
  static final BiblicalQaService instance = BiblicalQaService._();

  Map<String, dynamic>? _qa;
  bool _loading = false;

  Future<SeekResult?> lookup(String query) async {
    await _ensureLoaded();
    if (_qa == null || _qa!.isEmpty) return null;

    final qWords = _tokenize(query);
    if (qWords.isEmpty) return null;

    String? bestKey;
    double bestScore = 0.0;

    for (final key in _qa!.keys) {
      final entry = _qa![key] as Map<String, dynamic>?;
      if (entry == null) continue;

      double score = _score(query, qWords, key, entry);
      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    }

    if (bestKey == null || bestScore < 0.35) return null;

    final entry = _qa![bestKey] as Map<String, dynamic>;
    return _toResult(bestKey, entry);
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  double _score(String query, List<String> qWords, String key, Map<String, dynamic> entry) {
    // Check if any canonical question variant is a close string match
    final variants = ((entry['questions'] as List?) ?? []).cast<String>();
    final qNorm = query.toLowerCase().trim().replaceAll('?', '');
    for (final v in variants) {
      final vNorm = v.toLowerCase().replaceAll('?', '');
      if (vNorm == qNorm) return 1.0;
      if (vNorm.contains(qNorm) || qNorm.contains(vNorm)) return 0.9;
    }

    // Keyword overlap: how many query words appear in the entry's keywords list
    final keywords = ((entry['keywords'] as List?) ?? [])
        .cast<String>()
        .map((k) => k.toLowerCase())
        .toSet();

    int hits = 0;
    for (final w in qWords) {
      if (keywords.contains(w)) hits++;
      // partial match: keyword starts with query word (e.g. "trinit" hits "trinity")
      else if (keywords.any((k) => k.startsWith(w) && w.length >= 4)) hits++;
    }

    if (qWords.isEmpty) return 0.0;
    final overlap = hits / qWords.length;

    // Also boost if any query word is in the canonical key
    final keyWords = key.split(' ').toSet();
    final keyHits = qWords.where((w) => keyWords.contains(w)).length;
    final keyBoost = keyHits / qWords.length * 0.2;

    return (overlap * 0.8 + keyBoost).clamp(0.0, 1.0);
  }

  SeekResult _toResult(String key, Map<String, dynamic> e) {
    final rawVerses = ((e['verses'] as List?) ?? []).cast<String>();
    final verses = rawVerses.map((ref) => SeekVerse(ref: ref, text: '')).toList();

    return SeekResult(
      type: SeekType.question,
      question: _canonicalQuestion(key),
      answer: e['answer'] as String?,
      context: e['context'] as String?,
      verses: verses,
      reflection: e['reflection'] as String?,
      fromCache: true,
    );
  }

  String _canonicalQuestion(String key) {
    // Capitalise first letter and add a question mark if missing
    if (key.isEmpty) return key;
    final s = key[0].toUpperCase() + key.substring(1);
    return s.endsWith('?') ? s : '$s?';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const _stopWords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'to', 'of', 'and', 'or', 'in', 'on', 'at', 'it', 'its', 'for',
    'do', 'does', 'did', 'with', 'that', 'this', 'these', 'those',
    'i', 'me', 'my', 'we', 'you', 'your', 'he', 'she', 'they', 'them',
    'if', 'but', 'not', 'so', 'by', 'from', 'up', 'out', 'about',
  };

  List<String> _tokenize(String q) => q
      .toLowerCase()
      .replaceAll(RegExp(r'[?!.,;:]'), '')
      .replaceAll("'", '')
      .replaceAll('"', '')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1 && !_stopWords.contains(w))
      .toList();

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_qa != null) return;
    if (_loading) {
      while (_loading) { await Future.delayed(const Duration(milliseconds: 20)); }
      return;
    }
    _loading = true;
    try {
      final raw = await rootBundle.loadString('assets/data/biblical_qa.json');
      _qa = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      _qa = {};
    } finally {
      _loading = false;
    }
  }
}
