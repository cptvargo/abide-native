import 'package:flutter/painting.dart';

class CRColors {
  static const bg = Color(0xFF0A0806);
  static const bgCard = Color(0xFF130F0A);
  static const gold = Color(0xFFD4A853);
  static const goldDim = Color(0xFF6B5228);
  static const crimson = Color(0xFF8B2020);
  static const parchment = Color(0xFFE8DCC8);
  static const parchmentDim = Color(0xFF8A7A6A);
  static const star = Color(0xFFCDC4B5);
}

class CRTrigger {
  const CRTrigger({required this.chapter, required this.verse});
  final int chapter, verse;

  factory CRTrigger.fromJson(Map<String, dynamic> j) =>
      CRTrigger(chapter: j['chapter'] as int, verse: j['verse'] as int);

  String get key => '$chapter:$verse';
}

class CRObservation {
  const CRObservation({required this.trigger, required this.text});
  final CRTrigger trigger;
  final String text;

  factory CRObservation.fromJson(Map<String, dynamic> j) => CRObservation(
        trigger: CRTrigger.fromJson(j['trigger'] as Map<String, dynamic>),
        text: j['text'] as String,
      );
}

class CRChapterSummary {
  const CRChapterSummary({required this.chapter, required this.text});
  final int chapter;
  final String text;

  factory CRChapterSummary.fromJson(Map<String, dynamic> j) =>
      CRChapterSummary(chapter: j['chapter'] as int, text: j['text'] as String);
}

class CRCrossRef {
  const CRCrossRef({required this.reference, required this.note});
  final String reference, note;

  factory CRCrossRef.fromJson(Map<String, dynamic> j) =>
      CRCrossRef(reference: j['reference'] as String, note: j['note'] as String);
}

class CREvent {
  const CREvent({
    required this.id,
    required this.title,
    required this.chapters,
    required this.christRevealed,
    required this.adversarysMoves,
    required this.chapterSummaries,
    required this.crossReferences,
  });

  final String id, title;
  final List<int> chapters;
  final List<CRObservation> christRevealed;
  final List<CRObservation> adversarysMoves;
  final List<CRChapterSummary> chapterSummaries;
  final List<CRCrossRef> crossReferences;

  factory CREvent.fromJson(Map<String, dynamic> j) => CREvent(
        id: j['id'] as String,
        title: j['title'] as String,
        chapters: List<int>.from(j['chapters'] as List),
        christRevealed: (j['christRevealed'] as List? ?? [])
            .map((e) => CRObservation.fromJson(e as Map<String, dynamic>))
            .toList(),
        adversarysMoves: (j['adversarysMoves'] as List? ?? [])
            .map((e) => CRObservation.fromJson(e as Map<String, dynamic>))
            .toList(),
        chapterSummaries: (j['chapterSummaries'] as List? ?? [])
            .map((e) => CRChapterSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        crossReferences: (j['crossReferences'] as List? ?? [])
            .map((e) => CRCrossRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // All observations for a specific chapter, keyed by verse number
  Map<int, List<({CRObservation obs, bool isChrist})>>
      observationsForChapter(int chapter) {
    final map = <int, List<({CRObservation obs, bool isChrist})>>{};
    for (final o in christRevealed) {
      if (o.trigger.chapter == chapter) {
        (map[o.trigger.verse] ??= []).add((obs: o, isChrist: true));
      }
    }
    for (final o in adversarysMoves) {
      if (o.trigger.chapter == chapter) {
        (map[o.trigger.verse] ??= []).add((obs: o, isChrist: false));
      }
    }
    return map;
  }

  CRChapterSummary? summaryForChapter(int chapter) {
    for (final s in chapterSummaries) {
      if (s.chapter == chapter) return s;
    }
    return null;
  }
}

class CRBook {
  const CRBook({
    required this.book,
    required this.displayName,
    required this.testament,
    required this.events,
  });

  final String book, displayName, testament;
  final List<CREvent> events;

  factory CRBook.fromJson(Map<String, dynamic> j) => CRBook(
        book: j['book'] as String,
        displayName: j['displayName'] as String,
        testament: j['testament'] as String,
        events: (j['events'] as List? ?? [])
            .map((e) => CREvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // All observations across events for a given chapter
  Map<int, List<({CRObservation obs, bool isChrist, String eventTitle})>>
      allObservationsForChapter(int chapter) {
    final map =
        <int, List<({CRObservation obs, bool isChrist, String eventTitle})>>{};
    for (final event in events) {
      final byVerse = event.observationsForChapter(chapter);
      for (final entry in byVerse.entries) {
        for (final item in entry.value) {
          (map[entry.key] ??= [])
              .add((obs: item.obs, isChrist: item.isChrist, eventTitle: event.title));
        }
      }
    }
    return map;
  }

  CRChapterSummary? summaryForChapter(int chapter) {
    for (final event in events) {
      final s = event.summaryForChapter(chapter);
      if (s != null) return s;
    }
    return null;
  }

  List<CRCrossRef> crossRefsForChapter(int chapter) {
    final refs = <CRCrossRef>[];
    for (final event in events) {
      if (event.chapters.contains(chapter)) {
        refs.addAll(event.crossReferences);
      }
    }
    return refs;
  }
}

class CRIndexEntry {
  const CRIndexEntry({
    required this.book,
    required this.displayName,
    required this.testament,
    required this.eventCount,
    required this.available,
  });

  final String book, displayName, testament;
  final int eventCount;
  final bool available;

  factory CRIndexEntry.fromJson(Map<String, dynamic> j) => CRIndexEntry(
        book: j['book'] as String,
        displayName: j['displayName'] as String,
        testament: j['testament'] as String,
        eventCount: j['eventCount'] as int? ?? 0,
        available: j['available'] as bool? ?? false,
      );
}
