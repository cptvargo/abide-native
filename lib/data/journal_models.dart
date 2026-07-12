import 'dart:convert';

enum JournalEntryType { sundayService, timeWithGod, reflection, spontaneous }

extension JournalEntryTypeX on JournalEntryType {
  String get label => switch (this) {
        JournalEntryType.sundayService => 'Sunday Service',
        JournalEntryType.timeWithGod => 'Time with God',
        JournalEntryType.reflection => 'Reflection',
        JournalEntryType.spontaneous => 'Spontaneous',
      };

  // Fixed accent colors — consistent across all themes
  int get colorValue => switch (this) {
        JournalEntryType.sundayService => 0xFF7B8AC8,   // periwinkle
        JournalEntryType.timeWithGod => 0xFF6BAA82,     // sage
        JournalEntryType.reflection => 0xFFC87BA0,      // soft rose
        JournalEntryType.spontaneous => 0xFFD4A843,     // gold
      };
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.body,
    required this.type,
    this.scriptureBook,
    this.scriptureChapter,
    this.scriptureVerseRange,
    this.scriptureText,
    this.translation,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String body;
  final JournalEntryType type;
  final String? scriptureBook;
  final int? scriptureChapter;
  final String? scriptureVerseRange;
  final String? scriptureText;
  final String? translation;

  bool get hasScripture => scriptureBook != null;

  String? get scriptureRef {
    if (scriptureBook == null) return null;
    if (scriptureChapter == null) return scriptureBook;
    if (scriptureVerseRange == null) return '$scriptureBook $scriptureChapter';
    return '$scriptureBook $scriptureChapter:$scriptureVerseRange';
  }

  // First non-empty line, used as the card title
  String get title {
    for (final line in body.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) return t.length > 72 ? '${t.substring(0, 72)}…' : t;
    }
    return type.label;
  }

  // Rest of the body after the title line, used as preview
  String get preview {
    final lines = body.split('\n');
    final rest = lines.skipWhile((l) => l.trim().isEmpty).skip(1).join(' ').trim();
    return rest.length > 140 ? '${rest.substring(0, 140)}…' : rest;
  }

  int get wordCount =>
      body.trim().isEmpty ? 0 : body.trim().split(RegExp(r'\s+')).length;

  JournalEntry copyWith({
    String? body,
    JournalEntryType? type,
    String? scriptureBook,
    int? scriptureChapter,
    String? scriptureVerseRange,
    String? scriptureText,
    String? translation,
    bool clearScripture = false,
  }) =>
      JournalEntry(
        id: id,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        body: body ?? this.body,
        type: type ?? this.type,
        scriptureBook: clearScripture ? null : (scriptureBook ?? this.scriptureBook),
        scriptureChapter: clearScripture ? null : (scriptureChapter ?? this.scriptureChapter),
        scriptureVerseRange:
            clearScripture ? null : (scriptureVerseRange ?? this.scriptureVerseRange),
        scriptureText: clearScripture ? null : (scriptureText ?? this.scriptureText),
        translation: clearScripture ? null : (translation ?? this.translation),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'body': body,
        'type': type.name,
        if (scriptureBook != null) 'scriptureBook': scriptureBook,
        if (scriptureChapter != null) 'scriptureChapter': scriptureChapter,
        if (scriptureVerseRange != null) 'scriptureVerseRange': scriptureVerseRange,
        if (scriptureText != null) 'scriptureText': scriptureText,
        if (translation != null) 'translation': translation,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) {
    final typeStr = (j['type'] as String?) ?? 'spontaneous';
    final type = JournalEntryType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => JournalEntryType.spontaneous,
    );
    return JournalEntry(
      id: (j['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse((j['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      body: (j['body'] as String?) ?? '',
      type: type,
      scriptureBook: j['scriptureBook'] as String?,
      scriptureChapter: j['scriptureChapter'] as int?,
      scriptureVerseRange: j['scriptureVerseRange'] as String?,
      scriptureText: j['scriptureText'] as String?,
      translation: j['translation'] as String?,
    );
  }
}
