import 'package:flutter/material.dart';
import '../data/devotional_models.dart';
import '../services/devotionals_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/verse_sheet.dart';

enum _PageType { intro, word, reading, reflect, abide }

class DevotionalReaderScreen extends StatefulWidget {
  const DevotionalReaderScreen({
    super.key,
    required this.seriesId,
    required this.day,
    required this.initiallyComplete,
  });

  final String seriesId;
  final DevotionalDay day;
  final bool initiallyComplete;

  @override
  State<DevotionalReaderScreen> createState() =>
      _DevotionalReaderScreenState();
}

class _DevotionalReaderScreenState extends State<DevotionalReaderScreen> {
  late final PageController _pageCtrl;
  late final List<_PageType> _pages;
  int _currentPage = 0;
  bool _isComplete = false;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _isComplete = widget.initiallyComplete;
    _pages = [
      if (widget.day.intro != null) _PageType.intro,
      _PageType.word,
      _PageType.reading,
      _PageType.reflect,
      _PageType.abide,
    ];
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = index);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) _goTo(_currentPage + 1);
  }

  void _prev() {
    if (_currentPage > 0) _goTo(_currentPage - 1);
  }

  Future<void> _markComplete() async {
    if (_completing || _isComplete) return;
    setState(() => _completing = true);
    await DevotionalsService.instance
        .markComplete(widget.seriesId, widget.day.day);
    if (!mounted) return;
    setState(() {
      _completing = false;
      _isComplete = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pop(context);
  }

  static const Map<_PageType, String> _labels = {
    _PageType.intro: 'INTRO',
    _PageType.word: 'THE WORD',
    _PageType.reading: 'THE READING',
    _PageType.reflect: 'REFLECT',
    _PageType.abide: 'ABIDE',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final day = widget.day;
    final pageType = _pages[_currentPage];

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Stack(
        children: [
          // Atmospheric radial glow
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, -0.7),
                    radius: 1.2,
                    colors: [
                      theme.textAccent.withValues(alpha: 0.045),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Page content
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages.map((p) {
              return switch (p) {
                _PageType.intro => _IntroPage(
                    day: day, theme: theme, onNext: _next),
                _PageType.word => _WordPage(
                    day: day,
                    theme: theme,
                    hasPrev: _pages.first != _PageType.word,
                    onNext: _next,
                    onBack: _prev,
                  ),
                _PageType.reading => _ReadingPage(
                    day: day, theme: theme, onNext: _next, onBack: _prev),
                _PageType.reflect => _ReflectPage(
                    day: day, theme: theme, onNext: _next, onBack: _prev),
                _PageType.abide => _AbidePage(
                    day: day,
                    theme: theme,
                    isComplete: _isComplete,
                    completing: _completing,
                    onComplete: _markComplete,
                    onBack: _prev,
                  ),
              };
            }).toList(),
          ),

          // Fixed floating header
          Positioned(
            top: 0, left: 0, right: 0,
            child: _Header(
              pageCount: _pages.length,
              currentPage: _currentPage,
              pageLabel: _labels[pageType] ?? '',
              theme: theme,
              onClose: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fixed Floating Header ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.pageCount,
    required this.currentPage,
    required this.pageLabel,
    required this.theme,
    required this.onClose,
  });

  final int pageCount;
  final int currentPage;
  final String pageLabel;
  final AbideThemeData theme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.bgApp,
            theme.bgApp.withValues(alpha: 0.85),
            theme.bgApp.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.textAccent.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border:
                    Border.all(color: theme.textAccent.withValues(alpha: 0.18)),
              ),
              child: Icon(Icons.close_rounded,
                  size: 15,
                  color: theme.textPrimary.withValues(alpha: 0.55)),
            ),
          ),

          const Spacer(),

          // Progress dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(pageCount, (i) {
              final isActive = i == currentPage;
              final isPast = i < currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isActive ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? theme.textAccent
                      : isPast
                          ? theme.textAccent.withValues(alpha: 0.42)
                          : theme.textAccent.withValues(alpha: 0.16),
                ),
              );
            }),
          ),

          const Spacer(),

          // Page label
          SizedBox(
            width: 34,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                pageLabel,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: theme.textAccent.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 0 (optional): INTRO ──────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.day,
    required this.theme,
    required this.onNext,
  });

  final DevotionalDay day;
  final AbideThemeData theme;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final paragraphs = (day.intro ?? '')
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28, top + 68, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Day number
          Text(
            'DAY ${day.day}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: theme.textAccent.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Day title
          Text(
            day.title,
            style: theme.bodyFont(26).copyWith(
              color: theme.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Ornament
          Text(
            '✦',
            style: TextStyle(
              fontSize: 18,
              color: theme.textAccent.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 32),

          // Intro paragraphs — large italic, generous breathing
          for (final para in paragraphs) ...[
            Text(
              para,
              style: theme.bodyFont(17).copyWith(
                color: theme.textPrimary.withValues(alpha: 0.80),
                height: 1.90,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 22),
          ],

          const SizedBox(height: 12),
          _NavButton(
            label: 'The Word →',
            theme: theme,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Page: THE WORD ────────────────────────────────────────────────────────────

class _WordPage extends StatelessWidget {
  const _WordPage({
    required this.day,
    required this.theme,
    required this.hasPrev,
    required this.onNext,
    required this.onBack,
  });

  final DevotionalDay day;
  final AbideThemeData theme;
  final bool hasPrev;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final primary = day.primaryScripture;
    final allRefs = day.allScriptures;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, top + 68, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Section eyebrow
          Text(
            '✦  THE WORD',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          Container(
              width: 32, height: 1.5,
              color: theme.textAccent.withValues(alpha: 0.3)),
          const SizedBox(height: 28),

          // Primary scripture card
          if (primary != null)
            GestureDetector(
              onTap: () => showVerseSheet(context, primary),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: theme.textAccent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.textAccent.withValues(alpha: 0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.textAccent.withValues(alpha: 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      primary,
                      style: theme.bodyFont(28).copyWith(
                        color: theme.textAccent,
                        height: 1.25,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 24,
                      height: 1,
                      color: theme.textAccent.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Open in Scripture',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.textAccent.withValues(alpha: 0.55),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.chevron_right_rounded,
                            size: 14,
                            color: theme.textAccent.withValues(alpha: 0.4)),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: theme.textAccent.withValues(alpha: 0.1)),
              ),
              child: Text(
                'Open your Bible and sit with the Word.',
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: theme.textPrimary.withValues(alpha: 0.4),
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 40),
          Row(
            children: [
              if (hasPrev)
                GestureDetector(
                  onTap: onBack,
                  child: Text(
                    '← Back',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textPrimary.withValues(alpha: 0.32),
                    ),
                  ),
                ),
              const Spacer(),
              _NavButton(label: 'The Reading →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page: THE READING ─────────────────────────────────────────────────────────

class _ReadingPage extends StatelessWidget {
  const _ReadingPage({
    required this.day,
    required this.theme,
    required this.onNext,
    required this.onBack,
  });

  final DevotionalDay day;
  final AbideThemeData theme;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final paragraphs = day.reading
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28, top + 68, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section eyebrow
          Text(
            '✦  THE READING',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
              width: 32, height: 1.5,
              color: theme.textAccent.withValues(alpha: 0.3)),
          const SizedBox(height: 28),

          // Reading paragraphs — beautifully typeset
          for (final para in paragraphs) ...[
            Text(
              para,
              style: theme.bodyFont(19).copyWith(
                color: theme.textPrimary.withValues(alpha: 0.86),
                height: 1.92,
              ),
            ),
            const SizedBox(height: 26),
          ],

          // Visual separator
          Center(
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 14,
                color: theme.textAccent.withValues(alpha: 0.25),
              ),
            ),
          ),
          const SizedBox(height: 36),

          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Text(
                  '← The Word',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textPrimary.withValues(alpha: 0.32),
                  ),
                ),
              ),
              const Spacer(),
              _NavButton(label: 'Reflect →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page: REFLECT ─────────────────────────────────────────────────────────────

class _ReflectPage extends StatelessWidget {
  const _ReflectPage({
    required this.day,
    required this.theme,
    required this.onNext,
    required this.onBack,
  });

  final DevotionalDay day;
  final AbideThemeData theme;
  final VoidCallback onNext;
  final VoidCallback onBack;

  List<String> _parseQuestions() {
    final raw = day.reflection.trim();
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return lines.isEmpty ? [raw] : lines;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final questions = _parseQuestions();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, top + 68, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Text(
            '✦  REFLECT',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          Container(
              width: 32, height: 1.5,
              color: theme.textAccent.withValues(alpha: 0.3)),
          const SizedBox(height: 28),

          // Question cards
          ...questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return _QuestionCard(
              number: i + 1,
              question: q,
              theme: theme,
            );
          }),

          const SizedBox(height: 28),
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Text(
                  '← The Reading',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textPrimary.withValues(alpha: 0.32),
                  ),
                ),
              ),
              const Spacer(),
              _NavButton(label: 'Abide →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page: ABIDE ───────────────────────────────────────────────────────────────

class _AbidePage extends StatelessWidget {
  const _AbidePage({
    required this.day,
    required this.theme,
    required this.isComplete,
    required this.completing,
    required this.onComplete,
    required this.onBack,
  });

  final DevotionalDay day;
  final AbideThemeData theme;
  final bool isComplete;
  final bool completing;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(36, top + 68, 36, bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          // Eyebrow label
          Text(
            'ABIDE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 5,
              color: theme.textAccent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 28),

          // Top vertical gradient line — fades down to accent
          Container(
            width: 1,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.textAccent.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Prayer text
          Text(
            '"${day.abide}"',
            style: theme.bodyFont(18).copyWith(
              color: theme.textPrimary.withValues(alpha: 0.75),
              height: 1.9,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Bottom vertical gradient line — fades up to accent
          Container(
            width: 1,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.transparent,
                  theme.textAccent.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // "Be still" caption
          Text(
            'BE STILL AND KNOW',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: theme.textPrimary.withValues(alpha: 0.15),
            ),
          ),

          const SizedBox(height: 52),

          // Mark complete button
          GestureDetector(
            onTap: isComplete || completing ? null : onComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isComplete
                    ? theme.textAccent.withValues(alpha: 0.08)
                    : theme.textAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.textAccent
                      .withValues(alpha: isComplete ? 0.32 : 0.52),
                  width: 1.5,
                ),
              ),
              child: completing
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
                          size: 17,
                          color: theme.textAccent,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          isComplete ? 'Complete ✓' : 'Mark Complete',
                          style: TextStyle(
                            fontSize: 14.5,
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
              '← Back to Reflection',
              style: TextStyle(
                fontSize: 12,
                color: theme.textPrimary.withValues(alpha: 0.28),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton(
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
          color: theme.textAccent.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.textAccent.withValues(alpha: 0.32), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.textAccent,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ScripturePill extends StatelessWidget {
  const _ScripturePill(
      {required this.reference, required this.theme, required this.onTap});
  final String reference;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.textAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.textAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reference,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textAccent.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 13,
                color: theme.textAccent.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard(
      {required this.number, required this.question, required this.theme});
  final int number;
  final String question;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.textAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number circle
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1, right: 14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.textAccent.withValues(alpha: 0.1),
              border:
                  Border.all(color: theme.textAccent.withValues(alpha: 0.28)),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.textAccent.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          // Question text
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: theme.textPrimary.withValues(alpha: 0.82),
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
