import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/devotional_models.dart';

class DevotionalsService {
  DevotionalsService._();
  static final instance = DevotionalsService._();

  static const _base = 'assets/data/devotionals';

  List<DevotionalSeries>? _indexCache;
  List<AuthorInfo>? _authorsCache;

  Future<List<DevotionalSeries>> loadIndex() async {
    if (_indexCache != null) return _indexCache!;
    final raw = jsonDecode(await rootBundle.loadString('$_base/index.json'))
        as List;
    _indexCache = raw
        .cast<Map<String, dynamic>>()
        .where((e) =>
            e['source'] != 'bible-project' &&
            e['format'] != 'video-daily' &&
            e['format'] != 'scripture-guided')
        .map(DevotionalSeries.fromJson)
        .toList();
    return _indexCache!;
  }

  Future<DevotionalDay> loadDay(String seriesId, int dayNum) async {
    final pad = dayNum.toString().padLeft(2, '0');
    final raw = jsonDecode(
        await rootBundle.loadString('$_base/$seriesId/day$pad.json'));
    return DevotionalDay.fromJson(raw as Map<String, dynamic>);
  }

  Future<List<AuthorInfo>> loadAuthors() async {
    if (_authorsCache != null) return _authorsCache!;
    final raw =
        jsonDecode(await rootBundle.loadString('$_base/authors.json')) as List;
    _authorsCache = raw
        .map((e) => AuthorInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    return _authorsCache!;
  }

  String? getAuthorImageAsset(String? imageFilename) {
    if (imageFilename == null || imageFilename.isEmpty) return null;
    return 'assets/images/$imageFilename';
  }

  Future<List<AuthorGroup>> groupedByAuthor() async {
    final results = await Future.wait([loadIndex(), loadAuthors()]);
    final series = results[0] as List<DevotionalSeries>;
    final authors = results[1] as List<AuthorInfo>;

    final groups = <AuthorGroup>[];
    for (final author in authors) {
      final authorSeries =
          series.where((s) => s.author == author.name).toList();
      if (authorSeries.isNotEmpty) {
        groups.add(AuthorGroup(author: author, series: authorSeries));
      }
    }
    final knownAuthors = authors.map((a) => a.name).toSet();
    final unmatched =
        series.where((s) => !knownAuthors.contains(s.author)).toList();
    if (unmatched.isNotEmpty) {
      groups.add(AuthorGroup(
        author: AuthorInfo(
            name: 'Other',
            subtitle: '',
            description: '',
            about: '',
            image: null,
            quote: null),
        series: unmatched,
      ));
    }
    return groups;
  }

  Future<List<int>> getCompleted(String seriesId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('devotional_completed_$seriesId') ?? [];
    return raw.map(int.parse).toList();
  }

  Future<void> markComplete(String seriesId, int day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'devotional_completed_$seriesId';
    final raw = (prefs.getStringList(key) ?? []).toSet()..add('$day');
    await prefs.setStringList(key, raw.toList());
  }

  bool isDayLocked(int dayNum, List<int> completed) =>
      dayNum > 1 && !completed.contains(dayNum - 1);
}
