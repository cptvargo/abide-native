import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/christ_revealed_models.dart';

class ChristRevealedService {
  ChristRevealedService._();
  static final instance = ChristRevealedService._();

  static const _base = 'assets/data/christ-revealed';

  List<CRIndexEntry>? _indexCache;

  Future<List<CRIndexEntry>> loadIndex() async {
    if (_indexCache != null) return _indexCache!;
    final raw =
        jsonDecode(await rootBundle.loadString('$_base/index.json')) as List;
    _indexCache = raw
        .map((e) => CRIndexEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return _indexCache!;
  }

  Future<CRBook?> loadBook(String bookSlug) async {
    try {
      final raw = jsonDecode(
          await rootBundle.loadString('$_base/$bookSlug.json'));
      return CRBook.fromJson(raw as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cr_intro_seen') ?? false;
  }

  Future<void> markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cr_intro_seen', true);
  }

  Future<List<int>> getCompletedChapters(String book) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('cr_${book}_completed') ?? [];
    return raw.map(int.parse).toList();
  }

  Future<void> markChapterComplete(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cr_${book}_completed';
    final raw = (prefs.getStringList(key) ?? []).toSet()..add('$chapter');
    await prefs.setStringList(key, raw.toList());
  }

  Future<Set<String>> getSeenReveals(String book) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('cr_${book}_seen') ?? []).toSet();
  }

  Future<void> markRevealSeen(String book, String key) async {
    final prefs = await SharedPreferences.getInstance();
    final k = 'cr_${book}_seen';
    final raw = (prefs.getStringList(k) ?? []).toSet()..add(key);
    await prefs.setStringList(k, raw.toList());
  }

  Future<int?> getCurrentChapter(String book) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('cr_${book}_chapter');
  }

  Future<void> saveCurrentChapter(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cr_${book}_chapter', chapter);
  }

  Future<({String book, int chapter})?> getJourneyPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final book = prefs.getString('cr_current_book');
    if (book == null) return null;
    final chapter = prefs.getInt('cr_${book}_chapter') ?? 1;
    return (book: book, chapter: chapter);
  }

  Future<void> saveJourneyPosition(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cr_current_book', book);
    await prefs.setInt('cr_${book}_chapter', chapter);
  }
}
