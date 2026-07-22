import 'dart:io';
import 'package:flutter/material.dart';
import '../data/daily_abiding_models.dart';
import '../data/devotional_models.dart';
import '../services/daily_abiding_service.dart';
import '../services/devotionals_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'daily_series_detail_screen.dart';
import 'devotional_series_screen.dart';
import 'scripture_guided_screen.dart';

const _planColors = {
  'beauty-of-holiness': Color(0xFFCBB27C),
  'beauty-of-holiness-kids': Color(0xFF8A9E5C),
  'discipleship-guide': Color(0xFF7EB5D0),
  'validated-by-god': Color(0xFFB8906A),
  'lucifer-light-and-fall': Color(0xFFB83232),
  'seven-spirits-of-god': Color(0xFF7ED0D8),
  'fear-of-god': Color(0xFFF97316),
  'slow-to-anger': Color(0xFF8A9E5C),
};

class DailyAbidingScreen extends StatefulWidget {
  const DailyAbidingScreen({super.key});

  @override
  State<DailyAbidingScreen> createState() => _DailyAbidingScreenState();
}

class _DailyAbidingScreenState extends State<DailyAbidingScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  List<DailyAbidingSeries>? _series;
  List<DevotionalSeries>? _readingPlans;
  Map<String, List<int>> _planCompletions = {};
  Set<String> _completed = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        DailyAbidingService.instance.loadIndex(),
        DailyAbidingService.instance.getCompletedDays(),
        DevotionalsService.instance.loadIndex(),
      ]);
      final series = results[0] as List<DailyAbidingSeries>;
      final completed = results[1] as Set<String>;
      final plans = results[2] as List<DevotionalSeries>;
      final completionLists = await Future.wait(
        plans.map((p) => DevotionalsService.instance.getCompleted(p.id)),
      );
      if (!mounted) return;
      setState(() {
        _series = series;
        _completed = completed;
        _readingPlans = plans;
        _planCompletions = {
          for (var i = 0; i < plans.length; i++) plans[i].id: completionLists[i],
        };
        _error = null;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  DailyAbidingSeries? get _featured =>
      _series?.firstWhere((s) => s.featured,
          orElse: () => _series!.firstWhere(
              (s) => s.isVideoDaily && !s.isBibleProject,
              orElse: () => _series!.first));

  DailyAbidingSeries? get _holySpirit =>
      _series?.firstWhere((s) => s.isScriptureGuided, orElse: () => _series!.first);

  List<DailyAbidingSeries> get _bibleProject =>
      _series?.where((s) => s.isBibleProject).toList() ?? [];

  List<DailyAbidingSeries> get _otherVideo => _series
          ?.where((s) => s.isVideoDaily && !s.isBibleProject && !s.featured)
          .toList() ??
      [];

  void _openVideoSeries(DailyAbidingSeries s) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, _a, _b) => s.isScriptureGuided
            ? ScriptureGuidedScreen(series: s)
            : DailySeriesDetailScreen(series: s),
        transitionsBuilder: (_, anim, _b, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  void _openBibleProject(DailyAbidingSeries s) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, _a, _b) => DailySeriesDetailScreen(series: s),
        transitionsBuilder: (_, anim, _b, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  Future<void> _openReadingPlan(DevotionalSeries plan) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, _a, _b) => DevotionalSeriesScreen(series: plan),
        transitionsBuilder: (_, anim, _b, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    final completionLists = await Future.wait(
      _readingPlans!.map((p) => DevotionalsService.instance.getCompleted(p.id)),
    );
    if (!mounted) return;
    setState(() {
      _planCompletions = {
        for (var i = 0; i < _readingPlans!.length; i++)
          _readingPlans![i].id: completionLists[i],
      };
    });
  }

  int _completedCountForSeries(String prefix) =>
      _completed.where((id) => id.startsWith(prefix)).length;

  String _planStateLabel(String id, int totalDays) {
    final completed = _planCompletions[id] ?? [];
    if (completed.isEmpty) return 'Begin';
    final set = completed.toSet();
    for (int d = 1; d <= totalDays; d++) {
      if (!set.contains(d)) return 'Day $d';
    }
    return 'Complete ✓';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.bgApp,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 28, color: theme.textAccent.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Could not load content',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary.withValues(alpha: 0.7))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() => _error = null);
                  _load();
                },
                child: Text('Try again',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.textAccent,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: AtmosphericBackground(
        baseColor: theme.bgApp,
        accentColor: theme.textAccent,
        child: FadeTransition(
          opacity: _series == null ? const AlwaysStoppedAnimation(1.0) : _fade,
          child: Column(
            children: [
              // ── Header + Tab bar ────────────────────────────────────────────
              _buildHeader(theme, top),
              // ── Tab content ─────────────────────────────────────────────────
              Expanded(
                child: _series == null
                    ? _buildLoading(theme)
                    : TabBarView(
                        controller: _tabCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _VideoTab(
                            theme: theme,
                            featured: _featured,
                            holySpirit: _holySpirit,
                            otherVideo: _otherVideo,
                            completed: _completed,
                            completedCountForSeries: _completedCountForSeries,
                            onOpen: _openVideoSeries,
                          ),
                          _ReadingTab(
                            theme: theme,
                            plans: _readingPlans ?? [],
                            planCompletions: _planCompletions,
                            planStateLabel: _planStateLabel,
                            onOpen: _openReadingPlan,
                          ),
                          _BibleProjectTab(
                            theme: theme,
                            series: _bibleProject,
                            onOpen: _openBibleProject,
                          ),
                        ],
                      ),
              ),
              SizedBox(height: bottom == 0 ? 0 : 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AbideThemeData theme, double top) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: theme.textAccent.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'DAILY PRACTICE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.8,
                  color: theme.textAccent.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTabBar(theme),
        ],
      ),
    );
  }

  Widget _buildTabBar(AbideThemeData theme) {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (_, __) {
        final idx = _tabCtrl.index;
        return Row(
          children: [
            _TabItem(label: 'Video', active: idx == 0,
                theme: theme, onTap: () => _tabCtrl.animateTo(0)),
            const SizedBox(width: 28),
            _TabItem(label: 'Reading', active: idx == 1,
                theme: theme, onTap: () => _tabCtrl.animateTo(1)),
            const SizedBox(width: 28),
            _TabItem(label: 'Bible Project', active: idx == 2,
                theme: theme, onTap: () => _tabCtrl.animateTo(2)),
          ],
        );
      },
    );
  }

  Widget _buildLoading(AbideThemeData theme) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: theme.textAccent.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ── Tab label ─────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  const _TabItem({
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Crimson Pro',
                fontSize: active ? 18 : 17,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? theme.textPrimary
                    : theme.textPrimary.withValues(alpha: 0.35),
                height: 1.0,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 1.5,
              width: active ? label.length * 7.5 : 0,
              decoration: BoxDecoration(
                color: theme.textAccent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video Tab ─────────────────────────────────────────────────────────────────

class _VideoTab extends StatelessWidget {
  const _VideoTab({
    required this.theme,
    required this.featured,
    required this.holySpirit,
    required this.otherVideo,
    required this.completed,
    required this.completedCountForSeries,
    required this.onOpen,
  });

  final AbideThemeData theme;
  final DailyAbidingSeries? featured;
  final DailyAbidingSeries? holySpirit;
  final List<DailyAbidingSeries> otherVideo;
  final Set<String> completed;
  final int Function(String prefix) completedCountForSeries;
  final void Function(DailyAbidingSeries) onOpen;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (featured != null)
          SliverToBoxAdapter(child: _buildHero(context, size, featured!)),
        if (holySpirit != null)
          SliverToBoxAdapter(
              child: _buildScriptureCard(context, holySpirit!)),
        for (final s in otherVideo)
          SliverToBoxAdapter(child: _buildVideoCard(context, s)),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildHero(BuildContext context, Size size, DailyAbidingSeries s) {
    final heroH = size.height * 0.42;
    final completedCount = completedCountForSeries(s.id.split('-').first);
    final hasProgress = completedCount > 0;
    final isComplete = completedCount >= s.days;

    return SizedBox(
      height: heroH,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            s.coverImage != null
                ? 'assets/images/${s.coverImage}'
                : 'assets/images/the_blood_of_christ.png',
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _a, _b) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.2,
                  colors: [
                    theme.textAccent.withValues(alpha: 0.22),
                    theme.bgApp,
                  ],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.88),
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0, height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [theme.bgApp, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24, right: 24, bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22), width: 1),
                  ),
                  child: Text(
                    '${s.days}-DAY VIDEO SERIES  •  FEATURED',
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.title,
                  style: const TextStyle(
                    fontFamily: 'Crimson Pro',
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.58),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                if (hasProgress && !isComplete) ...[
                  _HeroProgress(completed: completedCount, total: s.days),
                  const SizedBox(height: 14),
                ],
                GestureDetector(
                  onTap: () => onOpen(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    child: Text(
                      isComplete
                          ? 'Watch Again'
                          : hasProgress
                              ? 'Continue — Day ${completedCount + 1}'
                              : 'Begin the Journey',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptureCard(BuildContext context, DailyAbidingSeries s) {
    final thumbUrl = s.coverVideoId != null
        ? 'https://img.youtube.com/vi/${s.coverVideoId}/hqdefault.jpg'
        : null;
    final isDone = completed.contains('scripture-guided-${s.id}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => onOpen(s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 148,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (thumbUrl != null)
                  Image.network(thumbUrl,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.1),
                      errorBuilder: (_, _a, _b) => _fallbackBg())
                else
                  _fallbackBg(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        theme.bgApp.withValues(alpha: 0.97),
                        theme.bgApp.withValues(alpha: 0.78),
                        theme.bgApp.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.38, 0.65, 1.0],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: theme.textAccent.withValues(alpha: 0.12)),
                  ),
                ),
                Positioned(
                  left: 20, top: 0, bottom: 0, right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'SCRIPTURE + WORSHIP',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: theme.textPrimary.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.title,
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.textPrimary.withValues(alpha: 0.42),
                          height: 1.35,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isDone ? 'Completed  ✓' : 'Enter Experience →',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, DailyAbidingSeries s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () => onOpen(s),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.textAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: theme.textAccent.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: TextStyle(
                          fontFamily: 'Crimson Pro',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        )),
                    const SizedBox(height: 3),
                    Text(s.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textPrimary.withValues(alpha: 0.42),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: theme.textPrimary.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackBg() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.centerRight,
            radius: 1.0,
            colors: [
              theme.textAccent.withValues(alpha: 0.18),
              theme.bgApp,
            ],
          ),
        ),
      );
}

// ── Reading Tab ───────────────────────────────────────────────────────────────

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({
    required this.theme,
    required this.plans,
    required this.planCompletions,
    required this.planStateLabel,
    required this.onOpen,
  });

  final AbideThemeData theme;
  final List<DevotionalSeries> plans;
  final Map<String, List<int>> planCompletions;
  final String Function(String id, int totalDays) planStateLabel;
  final Future<void> Function(DevotionalSeries) onOpen;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Center(
        child: Text('No reading plans yet.',
            style: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.4),
                fontSize: 14)),
      );
    }
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(
                  plan: plans[i],
                  theme: theme,
                  stateLabel:
                      planStateLabel(plans[i].id, plans[i].days),
                  completed: (planCompletions[plans[i].id] ?? []).length,
                  onTap: () => onOpen(plans[i]),
                ),
              ),
              childCount: plans.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.theme,
    required this.stateLabel,
    required this.completed,
    required this.onTap,
  });

  final DevotionalSeries plan;
  final AbideThemeData theme;
  final String stateLabel;
  final int completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _planColors[plan.id] ?? theme.textAccent;
    final isDone = stateLabel == 'Complete ✓';
    final hasProgress = completed > 0 && !isDone;
    final progress = plan.days > 0 ? completed / plan.days : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.28),
                accent.withValues(alpha: 0.08),
                theme.bgApp.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.20),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              // Content
              Positioned(
                left: 20, top: 20, right: 20, bottom: hasProgress ? 36 : 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${plan.days} DAYS',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: accent,
                            ),
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Complete ✓',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: theme.textPrimary.withValues(alpha: 0.25)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontFamily: 'Crimson Pro',
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plan.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        plan.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textPrimary.withValues(alpha: 0.42),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    if (!hasProgress && !isDone)
                      Text(
                        'Begin →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    if (hasProgress)
                      Text(
                        'Continue — $stateLabel →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                  ],
                ),
              ),
              // Progress bar at bottom
              if (hasProgress)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bible Project Tab ─────────────────────────────────────────────────────────

class _BibleProjectTab extends StatelessWidget {
  const _BibleProjectTab({
    required this.theme,
    required this.series,
    required this.onOpen,
  });

  final AbideThemeData theme;
  final List<DailyAbidingSeries> series;
  final void Function(DailyAbidingSeries) onOpen;

  Future<void> _openWebsite() async {
    const url = 'https://bibleproject.com';
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Attribution header ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/the_bible_project.png',
                  height: 22,
                  errorBuilder: (_, _a, _b) => Text(
                    'THE BIBLE PROJECT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: theme.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Animated overviews of Scripture that explore the Bible as a unified story leading to Jesus.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textPrimary.withValues(alpha: 0.5),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _openWebsite,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Content provided by The Bible Project',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.textAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded,
                          size: 12, color: theme.textAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Used under Creative Commons Attribution-NonCommercial-ShareAlike 4.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textPrimary.withValues(alpha: 0.3),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: theme.textAccent.withValues(alpha: 0.10)),
              ],
            ),
          ),
        ),

        // ── Series list ────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BibleProjectCard(
                  s: series[i],
                  theme: theme,
                  onTap: () => onOpen(series[i]),
                ),
              ),
              childCount: series.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _BibleProjectCard extends StatelessWidget {
  const _BibleProjectCard(
      {required this.s, required this.theme, required this.onTap});
  final DailyAbidingSeries s;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbUrl = s.coverVideoId != null
        ? 'https://img.youtube.com/vi/${s.coverVideoId}/hqdefault.jpg'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 88,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbUrl != null)
                Image.network(thumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _a, _b) => Container(
                        color: theme.textAccent.withValues(alpha: 0.08)))
              else
                Container(color: theme.textAccent.withValues(alpha: 0.08)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      theme.bgApp.withValues(alpha: 0.97),
                      theme.bgApp.withValues(alpha: 0.82),
                      theme.bgApp.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.42, 0.65, 1.0],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.textAccent.withValues(alpha: 0.10)),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Positioned(
                left: 16, top: 0, bottom: 0, right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(
                        fontFamily: 'Crimson Pro',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.textPrimary.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16, top: 0, bottom: 0,
                child: Icon(Icons.play_circle_outline_rounded,
                    size: 22,
                    color: theme.textPrimary.withValues(alpha: 0.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Progress Bar ─────────────────────────────────────────────────────────

class _HeroProgress extends StatelessWidget {
  const _HeroProgress({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 2.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$completed of $total days',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
