import 'package:flutter/material.dart';
import '../data/daily_abiding_models.dart';
import '../theme/abide_theme.dart';
import '../widgets/verse_sheet.dart';
import '../widgets/youtube_player_card.dart';

class DayExperienceScreen extends StatefulWidget {
  const DayExperienceScreen({
    super.key,
    required this.series,
    required this.detail,
    required this.day,
    required this.completed,
    required this.onComplete,
  });

  final DailyAbidingSeries series;
  final DailyAbidingSeriesDetail detail;
  final DailyAbidingDay day;
  final Set<String> completed;
  final Future<void> Function(String dayId) onComplete;

  @override
  State<DayExperienceScreen> createState() => _DayExperienceScreenState();
}

class _DayExperienceScreenState extends State<DayExperienceScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  int _selectedChoice = -1;
  bool _completing = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _isComplete = widget.completed.contains(widget.day.id);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_page < 2) {
      _pageCtrl.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _page = _page + 1;
        _selectedChoice = -1;
      });
    }
  }

  void _prevPage() {
    if (_page > 0) {
      _pageCtrl.animateToPage(
        _page - 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _page = _page - 1;
        _selectedChoice = -1;
      });
    }
  }

  Future<void> _markComplete() async {
    if (_completing) return;
    setState(() => _completing = true);
    await widget.onComplete(widget.day.id);
    if (!mounted) return;
    setState(() {
      _completing = false;
      _isComplete = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final day = widget.day;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Stack(
        children: [
          // Subtle atmospheric gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    theme.textAccent.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Page content
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _WordPage(day: day, theme: theme, onNext: _nextPage),
              _ReflectPage(
                day: day,
                theme: theme,
                selectedChoice: _selectedChoice,
                onChoiceSelect: (i) => setState(() => _selectedChoice = i),
                onNext: _nextPage,
                onBack: _prevPage,
              ),
              _AbidePage(
                day: day,
                theme: theme,
                isComplete: _isComplete,
                completing: _completing,
                onComplete: _markComplete,
                onBack: _prevPage,
              ),
            ],
          ),

          // Fixed header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(
              day: day,
              page: _page,
              theme: theme,
              onClose: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fixed Header ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.day,
    required this.page,
    required this.theme,
    required this.onClose,
  });

  final DailyAbidingDay day;
  final int page;
  final AbideThemeData theme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final labels = ['THE WORD', 'REFLECT', 'ABIDE'];

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.bgApp,
            theme.bgApp.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // Close button
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

          // Progress dots
          Row(
            children: List.generate(3, (i) {
              final isActive = i == page;
              final isPast = i < page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 5,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? theme.textAccent
                      : isPast
                          ? theme.textAccent.withValues(alpha: 0.45)
                          : theme.textAccent.withValues(alpha: 0.18),
                ),
              );
            }),
          ),

          const Spacer(),

          // Page label
          SizedBox(
            width: 34,
            child: Text(
              labels[page],
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.textAccent.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 0: The Word ──────────────────────────────────────────────────────────

class _WordPage extends StatefulWidget {
  const _WordPage({
    required this.day,
    required this.theme,
    required this.onNext,
  });

  final DailyAbidingDay day;
  final AbideThemeData theme;
  final VoidCallback onNext;

  @override
  State<_WordPage> createState() => _WordPageState();
}

class _WordPageState extends State<_WordPage> {
  bool _showBeliever = true;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final day = widget.day;
    final theme = widget.theme;
    final hasPersonal =
        day.forBeliever != null || day.forUnbeliever != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, top + 72, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Embedded YouTube player
          if (day.videoId.isNotEmpty) ...[
            YoutubePlayerCard(
              videoId: day.videoId,
              autoPlay: false,
            ),
            const SizedBox(height: 28),
          ],

          // Theme tagline
          if (day.theme != null) ...[
            Row(
              children: [
                Container(
                    width: 20, height: 1,
                    color: theme.textAccent.withValues(alpha: 0.4)),
                const SizedBox(width: 10),
                Text(
                  day.theme!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: theme.textAccent.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Reading
          if (day.reading != null) ...[
            Text(
              day.reading!,
              style: TextStyle(
                fontSize: 15.5,
                color: theme.textPrimary.withValues(alpha: 0.82),
                height: 1.7,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Cross reference pills
          if (day.crossRefPills.isNotEmpty) ...[
            Text(
              'ALSO IN SCRIPTURE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: theme.textAccent.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: day.crossRefPills
                  .map((ref) => _PillBadge(
                        text: ref,
                        theme: theme,
                        onTap: () => showVerseSheet(context, ref),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Believer / Seeker
          if (hasPersonal) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: theme.textAccent.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            if (day.forBeliever != null && day.forUnbeliever != null) ...[
              // Tab toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.textAccent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _TabBtn(
                        label: 'For the Believer',
                        active: _showBeliever,
                        theme: theme,
                        onTap: () =>
                            setState(() => _showBeliever = true)),
                    _TabBtn(
                        label: 'For the Seeker',
                        active: !_showBeliever,
                        theme: theme,
                        onTap: () =>
                            setState(() => _showBeliever = false)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _PersonalBlock(
                  key: ValueKey(_showBeliever),
                  text: _showBeliever ? day.forBeliever! : day.forUnbeliever!,
                  theme: theme,
                ),
              ),
            ] else if (day.forBeliever != null) ...[
              _PersonalBlock(text: day.forBeliever!, theme: theme),
            ] else if (day.forUnbeliever != null) ...[
              _PersonalBlock(text: day.forUnbeliever!, theme: theme),
            ],
            const SizedBox(height: 8),
          ],

          // Next button
          const SizedBox(height: 24),
          _NextButton(label: 'Reflect →', theme: theme, onTap: widget.onNext),
        ],
      ),
    );
  }
}

// ── Page 1: Reflect ───────────────────────────────────────────────────────────

class _ReflectPage extends StatelessWidget {
  const _ReflectPage({
    required this.day,
    required this.theme,
    required this.selectedChoice,
    required this.onChoiceSelect,
    required this.onNext,
    required this.onBack,
  });

  final DailyAbidingDay day;
  final AbideThemeData theme;
  final int selectedChoice;
  final void Function(int) onChoiceSelect;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final reflection = day.reflection;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, top + 72, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
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
          const SizedBox(height: 20),

          // Prompt
          Text(
            reflection.prompt,
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: theme.textPrimary,
              height: 1.5,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 32),

          // Choice cards
          ...reflection.choices.asMap().entries.map((entry) {
            final i = entry.key;
            final choice = entry.value;
            final isSelected = selectedChoice == i;

            return GestureDetector(
              onTap: () => onChoiceSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.textAccent.withValues(alpha: 0.09)
                      : theme.surface.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? theme.textAccent.withValues(alpha: 0.45)
                        : theme.textAccent.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Radio circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.textAccent
                                  : theme.textAccent.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.textAccent,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            choice.label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: theme.textPrimary.withValues(
                                  alpha: isSelected ? 0.95 : 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Deep question
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      firstCurve: Curves.easeOut,
                      secondCurve: Curves.easeIn,
                      sizeCurve: Curves.easeOutCubic,
                      crossFadeState: isSelected
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.only(top: 14, left: 30),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                  color: theme.textAccent
                                      .withValues(alpha: 0.4),
                                  width: 2),
                            ),
                          ),
                          child: Text(
                            choice.deepQuestion,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontStyle: FontStyle.italic,
                              color: theme.textPrimary.withValues(alpha: 0.7),
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Text(
                  '← Back',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textPrimary.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const Spacer(),
              _NextButton(label: 'Abide →', theme: theme, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Abide ─────────────────────────────────────────────────────────────

class _AbidePage extends StatelessWidget {
  const _AbidePage({
    required this.day,
    required this.theme,
    required this.isComplete,
    required this.completing,
    required this.onComplete,
    required this.onBack,
  });

  final DailyAbidingDay day;
  final AbideThemeData theme;
  final bool isComplete;
  final bool completing;
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
          const SizedBox(height: 24),

          Text(
            'A B I D E',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 5,
              color: theme.textAccent.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 36),

          Text(
            '"${day.abide}"',
            style: TextStyle(
              fontSize: 19,
              fontStyle: FontStyle.italic,
              color: theme.textPrimary.withValues(alpha: 0.88),
              height: 1.7,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),
          Text(
            '· · ·',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 6,
              color: theme.textAccent.withValues(alpha: 0.25),
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
                onTap: isComplete || completing ? null : onComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? theme.textAccent.withValues(alpha: 0.1)
                        : theme.textAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.textAccent.withValues(
                          alpha: isComplete ? 0.35 : 0.5),
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
                              size: 16,
                              color: theme.textAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isComplete ? 'Session Complete' : 'Mark Today Complete',
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
                  '← Back to Reflection',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textPrimary.withValues(alpha: 0.3),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.text, required this.theme, this.onTap});
  final String text;
  final AbideThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: theme.textAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.textAccent.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: theme.textAccent.withValues(alpha: 0.8),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 13,
                  color: theme.textAccent.withValues(alpha: 0.4)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PersonalBlock extends StatelessWidget {
  const _PersonalBlock({super.key, required this.text, required this.theme});
  final String text;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.textAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
              color: theme.textAccent.withValues(alpha: 0.45), width: 2.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: theme.textPrimary.withValues(alpha: 0.75),
          height: 1.6,
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.active,
    required this.theme,
    required this.onTap,
  });
  final String label;
  final bool active;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? theme.textAccent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active
                  ? theme.textAccent
                  : theme.textPrimary.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton(
      {required this.label, required this.theme, required this.onTap});
  final String label;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
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
