class DailyAbidingSeries {
  const DailyAbidingSeries({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.author,
    this.format,
    this.coverImage,
    this.coverVideoId,
    this.days = 1,
    this.source,
    this.group,
    this.featured = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String author;
  final String? format;
  final String? coverImage;
  final String? coverVideoId;
  final int days;
  final String? source;
  final String? group;
  final bool featured;

  bool get isVideoDaily => format == 'video-daily';
  bool get isScriptureGuided => format == 'scripture-guided';
  bool get isBibleProject => source == 'bible-project';

  factory DailyAbidingSeries.fromJson(Map<String, dynamic> j) =>
      DailyAbidingSeries(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        description: j['description'] as String? ?? '',
        author: j['author'] as String? ?? 'ABIDE',
        format: j['format'] as String?,
        coverImage: j['coverImage'] as String?,
        coverVideoId: j['coverVideoId'] as String?,
        days: (j['days'] ?? j['dayCount'] ?? 1) as int,
        source: j['source'] as String?,
        group: j['group'] as String?,
        featured: j['featured'] as bool? ?? false,
      );
}

class DailyAbidingChoice {
  const DailyAbidingChoice({required this.label, required this.deepQuestion});
  final String label;
  final String deepQuestion;

  factory DailyAbidingChoice.fromJson(Map<String, dynamic> j) =>
      DailyAbidingChoice(
        label: j['label'] as String,
        deepQuestion: j['deepQuestion'] as String,
      );
}

class DailyAbidingReflection {
  const DailyAbidingReflection({required this.prompt, required this.choices});
  final String prompt;
  final List<DailyAbidingChoice> choices;

  factory DailyAbidingReflection.fromJson(Map<String, dynamic> j) =>
      DailyAbidingReflection(
        prompt: j['prompt'] as String,
        choices: (j['choices'] as List)
            .map((c) => DailyAbidingChoice.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class DailyAbidingDay {
  const DailyAbidingDay({
    required this.id,
    required this.title,
    required this.subtitle,
    this.theme,
    required this.videoId,
    required this.crossRefPills,
    this.reading,
    this.forBeliever,
    this.forUnbeliever,
    required this.reflection,
    required this.abide,
    this.unlockAfter,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? theme;
  final String videoId;
  final List<String> crossRefPills;
  final String? reading;
  final String? forBeliever;
  final String? forUnbeliever;
  final DailyAbidingReflection reflection;
  final String abide;
  final String? unlockAfter;

  factory DailyAbidingDay.fromJson(Map<String, dynamic> j,
      {String fallbackVideoId = ''}) =>
      DailyAbidingDay(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        theme: j['theme'] as String?,
        videoId: (j['videoId'] as String?) ?? fallbackVideoId,
        crossRefPills: (j['crossRefPills'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        reading: j['reading'] as String?,
        forBeliever: j['forBeliever'] as String?,
        forUnbeliever: j['forUnbeliever'] as String?,
        reflection: DailyAbidingReflection.fromJson(
            j['reflection'] as Map<String, dynamic>),
        abide: j['abide'] as String? ?? '',
        unlockAfter: j['unlockAfter'] as String?,
      );
}

class DailyAbidingSeriesDetail {
  const DailyAbidingSeriesDetail({
    required this.seriesTitle,
    required this.subtitle,
    required this.description,
    required this.days,
    this.seriesVideoId,
  });

  final String seriesTitle;
  final String subtitle;
  final String description;
  final List<DailyAbidingDay> days;
  final String? seriesVideoId;

  factory DailyAbidingSeriesDetail.fromJson(Map<String, dynamic> j) {
    final fallbackVideoId = j['videoId'] as String? ?? '';
    return DailyAbidingSeriesDetail(
      seriesTitle: j['seriesTitle'] as String,
      subtitle: j['subtitle'] as String? ?? '',
      description: j['description'] as String? ?? '',
      seriesVideoId: j['videoId'] as String?,
      days: (j['days'] as List)
          .map((d) => DailyAbidingDay.fromJson(d as Map<String, dynamic>,
              fallbackVideoId: fallbackVideoId))
          .toList(),
    );
  }
}

// ── Scripture Guided ──────────────────────────────────────────────────────────

class ScripturePill {
  const ScripturePill({required this.reference, required this.text});
  final String reference;
  final String text;

  factory ScripturePill.fromJson(Map<String, dynamic> j) => ScripturePill(
        reference: j['reference'] as String,
        text: j['text'] as String,
      );
}

class ScriptureGuidedData {
  const ScriptureGuidedData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.reading,
    required this.scripturePills,
    required this.worshipVideoId,
    required this.worshipPrompt,
    required this.worshipSong,
    required this.worshipArtist,
    required this.reflectQuestions,
    required this.respond,
    required this.abide,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> intro;
  final String reading;
  final List<ScripturePill> scripturePills;
  final String worshipVideoId;
  final String worshipPrompt;
  final String worshipSong;
  final String worshipArtist;
  final List<String> reflectQuestions;
  final String respond;
  final String abide;

  factory ScriptureGuidedData.fromJson(Map<String, dynamic> j) {
    final worship = j['worship'] as Map<String, dynamic>;
    final abiding = j['abiding'] as Map<String, dynamic>;
    return ScriptureGuidedData(
      id: j['id'] as String,
      title: j['title'] as String,
      subtitle: j['subtitle'] as String? ?? '',
      intro: (j['intro'] as List).map((e) => e as String).toList(),
      reading: j['reading'] as String,
      scripturePills: (j['scripturePills'] as List)
          .map((p) => ScripturePill.fromJson(p as Map<String, dynamic>))
          .toList(),
      worshipVideoId: worship['videoId'] as String,
      worshipPrompt: worship['prompt'] as String,
      worshipSong: worship['song'] as String,
      worshipArtist: worship['artist'] as String,
      reflectQuestions:
          (abiding['reflect'] as List).map((e) => e as String).toList(),
      respond: abiding['respond'] as String,
      abide: j['abide'] as String,
    );
  }
}
