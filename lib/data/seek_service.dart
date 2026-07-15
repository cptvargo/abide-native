import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'search_models.dart';
import 'word_study_service.dart';
import 'biblical_qa_service.dart';

const _kWorkerUrl = 'https://abide-seek-proxy.jvargas22.workers.dev';
const _kWorkerSecret = 'abide-cf-7xK2m9pRqL';
const _kPrefsKey = 'seek_cache_v1';
const _kMaxEntries = 200;

class SeekService {
  SeekService._();
  static final SeekService instance = SeekService._();

  // in-memory: key → result
  final Map<String, SeekResult> _mem = {};
  // key order for LRU eviction (oldest first)
  final List<String> _order = [];
  bool _loaded = false;

  // ── Public API ────────────────────────────────────────────────────────────

  Future<SeekResult> seek(String query, {String translation = 'ASR'}) async {
    final q = query.trim();
    if (q.isEmpty) throw ArgumentError('empty query');

    await _ensureLoaded();

    final key = '${translation.toUpperCase()}:${q.toLowerCase()}';
    if (_mem.containsKey(key)) {
      return _mem[key]!.copyWith(fromCache: true);
    }

    // For word studies, try the local Strong's dataset first (zero cost, offline)
    if (!_isQuestion(q)) {
      final local = await WordStudyService.instance.lookup(q, translation: translation);
      if (local != null) return local;
    }

    // For questions, check the offline Q&A before hitting the Worker
    if (_isQuestion(q)) {
      final qa = await BiblicalQaService.instance.lookup(q);
      if (qa != null) return qa;
    }

    final result = await _fetch(q, translation);
    await _put(key, result);
    return result;
  }

  Future<void> clearCache() async {
    _mem.clear();
    _order.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefsKey);
  }

  // ── Network ───────────────────────────────────────────────────────────────

  Future<SeekResult> _fetch(String query, String translation) async {
    final queryType = _isQuestion(query) ? 'question' : 'word_study';

    final response = await http.post(
      Uri.parse(_kWorkerUrl),
      headers: {'Content-Type': 'application/json', 'X-Abide-Client': _kWorkerSecret},
      body: json.encode({
        'query': query,
        'translation': translation.toUpperCase(),
        'queryType': queryType,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Seek error ${response.statusCode}: ${response.body}');
    }

    final envelope = json.decode(response.body);
    final rawText = _extractText(envelope);
    final payload = _parseJson(rawText);
    return SeekResult.fromJson(payload);
  }

  String _extractText(dynamic envelope) {
    if (envelope is Map) {
      // { content: [{ text: "..." }] }
      final content = envelope['content'];
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map) return (first['text'] as String?) ?? '';
      }
      // { data: { content: [...] } }
      final data = envelope['data'];
      if (data is Map) {
        final c = data['content'];
        if (c is List && c.isNotEmpty) {
          final first = c.first;
          if (first is Map) return (first['text'] as String?) ?? '';
        }
      }
      if (envelope['text'] is String) return envelope['text'] as String;
    }
    return json.encode(envelope);
  }

  Map<String, dynamic> _parseJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      final firstNl = text.indexOf('\n');
      if (firstNl != -1) text = text.substring(firstNl + 1);
      if (text.endsWith('```')) text = text.substring(0, text.length - 3).trimRight();
    }
    return json.decode(text) as Map<String, dynamic>;
  }

  bool _isQuestion(String q) {
    final lower = q.toLowerCase().trimLeft();
    const starters = [
      'why', 'what', 'who', 'how', 'when', 'where', 'did', 'does',
      'is', 'are', 'can', 'could', 'would', 'should', 'was', 'were', 'do',
    ];
    for (final s in starters) {
      if (lower.startsWith('$s ') || lower == s) return true;
    }
    return q.trimRight().endsWith('?');
  }

  // ── Persistent cache ──────────────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null) return;
      final list = json.decode(raw) as List;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        final k = m['key'] as String;
        final resultJson = m['result'] as Map<String, dynamic>;
        _mem[k] = SeekResult.fromJson(resultJson);
        _order.add(k);
      }
    } catch (e) {
      debugPrint('SeekService: failed to load cache: $e');
    }
  }

  Future<void> _put(String key, SeekResult result) async {
    _mem[key] = result;
    _order.remove(key);
    _order.add(key);

    // evict oldest when over limit
    while (_order.length > _kMaxEntries) {
      final oldest = _order.removeAt(0);
      _mem.remove(oldest);
    }

    await _persist();
  }

  Future<void> _persist() async {
    try {
      final list = _order.map((k) => {
            'key': k,
            'result': _seekResultToJson(_mem[k]!),
          }).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefsKey, json.encode(list));
    } catch (e) {
      debugPrint('SeekService: failed to persist cache: $e');
    }
  }
}

Map<String, dynamic> _seekResultToJson(SeekResult r) => {
      'type': r.type.name,
      'word': r.word,
      'originalLanguage': r.originalLanguage == null
          ? null
          : {
              'language': r.originalLanguage!.language,
              'word': r.originalLanguage!.word,
              'transliteration': r.originalLanguage!.transliteration,
              'strongs': r.originalLanguage!.strongs,
              'meaning': r.originalLanguage!.meaning,
            },
      'definition': r.definition,
      'significance': r.significance,
      'question': r.question,
      'answer': r.answer,
      'context': r.context,
      'exegesis': r.exegesis
          ?.map((e) => {
                'passage': e.passage,
                'explanation': e.explanation,
                'keyInsight': e.keyInsight,
              })
          .toList(),
      'verses': r.verses
          .map((v) => {
                'ref': v.ref,
                'text': v.text,
                'note': v.note,
                'translation': v.translation,
              })
          .toList(),
      'pastoralCaution': r.pastoralCaution,
      'reflection': r.reflection,
    };
