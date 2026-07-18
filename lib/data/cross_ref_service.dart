import 'dart:convert';
import 'package:flutter/services.dart';

class CrossRef {
  const CrossRef({required this.verseNum, required this.refs});
  final int verseNum;
  final List<String> refs; // e.g. ["john 3:16", "romans 8:28"]
}

class CrossRefTarget {
  const CrossRefTarget({
    required this.book,       // display name, e.g. "John"
    required this.chapter,
    required this.verse,
    required this.raw,        // original string e.g. "john 3:16"
  });
  final String book;
  final int chapter;
  final int verse;
  final String raw;
}

class CrossRefService {
  CrossRefService._();
  static final CrossRefService instance = CrossRefService._();

  final Map<String, List<CrossRef>> _cache = {};

  Future<List<CrossRef>> load(String book, int chapter) async {
    final slug = _bookSlug(book);
    final key = '$slug:$chapter';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final raw = await rootBundle.loadString('assets/cross-references/$slug/$chapter.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final result = <CrossRef>[];
      final sorted = data.keys.toList()
        ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
      for (final k in sorted) {
        final vNum = int.tryParse(k);
        if (vNum == null) continue;
        final refs = (data[k] as List?)?.cast<String>() ?? [];
        if (refs.isNotEmpty) result.add(CrossRef(verseNum: vNum, refs: refs));
      }
      _cache[key] = result;
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Loads the text of a specific verse from the bundled translation files.
  Future<String> fetchVerseText(CrossRefTarget ref, String translation) async {
    try {
      final tl = translation.toLowerCase();
      final slug = _bookSlug(ref.book, translation: tl);
      final path = 'assets/$tl/$slug/${ref.chapter}.json';
      final raw = await rootBundle.loadString(path);
      final data = json.decode(raw) as Map<String, dynamic>;
      final verses = data['verses'] as Map<String, dynamic>?;
      if (verses == null) return '';
      final v = verses[ref.verse.toString()];
      return _extractText(v);
    } catch (_) {
      return '';
    }
  }

  /// Parses a raw ref string like "john 3:16" or "1corinthians 13:4-7" into a CrossRefTarget.
  CrossRefTarget? parseRef(String raw) {
    // Handle ranges like "john 3:16-18" — take first verse
    final cleaned = raw.replaceAll(RegExp(r'-\d+$'), '');
    final m = RegExp(r'^(.*?)\s+(\d+):(\d+)$').firstMatch(cleaned.trim());
    if (m == null) return null;
    final slug = m.group(1)!.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final chapter = int.tryParse(m.group(2)!);
    final verse = int.tryParse(m.group(3)!);
    if (chapter == null || verse == null) return null;
    final display = _displayName(slug);
    return CrossRefTarget(book: display, chapter: chapter, verse: verse, raw: raw);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _extractText(dynamic v) {
    if (v is String) return v;
    if (v is Map) {
      if (v.containsKey('segments')) {
        return (v['segments'] as List).map((s) => (s is Map ? s['text'] : s) ?? '').join(' ');
      }
      return (v['text'] as String?) ?? '';
    }
    return '';
  }

  String _bookSlug(String book, {String translation = 'asr'}) {
    final slug = book.toLowerCase().replaceAll(RegExp(r'[\s\.]'), '').replaceAll("'", '');
    // KJV asset folder is named "solomon'ssong", not "songofsolomon"
    if (slug == 'songofsolomon' && translation.toLowerCase() == 'kjv') {
      return "solomon'ssong";
    }
    return slug;
  }

  String _displayName(String slug) {
    const map = {
      'genesis': 'Genesis', 'exodus': 'Exodus', 'leviticus': 'Leviticus',
      'numbers': 'Numbers', 'deuteronomy': 'Deuteronomy', 'joshua': 'Joshua',
      'judges': 'Judges', 'ruth': 'Ruth', '1samuel': '1 Samuel',
      '2samuel': '2 Samuel', '1kings': '1 Kings', '2kings': '2 Kings',
      '1chronicles': '1 Chronicles', '2chronicles': '2 Chronicles',
      'ezra': 'Ezra', 'nehemiah': 'Nehemiah', 'esther': 'Esther',
      'job': 'Job', 'psalms': 'Psalms', 'proverbs': 'Proverbs',
      'ecclesiastes': 'Ecclesiastes', 'songofsolomon': 'Song of Solomon',
      'isaiah': 'Isaiah', 'jeremiah': 'Jeremiah', 'lamentations': 'Lamentations',
      'ezekiel': 'Ezekiel', 'daniel': 'Daniel', 'hosea': 'Hosea',
      'joel': 'Joel', 'amos': 'Amos', 'obadiah': 'Obadiah', 'jonah': 'Jonah',
      'micah': 'Micah', 'nahum': 'Nahum', 'habakkuk': 'Habakkuk',
      'zephaniah': 'Zephaniah', 'haggai': 'Haggai', 'zechariah': 'Zechariah',
      'malachi': 'Malachi', 'matthew': 'Matthew', 'mark': 'Mark',
      'luke': 'Luke', 'john': 'John', 'acts': 'Acts', 'romans': 'Romans',
      '1corinthians': '1 Corinthians', '2corinthians': '2 Corinthians',
      'galatians': 'Galatians', 'ephesians': 'Ephesians',
      'philippians': 'Philippians', 'colossians': 'Colossians',
      '1thessalonians': '1 Thessalonians', '2thessalonians': '2 Thessalonians',
      '1timothy': '1 Timothy', '2timothy': '2 Timothy', 'titus': 'Titus',
      'philemon': 'Philemon', 'hebrews': 'Hebrews', 'james': 'James',
      '1peter': '1 Peter', '2peter': '2 Peter', '1john': '1 John',
      '2john': '2 John', '3john': '3 John', 'jude': 'Jude',
      'revelation': 'Revelation',
    };
    return map[slug] ?? slug;
  }
}
