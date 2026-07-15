import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kWorkerUrl = 'https://abide-seek-proxy.jvargas22.workers.dev';
const _kWorkerSecret = 'abide-cf-7xK2m9pRqL';
const _kCachePrefix = 'abide_reflection_v1:';

class ReflectionService {
  ReflectionService._();
  static final ReflectionService instance = ReflectionService._();

  final Map<String, List<String>> _mem = {};

  String _cacheKey(String book, int chapter) =>
      '$_kCachePrefix${book.toLowerCase().replaceAll(' ', '')}:$chapter';

  Future<List<String>> load(String book, int chapter) async {
    final key = _cacheKey(book, chapter);
    if (_mem.containsKey(key)) return _mem[key]!;

    // Check persistent cache
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final list = (json.decode(raw) as List).cast<String>();
        _mem[key] = list;
        return list;
      } catch (_) {}
    }

    // Fetch from Worker
    final paragraphs = await _fetch(book, chapter);
    _mem[key] = paragraphs;
    try {
      await prefs.setString(key, json.encode(paragraphs));
    } catch (_) {}
    return paragraphs;
  }

  Future<List<String>> _fetch(String book, int chapter) async {
    final prompt =
        'Write a rich, weighty devotional reflection on $book Chapter $chapter.\n\n'
        'Write 3 paragraphs of flowing prose — no headers, no bullet points, no key verse callouts, no prayer. '
        'Just deep, contemplative reflection on what this chapter reveals about God, His character, and His purposes. '
        'The tone should be like a thoughtful Reformed evangelical scholar writing for personal devotion — '
        'reverent, substantive, and grounded in the text. Do not summarize the chapter. Reflect on its meaning and weight.\n\n'
        'Return only the 3 paragraphs separated by a blank line. No preamble, no labels, no JSON.';

    final response = await http.post(
      Uri.parse(_kWorkerUrl),
      headers: {'Content-Type': 'application/json', 'X-Abide-Client': _kWorkerSecret},
      body: json.encode({'query': prompt}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Reflection fetch failed: ${response.statusCode}');
    }

    final envelope = json.decode(response.body);
    final text = _extractText(envelope);
    final paragraphs = text
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) throw Exception('Empty reflection response');
    return paragraphs;
  }

  String _extractText(dynamic envelope) {
    if (envelope is Map) {
      final content = envelope['content'];
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map) return (first['text'] as String?) ?? '';
      }
      final data = envelope['data'];
      if (data is Map) {
        final c = data['content'];
        if (c is List && c.isNotEmpty) {
          final first = c.first;
          if (first is Map) return (first['text'] as String?) ?? '';
        }
      }
    }
    return '';
  }

  void clearCache() {
    _mem.clear();
    debugPrint('ReflectionService: in-memory cache cleared');
  }
}
