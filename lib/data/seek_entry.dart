import 'dart:convert';
import 'package:flutter/services.dart';

class SeekSource {
  final String author;
  final String quote;

  const SeekSource({required this.author, required this.quote});

  factory SeekSource.fromJson(Map<String, dynamic> j) => SeekSource(
        author: j['author'] as String,
        quote: j['quote'] as String,
      );
}

class SeekEntry {
  final String id;
  final String question;
  final List<String> topics;
  final String shortAnswer;
  final String? expanded;
  final List<String> refs;
  final List<SeekSource> sources;
  final List<String> related;

  const SeekEntry({
    required this.id,
    required this.question,
    required this.topics,
    required this.shortAnswer,
    this.expanded,
    required this.refs,
    required this.sources,
    required this.related,
  });

  factory SeekEntry.fromJson(Map<String, dynamic> j) => SeekEntry(
        id: j['id'] as String,
        question: j['question'] as String,
        topics: List<String>.from(j['topics'] as List? ?? []),
        shortAnswer: j['short_answer'] as String,
        expanded: j['expanded'] as String?,
        refs: List<String>.from(j['refs'] as List? ?? []),
        sources: (j['sources'] as List? ?? [])
            .map((s) => SeekSource.fromJson(s as Map<String, dynamic>))
            .toList(),
        related: List<String>.from(j['related'] as List? ?? []),
      );
}

class SeekIndexService {
  SeekIndexService._();
  static final SeekIndexService instance = SeekIndexService._();

  List<SeekEntry>? _cache;

  Future<List<SeekEntry>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/seek/entries.json');
    final list = json.decode(raw) as List;
    _cache = list
        .map((e) => SeekEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<SeekEntry>> search(String query, List<SeekEntry> all) async {
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    final words = q.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    final scored = <(int, SeekEntry)>[];

    for (final e in all) {
      int score = 0;
      final ql = e.question.toLowerCase();
      final al = e.shortAnswer.toLowerCase();
      final tl = e.topics.map((t) => t.toLowerCase()).join(' ');

      // Exact phrase in question = highest
      if (ql.contains(q)) score += 20;

      // Word hits in question
      for (final w in words) {
        if (ql.contains(w)) score += 5;
        if (tl.contains(w)) score += 3;
        if (al.contains(w)) score += 1;
      }

      if (score > 0) scored.add((score, e));
    }

    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.map((s) => s.$2).toList();
  }

  Future<List<SeekEntry>> byTopic(String topic, List<SeekEntry> all) async {
    return all.where((e) => e.topics.contains(topic)).toList();
  }

  SeekEntry? byId(String id, List<SeekEntry> all) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
