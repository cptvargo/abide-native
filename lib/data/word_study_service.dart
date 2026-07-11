import 'dart:convert';
import 'package:flutter/services.dart';
import 'search_models.dart';

// Priority:
//   1. word_studies.json  — fully enriched entries (theological prose + reflection)
//   2. strongs_greek.json / strongs_hebrew.json — raw Strong's fallback (Thayer/Gesenius defs)
//   3. null → SeekService falls through to the Cloudflare Worker

class WordStudyService {
  WordStudyService._();
  static final WordStudyService instance = WordStudyService._();

  Map<String, dynamic>? _enriched;   // word_studies.json
  Map<String, dynamic>? _greek;      // strongs_greek.json  (keyed by "G####")
  Map<String, dynamic>? _hebrew;     // strongs_hebrew.json (keyed by "H####")

  // Reverse index: lowercase english word → list of Strong's numbers
  // Built lazily from kjv_def fields of both lexicons
  Map<String, List<String>>? _index;

  bool _loading = false;

  Future<SeekResult?> lookup(String query, {String translation = 'ASR'}) async {
    await _ensureLoaded();

    final key = query.trim().toLowerCase();

    // ── 1. Enriched entry ────────────────────────────────────────────────────
    final enrichedEntry = _enriched?[key] as Map<String, dynamic>?;
    if (enrichedEntry != null) {
      return await _fromEnriched(enrichedEntry, query.trim(), translation);
    }

    // ── 2. Raw Strong's lookup ────────────────────────────────────────────────
    final strongs = _findStrongs(key);
    if (strongs != null) {
      return await _fromStrongs(strongs.$1, strongs.$2, query.trim(), translation);
    }

    return null;
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_enriched != null) return;
    if (_loading) {
      while (_loading) { await Future.delayed(const Duration(milliseconds: 20)); }
      return;
    }
    _loading = true;
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/data/word_studies.json'),
        rootBundle.loadString('assets/data/strongs_greek.json'),
        rootBundle.loadString('assets/data/strongs_hebrew.json'),
      ]);
      _enriched = json.decode(results[0]) as Map<String, dynamic>;
      _greek = json.decode(results[1]) as Map<String, dynamic>;
      _hebrew = json.decode(results[2]) as Map<String, dynamic>;
      _buildIndex();
    } catch (_) {
      _enriched = {};
      _greek = {};
      _hebrew = {};
    } finally {
      _loading = false;
    }
  }

  void _buildIndex() {
    final idx = <String, List<String>>{};

    void addEntries(Map<String, dynamic> lexicon) {
      for (final entry in lexicon.entries) {
        final num = entry.key;
        final data = entry.value as Map<String, dynamic>?;
        if (data == null) continue;
        final kjv = (data['kjv_def'] as String?) ?? '';
        // extract clean words from the kjv_def
        final words = kjv
            .toLowerCase()
            .replaceAll(RegExp(r'\[.*?\]|\(.*?\)|\{.*?\}'), '')
            .replaceAll(RegExp(r'[^a-z\s\-]'), ' ')
            .split(RegExp(r'[\s,;]+'))
            .map((w) => w.trim())
            .where((w) => w.length > 2);
        for (final w in words) {
          idx.putIfAbsent(w, () => []).add(num);
        }
        // also index the translit / xlit field
        final translit = ((data['translit'] ?? data['xlit']) as String?)
            ?.toLowerCase()
            .replaceAll(RegExp(r'[^a-z]'), '');
        if (translit != null && translit.length > 2) {
          idx.putIfAbsent(translit, () => []).add(num);
        }
      }
    }

    if (_greek != null) addEntries(_greek!);
    if (_hebrew != null) addEntries(_hebrew!);
    _index = idx;
  }

  // Returns (strongsNumber, entry map) for the best match, or null
  (String, Map<String, dynamic>)? _findStrongs(String word) {
    if (_index == null) return null;
    final matches = _index![word];
    if (matches == null || matches.isEmpty) return null;

    // Prefer NT Greek (G) for common theological terms; Hebrew (H) otherwise
    final gMatches = matches.where((m) => m.startsWith('G')).toList();
    final hMatches = matches.where((m) => m.startsWith('H')).toList();
    final pick = gMatches.isNotEmpty ? gMatches.first : hMatches.first;

    final entry = (pick.startsWith('G') ? _greek : _hebrew)?[pick] as Map<String, dynamic>?;
    if (entry == null) return null;
    return (pick, entry);
  }

  // ── Result builders ───────────────────────────────────────────────────────

  Future<SeekResult> _fromEnriched(
      Map<String, dynamic> e, String query, String translation) async {
    final ol = OriginalLanguage(
      language: (e['language'] as String?) ?? 'Greek',
      word: (e['word'] as String?) ?? '',
      transliteration: (e['translit'] as String?) ?? '',
      strongs: (e['strongs'] as String?) ?? '',
      meaning: (e['pronunciation'] as String?) ?? '',
    );

    final refs = ((e['keyVerses'] as List?) ?? []).cast<String>();
    final verses = await Future.wait(refs.map((r) => _fetchVerse(r, translation)));

    return SeekResult(
      type: SeekType.wordStudy,
      word: query,
      originalLanguage: ol,
      definition: e['definition'] as String?,
      significance: e['extendedMeaning'] as String?,
      verses: verses,
      reflection: e['reflection'] as String?,
      fromCache: true,
    );
  }

  Future<SeekResult> _fromStrongs(
      String num, Map<String, dynamic> e, String query, String translation) async {
    final isGreek = num.startsWith('G');
    final lang = isGreek ? 'Greek' : 'Hebrew';
    final word = (e['lemma'] as String?) ?? '';
    final translit = ((e['translit'] ?? e['xlit']) as String?) ?? '';
    final pron = (e['pron'] as String?) ?? '';
    final def = ((e['strongs_def'] as String?) ?? '').trim();

    final ol = OriginalLanguage(
      language: lang,
      word: word,
      transliteration: translit,
      strongs: num,
      meaning: pron,
    );

    // Find verses that contain this English word in the translation
    final verses = await _findVerses(query, translation);

    return SeekResult(
      type: SeekType.wordStudy,
      word: query,
      originalLanguage: ol,
      definition: def.isNotEmpty ? def : null,
      significance: null,
      verses: verses,
      reflection: _templateReflection(query, word, translit, lang),
      fromCache: true,
    );
  }

  String _templateReflection(String query, String original, String translit, String lang) =>
      'As you meditate on the word "$query" — $original ($translit) in $lang — '
      'where do you see this at work in your life today? '
      'How does understanding its original meaning deepen your reading of Scripture?';

  // ── Verse fetching ────────────────────────────────────────────────────────

  // For enriched entries: fetch specific verse by reference
  Future<SeekVerse> _fetchVerse(String ref, String translation) async {
    try {
      final parsed = _parseRef(ref);
      if (parsed == null) return SeekVerse(ref: ref, text: '');
      final tl = translation.toLowerCase();
      final path = 'assets/$tl/${_bookKey(parsed.$1)}/${parsed.$2}.json';
      final raw = await rootBundle.loadString(path);
      final data = json.decode(raw) as Map<String, dynamic>;
      final verses = data['verses'] as Map<String, dynamic>?;
      if (verses == null) return SeekVerse(ref: ref, text: '');
      final v = verses[parsed.$3.toString()];
      return SeekVerse(ref: ref, text: _extractText(v), translation: translation.toUpperCase());
    } catch (_) {
      return SeekVerse(ref: ref, text: '');
    }
  }

  // For raw Strong's entries: search local corpus for top 5 verses containing the word
  Future<List<SeekVerse>> _findVerses(String query, String translation) async {
    try {
      final tl = translation.toLowerCase();
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final prefix = 'assets/$tl/';
      final paths = manifest.listAssets()
          .where((k) => k.startsWith(prefix) && k.endsWith('.json'))
          .take(200) // sample first 200 chapters for speed
          .toList();

      final lq = query.toLowerCase();
      final found = <SeekVerse>[];

      for (final path in paths) {
        if (found.length >= 5) break;
        try {
          final raw = await rootBundle.loadString(path);
          final data = json.decode(raw) as Map<String, dynamic>;
          final verses = data['verses'] as Map<String, dynamic>?;
          if (verses == null) continue;

          final parts = path.split('/');
          final bookKey = parts[parts.length - 2];
          final chapter = int.tryParse(parts.last.replaceAll('.json', '')) ?? 0;
          final book = _displayBook(bookKey);

          for (final entry in verses.entries) {
            final text = _extractText(entry.value);
            if (text.toLowerCase().contains(lq)) {
              final vNum = int.tryParse(entry.key) ?? 0;
              found.add(SeekVerse(
                ref: '$book $chapter:$vNum',
                text: text,
                translation: translation.toUpperCase(),
              ));
              if (found.length >= 5) break;
            }
          }
        } catch (_) {}
      }
      return found;
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _extractText(dynamic v) {
    if (v is String) return v;
    if (v is Map) {
      if (v.containsKey('segments')) {
        return (v['segments'] as List)
            .map((s) => (s is Map ? s['text'] : s) ?? '')
            .join(' ');
      }
      return (v['text'] as String?) ?? '';
    }
    return '';
  }

  (String, int, int)? _parseRef(String ref) {
    final m = RegExp(r'^(.+?)\s+(\d+):(\d+)$').firstMatch(ref.trim());
    if (m == null) return null;
    final ch = int.tryParse(m.group(2)!);
    final v = int.tryParse(m.group(3)!);
    if (ch == null || v == null) return null;
    return (m.group(1)!, ch, v);
  }

  String _bookKey(String book) =>
      book.toLowerCase().replaceAll(' ', '').replaceAll('.', '').replaceAll("'", '');

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
}
