import 'dart:convert';
import 'package:flutter/services.dart';

class BibleSegment {
  const BibleSegment({required this.text, this.isJesus = false});
  final String text;
  final bool isJesus;
}

class BibleVerse {
  const BibleVerse({required this.number, required this.segments});

  final int number;
  final List<BibleSegment> segments;

  factory BibleVerse.simple(int number, String text, {bool isJesus = false}) =>
      BibleVerse(
        number: number,
        segments: [BibleSegment(text: text, isJesus: isJesus)],
      );

  String get text => segments.map((s) => s.text).join();
  bool get isJesus => segments.isNotEmpty && segments.every((s) => s.isJesus);
}

class BibleChapter {
  const BibleChapter({
    required this.book,
    required this.chapter,
    required this.translation,
    required this.verses,
  });
  final String book;
  final int chapter;
  final String translation;
  final List<BibleVerse> verses;
}

class BibleService {
  BibleService._();
  static final BibleService instance = BibleService._();

  final _cache = <String, BibleChapter>{};

  static String bookDisplayName(String slug) {
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
    return map[slug.toLowerCase()] ?? slug;
  }

  static String _bookKey(String bookName, String translation) {
    final key = bookName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('.', '');
    if (translation == 'kjv' && key == 'songofsolomon') return "solomon'ssong";
    return key;
  }

  Future<BibleChapter> loadChapter(
    String translation,
    String book,
    int chapter,
  ) async {
    final tl = translation.toLowerCase();
    final key = '$tl/${_bookKey(book, tl)}/$chapter';
    if (_cache.containsKey(key)) return _cache[key]!;

    final path = 'assets/$tl/${_bookKey(book, tl)}/$chapter.json';
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final versesJson = json['verses'] as Map<String, dynamic>;
    final verses = <BibleVerse>[];

    for (final entry in versesJson.entries) {
      final num = int.tryParse(entry.key) ?? 0;
      final val = entry.value;

      if (val is String) {
        verses.add(BibleVerse.simple(num, val));
      } else if (val is Map<String, dynamic>) {
        if (val.containsKey('segments')) {
          final segs = (val['segments'] as List).map((s) {
            final sm = s as Map<String, dynamic>;
            return BibleSegment(
              text: sm['text'] as String,
              isJesus: sm['speaker'] == 'Jesus',
            );
          }).toList();
          verses.add(BibleVerse(number: num, segments: segs));
        } else {
          final text = (val['text'] as String?) ?? '';
          final speaker = (val['speaker'] as String?) ?? '';
          verses.add(BibleVerse.simple(num, text, isJesus: speaker == 'Jesus'));
        }
      }
    }

    verses.sort((a, b) => a.number.compareTo(b.number));

    final result = BibleChapter(
      book: book,
      chapter: chapter,
      translation: translation.toUpperCase(),
      verses: verses,
    );

    _cache[key] = result;
    return result;
  }
}
