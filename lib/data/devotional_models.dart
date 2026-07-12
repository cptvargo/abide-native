// ── Devotional data models for text-based devotional series ──────────────────

class DevotionalSeries {
  const DevotionalSeries({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.author,
    required this.description,
    required this.days,
    this.authorNote,
  });

  final String id;
  final String title;
  final String subtitle;
  final String author;
  final String description;
  final int days;
  final String? authorNote;

  factory DevotionalSeries.fromJson(Map<String, dynamic> j) => DevotionalSeries(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        author: j['author'] as String? ?? 'ABIDE',
        description: j['description'] as String? ?? '',
        days: (j['days'] as int?) ?? 1,
        authorNote: j['authorNote'] as String?,
      );
}

class DevotionalDay {
  const DevotionalDay({
    required this.day,
    required this.title,
    required this.reading,
    required this.reflection,
    required this.abide,
    this.scripture,
    this.intro,
    this.scriptures,
  });

  final int day;
  final String title;
  final String reading;
  final String reflection;
  final String abide;
  final String? scripture;   // single scripture reference
  final String? intro;       // optional opening paragraph(s)
  final List<String>? scriptures; // optional multiple references

  /// The primary scripture to feature (single or first of array).
  String? get primaryScripture =>
      scripture ?? (scriptures != null && scriptures!.isNotEmpty ? scriptures!.first : null);

  /// All scripture references combined (primary first, then additional).
  List<String> get allScriptures {
    final refs = <String>[];
    if (scripture != null) refs.add(scripture!);
    if (scriptures != null) {
      for (final s in scriptures!) {
        if (!refs.contains(s)) refs.add(s);
      }
    }
    return refs;
  }

  factory DevotionalDay.fromJson(Map<String, dynamic> j) => DevotionalDay(
        day: (j['day'] as num).toInt(),
        title: j['title'] as String? ?? 'Day ${j['day']}',
        reading: j['reading'] as String? ?? '',
        reflection: j['reflection'] as String? ?? '',
        abide: j['abide'] as String? ?? '',
        scripture: j['scripture'] as String?,
        intro: j['intro'] as String?,
        scriptures:
            (j['scriptures'] as List?)?.map((e) => e as String).toList(),
      );
}

// ── Author metadata (from authors.json) ──────────────────────────────────────

class AuthorInfo {
  const AuthorInfo({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.about,
    this.image,
    this.quote,
  });

  final String name;
  final String subtitle;
  final String description;
  final String about;
  final String? image; // filename only, e.g. "Andrew Murray.png"
  final String? quote;

  factory AuthorInfo.fromJson(Map<String, dynamic> j) => AuthorInfo(
        name: j['name'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        description: j['description'] as String? ?? '',
        about: j['about'] as String? ?? '',
        image: j['image'] as String?,
        quote: j['quote'] as String?,
      );
}

// ── Author group (computed, not from JSON) ────────────────────────────────────

class AuthorGroup {
  const AuthorGroup({
    required this.author,
    required this.series,
  });

  final AuthorInfo author;
  final List<DevotionalSeries> series;

  int get totalDays => series.fold(0, (sum, s) => sum + s.days);
}
