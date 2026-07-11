// ── Verse search result ───────────────────────────────────────────────────────

class VerseResult {
  const VerseResult({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.translation,
    this.ref,
    this.score = 0.0,
  });

  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String translation;
  final String? ref;        // pre-formatted from Meilisearch ("Genesis 1:1")
  final double score;

  String get displayRef => ref ?? '$book $chapter:$verse';
}

// ── Seek models ───────────────────────────────────────────────────────────────

class OriginalLanguage {
  const OriginalLanguage({
    required this.language,
    required this.word,
    required this.transliteration,
    required this.strongs,
    required this.meaning,
  });
  final String language;
  final String word;
  final String transliteration;
  final String strongs;
  final String meaning;

  factory OriginalLanguage.fromJson(Map<String, dynamic> j) => OriginalLanguage(
        language: (j['language'] as String?) ?? '',
        word: (j['word'] as String?) ?? '',
        transliteration: (j['transliteration'] as String?) ?? '',
        strongs: (j['strongs'] as String?) ?? '',
        meaning: (j['meaning'] as String?) ?? '',
      );
}

class SeekVerse {
  const SeekVerse({required this.ref, required this.text, this.note, this.translation});
  final String ref;
  final String text;
  final String? note;
  final String? translation;

  factory SeekVerse.fromJson(Map<String, dynamic> j) => SeekVerse(
        ref: (j['ref'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
        note: j['note'] as String?,
        translation: j['translation'] as String?,
      );
}

class SeekExegesis {
  const SeekExegesis({
    required this.passage,
    required this.explanation,
    required this.keyInsight,
  });
  final String passage;
  final String explanation;
  final String keyInsight;

  factory SeekExegesis.fromJson(Map<String, dynamic> j) => SeekExegesis(
        passage: (j['passage'] as String?) ?? '',
        explanation: (j['explanation'] as String?) ?? '',
        keyInsight: (j['keyInsight'] as String?) ?? (j['key_insight'] as String?) ?? '',
      );
}

enum SeekType { wordStudy, question }

class SeekResult {
  const SeekResult({
    required this.type,
    required this.verses,
    this.word,
    this.originalLanguage,
    this.definition,
    this.significance,
    this.question,
    this.answer,
    this.context,
    this.exegesis,
    this.pastoralCaution,
    this.reflection,
    this.fromCache = false,
  });

  final SeekType type;
  final List<SeekVerse> verses;
  final String? word;
  final OriginalLanguage? originalLanguage;
  final String? definition;
  final String? significance;
  final String? question;
  final String? answer;
  final String? context;
  final List<SeekExegesis>? exegesis;
  final String? pastoralCaution;
  final String? reflection;
  final bool fromCache;

  factory SeekResult.fromJson(Map<String, dynamic> j, {bool fromCache = false}) {
    final verses = (j['verses'] as List? ?? [])
        .map((v) => SeekVerse.fromJson(v as Map<String, dynamic>))
        .toList();
    final exegesis = (j['exegesis'] as List?)
        ?.map((e) => SeekExegesis.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasWord = j.containsKey('word') || j.containsKey('originalLanguage');

    if (hasWord) {
      return SeekResult(
        type: SeekType.wordStudy,
        verses: verses,
        word: j['word'] as String?,
        originalLanguage: j['originalLanguage'] != null
            ? OriginalLanguage.fromJson(j['originalLanguage'] as Map<String, dynamic>)
            : null,
        definition: j['definition'] as String?,
        significance: j['significance'] as String?,
        reflection: j['reflection'] as String?,
        fromCache: fromCache,
      );
    } else {
      return SeekResult(
        type: SeekType.question,
        verses: verses,
        question: j['question'] as String?,
        answer: j['answer'] as String?,
        context: j['context'] as String?,
        exegesis: exegesis,
        pastoralCaution: j['pastoralCaution'] as String?,
        reflection: j['reflection'] as String?,
        fromCache: fromCache,
      );
    }
  }

  SeekResult copyWith({bool? fromCache}) => SeekResult(
        type: type,
        verses: verses,
        word: word,
        originalLanguage: originalLanguage,
        definition: definition,
        significance: significance,
        question: question,
        answer: answer,
        context: context,
        exegesis: exegesis,
        pastoralCaution: pastoralCaution,
        reflection: reflection,
        fromCache: fromCache ?? this.fromCache,
      );
}

// ── Highlight ─────────────────────────────────────────────────────────────────

class Highlight {
  const Highlight({
    required this.groupId,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.translation,
    required this.text,
    required this.colorId,
    required this.tags,
    required this.createdAt,
  });

  final String groupId;
  final String book;
  final int chapter;
  final int verse;
  final String translation;
  final String text;
  final String colorId;
  final List<String> tags;
  final DateTime createdAt;

  String get ref => '$book $chapter:$verse';

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'translation': translation,
        'text': text,
        'colorId': colorId,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  Highlight copyWith({String? groupId, String? colorId, List<String>? tags}) => Highlight(
        groupId: groupId ?? this.groupId,
        book: book,
        chapter: chapter,
        verse: verse,
        translation: translation,
        text: text,
        colorId: colorId ?? this.colorId,
        tags: tags ?? this.tags,
        createdAt: createdAt,
      );

  factory Highlight.fromJson(Map<String, dynamic> j) => Highlight(
        groupId: (j['groupId'] as String?) ?? '',
        book: (j['book'] as String?) ?? '',
        chapter: (j['chapter'] as int?) ?? 0,
        verse: (j['verse'] as int?) ?? 0,
        translation: (j['translation'] as String?) ?? 'ASR',
        text: (j['text'] as String?) ?? '',
        colorId: (j['colorId'] as String?) ?? 'gold',
        tags: List<String>.from((j['tags'] as List?) ?? []),
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

// ── Dictionary entry (saved Seek result) ─────────────────────────────────────

class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.savedAt,
    required this.query,
    required this.result,
    this.personalNote = '',
  });

  final String id;
  final DateTime savedAt;
  final String query;
  final SeekResult result;
  final String personalNote;

  String get displayWord => result.word ?? result.question ?? query;

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'query': query,
        'personalNote': personalNote,
        'result': _seekResultToJson(result),
      };

  factory DictionaryEntry.fromJson(Map<String, dynamic> j) => DictionaryEntry(
        id: (j['id'] as String?) ?? '',
        savedAt: DateTime.tryParse((j['savedAt'] as String?) ?? '') ?? DateTime.now(),
        query: (j['query'] as String?) ?? '',
        personalNote: (j['personalNote'] as String?) ?? '',
        result: SeekResult.fromJson((j['result'] as Map<String, dynamic>?) ?? {}),
      );

  DictionaryEntry copyWith({String? personalNote}) => DictionaryEntry(
        id: id,
        savedAt: savedAt,
        query: query,
        result: result,
        personalNote: personalNote ?? this.personalNote,
      );
}

Map<String, dynamic> _seekResultToJson(SeekResult r) => {
      'type': r.type.name,
      'word': r.word,
      'originalLanguage': r.originalLanguage == null
          ? null
          : {
              'language': r.originalLanguage!.language,
              'word': r.originalLanguage!.word,
              'transliteration': r.originalLanguage!.transliteration,
              'strongs': r.originalLanguage!.strongs,
              'meaning': r.originalLanguage!.meaning,
            },
      'definition': r.definition,
      'significance': r.significance,
      'question': r.question,
      'answer': r.answer,
      'context': r.context,
      'exegesis': r.exegesis
          ?.map((e) => {
                'passage': e.passage,
                'explanation': e.explanation,
                'keyInsight': e.keyInsight,
              })
          .toList(),
      'verses': r.verses
          .map((v) => {'ref': v.ref, 'text': v.text, 'note': v.note, 'translation': v.translation})
          .toList(),
      'pastoralCaution': r.pastoralCaution,
      'reflection': r.reflection,
    };
