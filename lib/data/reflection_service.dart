import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kWorkerUrl = 'https://abide-seek-proxy.jvargas22.workers.dev';
const _kWorkerSecret = 'abide-cf-7xK2m9pRqL';
const _kPrefPrefix = 'reflection_v1_';

class ReflectionService {
  ReflectionService._();
  static final ReflectionService instance = ReflectionService._();

  final Map<String, List<String>> _mem = {};

  Future<List<String>> load(String book, int chapter) async {
    final folder = book.toLowerCase().replaceAll(' ', '').replaceAll("'", '');
    final key = '$folder:$chapter';

    // 1. Memory cache
    if (_mem.containsKey(key)) return _mem[key]!;

    // 2. Persistent cache — never regenerate if already saved
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_kPrefPrefix$key');
    if (saved != null) {
      final list = (json.decode(saved) as List).cast<String>();
      _mem[key] = list;
      return list;
    }

    // 3. Generate via Worker and persist forever
    final ai = await _tryWorker(book, folder, chapter);
    if (ai != null) {
      await prefs.setString('$_kPrefPrefix$key', json.encode(ai));
      _mem[key] = ai;
      return ai;
    }

    // 4. Fall back to static JSON (not persisted — Worker may succeed next time)
    final path = 'assets/data/reflections/$folder/$chapter.json';
    final raw = await rootBundle.loadString(path);
    final list = (json.decode(raw) as List).cast<String>();
    _mem[key] = list;
    return list;
  }

  Future<List<String>?> _tryWorker(String book, String folder, int chapter) async {
    try {
      final chapterPath = 'assets/asr/$folder/$chapter.json';
      final raw = await rootBundle.loadString(chapterPath);
      final data = json.decode(raw) as Map<String, dynamic>;
      final verses = data['verses'] as Map<String, dynamic>? ?? {};

      final buffer = StringBuffer();
      for (final entry in verses.entries) {
        final v = entry.value;
        String text;
        if (v is String) {
          text = v;
        } else if (v is Map) {
          if (v.containsKey('segments')) {
            text = (v['segments'] as List)
                .map((s) => s is Map ? (s['text'] ?? '') : '')
                .join('');
          } else {
            text = v['text'] as String? ?? '';
          }
        } else {
          text = '';
        }
        buffer.write('${entry.key}. $text\n');
        if (buffer.length > 6000) break;
      }

      final response = await http.post(
        Uri.parse(_kWorkerUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Abide-Client': _kWorkerSecret,
        },
        body: json.encode({
          'queryType': 'reflection',
          'book': book,
          'chapter': chapter,
          'verseText': buffer.toString().trim(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;

      final body = json.decode(response.body) as Map<String, dynamic>;
      final paragraphs = (body['paragraphs'] as List?)?.cast<String>();
      if (paragraphs == null || paragraphs.isEmpty) return null;
      return paragraphs;
    } catch (_) {
      return null;
    }
  }

  void clearCache() => _mem.clear();
}
