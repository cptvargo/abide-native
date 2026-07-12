import 'package:flutter/material.dart';
import '../data/daily_abiding_models.dart';
import '../services/daily_abiding_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import '../widgets/verse_sheet.dart';
import 'daily_abiding_screen.dart' show openYouTube;

class ScriptureGuidedScreen extends StatefulWidget {
  const ScriptureGuidedScreen({super.key, required this.series});
  final DailyAbidingSeries series;

  @override
  State<ScriptureGuidedScreen> createState() => _ScriptureGuidedScreenState();
}

class _ScriptureGuidedScreenState extends State<ScriptureGuidedScreen> {
  ScriptureGuidedData? _data;
  bool _loading = true;
  bool _complete = false;
  bool _marking = false;

  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = DailyAbidingService.instance;
    final results = await Future.wait([
      svc.loadScriptureGuided(widget.series.id),
      svc.getCompletedDays(),
    ]);
    if (!mounted) return;
    final data = results[0] as ScriptureGuidedData;
    final completed = results[1] as Set<String>;
    setState(() {
      _data = data;
      _complete = completed.contains('scripture-guided-${widget.series.id}');
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int p) {
    _pageCtrl.animateToPage(p,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic);
    setState(() => _page = p);
  }

  Future<void> _markComplete() async {
    if (_marking || _complete) return;
    setState(() => _marking = true);
    await DailyAbidingService.instance
        .markComplete('scripture-guided-${widget.series.id}');
    if (!mounted) return;
    setState(() {
      _marking = false;
      _complete = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    if (_loading) {
      return AtmosphericBackground(
        baseColor: theme.bgApp,
        accentColor: theme.textAccent,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.textAccent.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final data = _data!;
    final pages = [
      _IntroPage(data: data, theme: theme, onNext: () => _goTo(1)),
      _ReadingPage(data: data, theme: theme, onNext: () => _goTo(2), onBack: () => _goTo(0)),
      _ScripturePage(
        data: data,
        theme: theme,
        onNext: () => _goTo(3),
        onBack: () => _goTo(1),
      ),
      _WorshipPage(data: data, theme: theme, onNext: () => _goTo(4), onBack: () => _goTo(2)),
      _AbidingPage(data: data, theme: theme, onNext: () => _goTo(5), onBack: () => _goTo(3)),
      _FinalAbidePage(
        data: data,
        theme: theme,
        isComplete: _complete,
        marking: _marking,
        onComplete: _markComplete,
        onBack: () => _goTo(4),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Stack(
        children: [
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          ),
          _SGHeader(
            page: _page,
            totalPages: pages.length,
            theme: theme,
            onClose: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ── Scripture Guided Header ───────────────────────────────────────────────────

class _SGHeader extends StatelessWidget {
  const _SGHeader({
    required this.page,
    required this.totalPages,
    required this.theme,
    required this.onClose,
  });

  final int page;
  final int totalPages;
  final AbideThemeData theme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const labels = ['INTRO', 'READING', 'SCRIPTURE', 'WORSHIP', 'ABIDING', 'ABIDE'];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, top + 12, 20, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.bgApp, theme.bgApp.withValues(alpha: 0.0)],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.textAccent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.textAccent.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.close_rounded,
                    size: 16,
                    color: theme.textPrimary.withValues(alpha: 0.6)),
              ),
            ),
            const Spacer(),
            // Dot progress
            Row(
              children: List.generate(totalPages, (i) {
                final active = i == page;
                final past = i < page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: active ? 18 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: active
                        ? theme.textAccent
                        : past
                            ? theme.textAccent.withValues(alpha: 0.45)
                            : theme.textAccent.withValues(alpha: 0.15),
                  ),
                );
              }),
            ),
            const Spacer(),
            SizedBox(
              width: 34,
              child: Text(
                page < labels.length ? labels[page] : '',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: theme.textAccent.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 0: Intro ─────────────────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  const _IntroPage(
      {required this.data, required this.theme, required this.onNext});
  final ScriptureGuidedData data;
  final AbideThemeData theme;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28, top + 72, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✦  DAILY ABIDING',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            data.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: theme.textPrimary,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 15,
              color: theme.textAccent.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ...data.intro.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              p,
              style: TextStyle(
                fontSize: 15.5,
                color: theme.textPrimary.withValues(alpha: 0.78),
                height: 1.7,
              ),
            ),
          )),
          const SizedBox(height: 16),
          _NavBtn(label: 'Begin Reading →', theme: theme, onTap: onNext),
        ],
      ),
    );
  }
}

// ── Page 1: Reading ───────────────────────────────────────────────────────────

class _ReadingPage extends StatelessWidget {
  const _ReadingPage({
    required this.data,
    required this.theme,
    required this.onNext,
    required this.onBack,
  });
  final ScriptureGuidedData data;
  final AbideThemeData theme;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final paragraphs = data.reading.split('\n\n');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28, top + 72, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE READING',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 24),
          ...paragraphs.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(
              p.trim(),
              style: TextStyle(
                fontSize: 15.5,
                color: theme.textPrimary.withValues(alpha: 0.8),
                height: 1.72,
              ),
            ),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              _BackLink(theme: theme, onTap: onBack),
              const Spacer(),
              _NavBtn(label: 'Scripture →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Scripture ─────────────────────────────────────────────────────────

class _ScripturePage extends StatelessWidget {
  const _ScripturePage({
    required this.data,
    required this.theme,
    required this.onNext,
    required this.onBack,
  });
  final ScriptureGuidedData data;
  final AbideThemeData theme;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, top + 72, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'KEY SCRIPTURES',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: theme.textAccent.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 24),
            child: Text(
              'Tap any verse to read it',
              style: TextStyle(
                fontSize: 12,
                color: theme.textPrimary.withValues(alpha: 0.35),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          ...data.scripturePills.map((pill) => GestureDetector(
            onTap: () => showVerseSheet(context, pill.reference),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: theme.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.textAccent.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.textAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: theme.textAccent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      pill.reference,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textAccent,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.textAccent.withValues(alpha: 0.3)),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
          Row(
            children: [
              _BackLink(theme: theme, onTap: onBack),
              const Spacer(),
              _NavBtn(label: 'Worship →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Worship ───────────────────────────────────────────────────────────

class _WorshipPage extends StatelessWidget {
  const _WorshipPage({
    required this.data,
    required this.theme,
    required this.onNext,
    required this.onBack,
  });
  final ScriptureGuidedData data;
  final AbideThemeData theme;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final thumbUrl =
        'https://img.youtube.com/vi/${data.worshipVideoId}/hqdefault.jpg';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28, top + 72, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'WORSHIP',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 24),

          // Prompt
          Text(
            data.worshipPrompt,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: theme.textPrimary.withValues(alpha: 0.75),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Video thumbnail
          GestureDetector(
            onTap: () => openYouTube(data.worshipVideoId),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.textAccent.withValues(alpha: 0.07),
                        height: 180,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Column(
                      children: [
                        Text(
                          data.worshipSong,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                        Text(
                          data.worshipArtist,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 9,
                              color: Colors.white.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            'Watch on YouTube',
                            style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _BackLink(theme: theme, onTap: onBack),
              const Spacer(),
              _NavBtn(label: 'Abide →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 4: Abiding ───────────────────────────────────────────────────────────

class _AbidingPage extends StatelessWidget {
  const _AbidingPage({
    required this.data,
    required this.theme,
    required this.onNext,
    required this.onBack,
  });
  final ScriptureGuidedData data;
  final AbideThemeData theme;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28, top + 72, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABIDING',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Reflect',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          ...data.reflectQuestions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: theme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.textAccent.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1, right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.textAccent.withValues(alpha: 0.35),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textAccent.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      q,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: theme.textPrimary.withValues(alpha: 0.75),
                        height: 1.58,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.textAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.textAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESPOND TODAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: theme.textAccent.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.respond,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: theme.textPrimary.withValues(alpha: 0.78),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _BackLink(theme: theme, onTap: onBack),
              const Spacer(),
              _NavBtn(label: 'Finish →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 5: Final Abide ───────────────────────────────────────────────────────

class _FinalAbidePage extends StatelessWidget {
  const _FinalAbidePage({
    required this.data,
    required this.theme,
    required this.isComplete,
    required this.marking,
    required this.onComplete,
    required this.onBack,
  });
  final ScriptureGuidedData data;
  final AbideThemeData theme;
  final bool isComplete;
  final bool marking;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(36, top + 72, 36, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Text(
            '✦',
            style: TextStyle(
              fontSize: 22,
              color: theme.textAccent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'A B I D E',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 5,
              color: theme.textAccent.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            '"${data.abide}"',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: theme.textPrimary.withValues(alpha: 0.88),
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Text(
            '· · ·',
            style: TextStyle(
              fontSize: 12,
              color: theme.textAccent.withValues(alpha: 0.25),
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'BE STILL AND KNOW',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: theme.textPrimary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 60),
              GestureDetector(
                onTap: isComplete || marking ? null : onComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? theme.textAccent.withValues(alpha: 0.08)
                        : theme.textAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.textAccent
                          .withValues(alpha: isComplete ? 0.3 : 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: marking
                      ? Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: theme.textAccent,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.check_rounded,
                              size: 16,
                              color: theme.textAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isComplete ? 'Experience Complete' : 'I Have Abided',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.textAccent,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onBack,
            child: Text(
              '← Back',
              style: TextStyle(
                fontSize: 12,
                color: theme.textPrimary.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared Nav Widgets ────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  const _NavBtn(
      {required this.label, required this.theme, required this.onTap});
  final String label;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.textAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.textAccent.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.textAccent,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.theme, required this.onTap});
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        '← Back',
        style: TextStyle(
          fontSize: 13,
          color: theme.textPrimary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
