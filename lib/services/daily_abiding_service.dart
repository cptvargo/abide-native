import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/daily_abiding_models.dart';

class DailyAbidingService {
  static final DailyAbidingService instance = DailyAbidingService._();
  DailyAbidingService._();

  List<DailyAbidingSeries>? _index;

  Future<List<DailyAbidingSeries>> loadIndex() async {
    if (_index != null) return _index!;
    final raw = await rootBundle.loadString('assets/data/devotionals/index.json');
    final list = jsonDecode(raw) as List;
    _index = list
        .map((e) => DailyAbidingSeries.fromJson(e as Map<String, dynamic>))
        .where((s) => s.isVideoDaily || s.isScriptureGuided)
        .toList();
    return _index!;
  }

  Future<DailyAbidingSeriesDetail> loadSeriesDetail(String id) async {
    final raw = await rootBundle.loadString(
        'assets/data/devotionals/$id/series.json');
    return DailyAbidingSeriesDetail.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ScriptureGuidedData> loadScriptureGuided(String id) async {
    final raw =
        await rootBundle.loadString('assets/data/devotionals/$id/day.json');
    return ScriptureGuidedData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<Set<String>> getCompletedDays() async {
    final prefs = await SharedPreferences.getInstance();
    return Set.from(prefs.getStringList('abide_daily_completed_v1') ?? []);
  }

  Future<void> markComplete(String dayId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('abide_daily_completed_v1') ?? [];
    if (!list.contains(dayId)) {
      list.add(dayId);
      await prefs.setStringList('abide_daily_completed_v1', list);
    }
  }

  Future<bool> isDayUnlocked(
      DailyAbidingDay day, Set<String> completed) async {
    if (day.unlockAfter == null) return true;
    return completed.contains(day.unlockAfter);
  }
}
