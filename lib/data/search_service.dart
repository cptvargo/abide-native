import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'search_models.dart';

// Searches the bundled translation JSON files (assets/{tl}/{book}/{chapter}.json).
// Strategies in priority order:
//   1. Phrase match   — substring of cleaned query in verse text (fast, exact)
//   2. All-word match — every query term appears in verse text
//   3. Most-word match — ≥ 60 % of terms appear (fuzzy fallback, 3+ word queries only)
// Results capped at 60 per search. Corpus is loaded once per translation and cached.
// Matching runs in a compute() isolate so the UI thread is never blocked.

// ── Isolate helpers (top-level required by compute) ───────────────────────────

class _MatchArgs {
  const _MatchArgs(this.query, this.texts);
  final String query;
  final List<String> texts; // pre-normalized verse texts, parallel to corpus
}

List<int> _matchIndices(_MatchArgs args) {
  final phrase = args.query;
  final terms = phrase.split(' ').where((s) => s.length > 1).toList();

  final phraseIdx = <int>[];
  final allWordIdx = <int>[];
  final partialIdx = <int>[];

  for (int i = 0; i < args.texts.length; i++) {
    final lc = args.texts[i];

    if (lc.contains(phrase)) {
      phraseIdx.add(i);
      continue;
    }

    if (terms.isEmpty) continue;

    final matchCount = terms.where((t) => lc.contains(t)).length;
    if (matchCount == terms.length) {
      allWordIdx.add(i);
    } else if (terms.length >= 3 && matchCount / terms.length >= 0.60) {
      partialIdx.add(i);
    }
  }

  return [...phraseIdx, ...allWordIdx, ...partialIdx].take(60).toList();
}

// ─────────────────────────────────────────────────────────────────────────────

class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  final Map<String, List<VerseResult>> _corpus = {};
  final Map<String, List<String>> _normalizedCorpus = {};
  final _loading = <String, Future<void>>{};

  bool hasCorpus(String translation) => _corpus.containsKey(translation.toLowerCase());

  // Call when the Search tab becomes visible so the corpus is ready by first keystroke.
  void warmUp(String translation) => _ensureCorpus(translation.toLowerCase());

  Future<List<VerseResult>> search(String query, String translation) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final tl = translation.toLowerCase();

    // Reference lookup first: "John 3:16", "Romans 8:28", "1 Cor 13:4"
    final refResult = await _tryReference(q, tl);
    if (refResult != null) return [refResult];

    await _ensureCorpus(tl);
    final corpus = _corpus[tl]!;
    final normalized = _normalizedCorpus[tl]!;

    final indices = await compute(
      _matchIndices,
      _MatchArgs(_norm(q), normalized),
    );
    return indices.map((i) => corpus[i]).toList();
  }

  // ── Reference detection ───────────────────────────────────────────────────

  // Matches "Genesis 1:1", "1 Corinthians 13:4", "Song of Solomon 3:2" etc.
  static final _refPattern = RegExp(
    r'^(\d\s+)?([A-Za-z]+(?:\s+[A-Za-z]+){0,3})\s+(\d{1,3}):(\d{1,3})$',
    caseSensitive: false,
  );

  Future<VerseResult?> _tryReference(String query, String tl) async {
    final m = _refPattern.firstMatch(query.trim());
    if (m == null) return null;

    final prefix = (m.group(1) ?? '').trim();
    final bookRaw = ((prefix.isNotEmpty ? '$prefix ' : '') + (m.group(2) ?? '')).trim();
    final chapter = int.tryParse(m.group(3) ?? '');
    final verse = int.tryParse(m.group(4) ?? '');
    if (chapter == null || verse == null) return null;

    final bookKey = _bookKey(bookRaw);
    if (bookKey == null) return null;

    try {
      final path = 'assets/$tl/$bookKey/$chapter.json';
      final raw = await rootBundle.loadString(path);
      final data = json.decode(raw);
      if (data is! Map) return null;
      final verses = data['verses'];
      if (verses is! Map) return null;
      final v = verses[verse.toString()];
      if (v == null) return null;

      String text = '';
      if (v is String) {
        text = v;
      } else if (v is Map) {
        if (v.containsKey('segments')) {
          text = (v['segments'] as List).map((s) => (s is Map ? s['text'] : s) ?? '').join(' ');
        } else {
          text = (v['text'] as String?) ?? '';
        }
      }
      if (text.isEmpty) return null;

      return VerseResult(
        book: _displayBook(bookKey),
        chapter: chapter,
        verse: verse,
        text: text,
        translation: tl.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // Maps user-typed book name to the folder key used in assets/
  String? _bookKey(String raw) {
    final norm = raw.toLowerCase().replaceAll(RegExp(r'[\s\.]+'), '');
    const aliases = {
      // Standard
      'genesis': 'genesis', 'gen': 'genesis',
      'exodus': 'exodus', 'exo': 'exodus', 'ex': 'exodus',
      'leviticus': 'leviticus', 'lev': 'leviticus',
      'numbers': 'numbers', 'num': 'numbers',
      'deuteronomy': 'deuteronomy', 'deut': 'deuteronomy', 'deu': 'deuteronomy',
      'joshua': 'joshua', 'josh': 'joshua',
      'judges': 'judges', 'judg': 'judges',
      'ruth': 'ruth',
      '1samuel': '1samuel', '1sam': '1samuel',
      '2samuel': '2samuel', '2sam': '2samuel',
      '1kings': '1kings', '1kgs': '1kings',
      '2kings': '2kings', '2kgs': '2kings',
      '1chronicles': '1chronicles', '1chron': '1chronicles', '1chr': '1chronicles',
      '2chronicles': '2chronicles', '2chron': '2chronicles', '2chr': '2chronicles',
      'ezra': 'ezra',
      'nehemiah': 'nehemiah', 'neh': 'nehemiah',
      'esther': 'esther', 'esth': 'esther',
      'job': 'job',
      'psalms': 'psalms', 'psalm': 'psalms', 'ps': 'psalms', 'psa': 'psalms',
      'proverbs': 'proverbs', 'prov': 'proverbs', 'pro': 'proverbs',
      'ecclesiastes': 'ecclesiastes', 'eccl': 'ecclesiastes', 'ecc': 'ecclesiastes',
      'songofsolomon': 'songofsolomon', 'song': 'songofsolomon', 'sos': 'songofsolomon', 'sng': 'songofsolomon',
      'isaiah': 'isaiah', 'isa': 'isaiah',
      'jeremiah': 'jeremiah', 'jer': 'jeremiah',
      'lamentations': 'lamentations', 'lam': 'lamentations',
      'ezekiel': 'ezekiel', 'ezek': 'ezekiel', 'eze': 'ezekiel',
      'daniel': 'daniel', 'dan': 'daniel',
      'hosea': 'hosea', 'hos': 'hosea',
      'joel': 'joel',
      'amos': 'amos',
      'obadiah': 'obadiah', 'obad': 'obadiah',
      'jonah': 'jonah', 'jon': 'jonah',
      'micah': 'micah', 'mic': 'micah',
      'nahum': 'nahum', 'nah': 'nahum',
      'habakkuk': 'habakkuk', 'hab': 'habakkuk',
      'zephaniah': 'zephaniah', 'zeph': 'zephaniah',
      'haggai': 'haggai', 'hag': 'haggai',
      'zechariah': 'zechariah', 'zech': 'zechariah', 'zec': 'zechariah',
      'malachi': 'malachi', 'mal': 'malachi',
      'matthew': 'matthew', 'matt': 'matthew', 'mat': 'matthew', 'mt': 'matthew',
      'mark': 'mark', 'mrk': 'mark', 'mk': 'mark',
      'luke': 'luke', 'luk': 'luke', 'lk': 'luke',
      'john': 'john', 'jhn': 'john', 'jn': 'john',
      'acts': 'acts',
      'romans': 'romans', 'rom': 'romans',
      '1corinthians': '1corinthians', '1cor': '1corinthians',
      '2corinthians': '2corinthians', '2cor': '2corinthians',
      'galatians': 'galatians', 'gal': 'galatians',
      'ephesians': 'ephesians', 'eph': 'ephesians',
      'philippians': 'philippians', 'phil': 'philippians', 'php': 'philippians',
      'colossians': 'colossians', 'col': 'colossians',
      '1thessalonians': '1thessalonians', '1thess': '1thessalonians', '1thes': '1thessalonians',
      '2thessalonians': '2thessalonians', '2thess': '2thessalonians', '2thes': '2thessalonians',
      '1timothy': '1timothy', '1tim': '1timothy',
      '2timothy': '2timothy', '2tim': '2timothy',
      'titus': 'titus', 'tit': 'titus',
      'philemon': 'philemon', 'phlm': 'philemon',
      'hebrews': 'hebrews', 'heb': 'hebrews',
      'james': 'james', 'jas': 'james',
      '1peter': '1peter', '1pet': '1peter', '1pe': '1peter',
      '2peter': '2peter', '2pet': '2peter', '2pe': '2peter',
      '1john': '1john', '1jn': '1john',
      '2john': '2john', '2jn': '2john',
      '3john': '3john', '3jn': '3john',
      'jude': 'jude',
      'revelation': 'revelation', 'rev': 'revelation',
    };
    return aliases[norm];
  }

  // ── Normalization ─────────────────────────────────────────────────────────

  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r"[''']"), "'").replaceAll(RegExp(r'\s+'), ' ').trim();

  // ── Corpus loading ────────────────────────────────────────────────────────

  Future<void> _ensureCorpus(String tl) async {
    if (_corpus.containsKey(tl)) return;
    // deduplicate concurrent loads for the same translation
    _loading[tl] ??= _loadCorpus(tl);
    await _loading[tl];
  }

  Future<void> _loadCorpus(String tl) async {
    final verses = <VerseResult>[];

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final prefix = 'assets/$tl/';

      final paths = manifest.listAssets()
          .where((k) => k.startsWith(prefix) && k.endsWith('.json'))
          .toList();

      for (final path in paths) {
        // path: assets/asr/matthew/3.json
        final parts = path.split('/');
        if (parts.length < 4) continue;
        final bookKey = parts[parts.length - 2];
        final chNum = int.tryParse(parts.last.replaceAll('.json', ''));
        if (chNum == null) continue;

        try {
          final raw = await rootBundle.loadString(path);
          final data = json.decode(raw);
          _parseChapter(data, _displayBook(bookKey), chNum, tl.toUpperCase(), verses);
        } catch (_) {}
      }
    } catch (_) {}

    _corpus[tl] = verses;
    _normalizedCorpus[tl] = verses.map((v) => _norm(v.text)).toList();
  }

  void _parseChapter(
    dynamic data,
    String book,
    int chapter,
    String translation,
    List<VerseResult> out,
  ) {
    if (data is! Map) return;
    final verses = data['verses'];
    if (verses is! Map) return;

    for (final entry in verses.entries) {
      final verseNum = int.tryParse(entry.key.toString()) ?? 0;
      final v = entry.value;
      String text = '';

      if (v is String) {
        text = v;
      } else if (v is Map) {
        if (v.containsKey('segments')) {
          final segs = v['segments'] as List? ?? [];
          text = segs.map((s) => (s is Map ? s['text'] : s) ?? '').join(' ');
        } else {
          text = (v['text'] as String?) ?? '';
        }
      }

      if (text.isNotEmpty) {
        out.add(VerseResult(
          book: book,
          chapter: chapter,
          verse: verseNum,
          text: text,
          translation: translation,
        ));
      }
    }
  }

  // ── Book key → display name ───────────────────────────────────────────────

  String _displayBook(String key) {
    const map = {
      'genesis': 'Genesis', 'exodus': 'Exodus', 'leviticus': 'Leviticus',
      'numbers': 'Numbers', 'deuteronomy': 'Deuteronomy', 'joshua': 'Joshua',
      'judges': 'Judges', 'ruth': 'Ruth', '1samuel': '1 Samuel',
      '2samuel': '2 Samuel', '1kings': '1 Kings', '2kings': '2 Kings',
      '1chronicles': '1 Chronicles', '2chronicles': '2 Chronicles',
      'ezra': 'Ezra', 'nehemiah': 'Nehemiah', 'esther': 'Esther',
      'job': 'Job', 'psalms': 'Psalms', 'proverbs': 'Proverbs',
      'ecclesiastes': 'Ecclesiastes', 'songofsolomon': 'Song of Solomon',
      "solomon'ssong": 'Song of Solomon',
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
    return map[key.toLowerCase()] ?? key;
  }

  void clearCache() {
    _corpus.clear();
    _normalizedCorpus.clear();
    _loading.clear();
  }
}
