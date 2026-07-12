import 'package:flutter/material.dart';
import '../data/devotional_models.dart';
import '../services/devotionals_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'devotional_author_screen.dart';
import 'devotional_series_screen.dart';

// ── Accent color map for each series ─────────────────────────────────────────
const _seriesColors = {
  'beauty-of-holiness': Color(0xFFCBB27C),
  'beauty-of-holiness-kids': Color(0xFF8A9E5C),
  'from-the-inside-out': Color(0xFF8A9E5C),
  'discipleship-guide': Color(0xFF7EB5D0),
  'living-close-to-jesus': Color(0xFFCBB27C),
  'validated-by-god': Color(0xFFB8906A),
  'lucifer-light-and-fall': Color(0xFFB83232),
  'seven-spirits-of-god': Color(0xFF7ED0D8),
  'fear-of-god': Color(0xFFF97316),
  'slow-to-anger': Color(0xFF8A9E5C),
};

class DevotionalsScreen extends StatefulWidget {
  const DevotionalsScreen({super.key});

  @override
  State<DevotionalsScreen> createState() => _DevotionalsScreenState();
}

class _DevotionalsScreenState extends State<DevotionalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  List<AuthorGroup> _groups = [];
  Map<String, List<int>> _completions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final svc = DevotionalsService.instance;
    final groups = await svc.groupedByAuthor();

    // Flatten all series to load completions in parallel
    final allSeries = groups.expand((g) => g.series).toList();
    final completionLists = await Future.wait(
      allSeries.map((s) => svc.getCompleted(s.id)),
    );

    if (!mounted) return;
    setState(() {
      _groups = groups;
      _completions = {
        for (var i = 0; i < allSeries.length; i++)
          allSeries[i].id: completionLists[i],
      };
      _loading = false;
    });
    _ctrl.forward();
  }

  Future<void> _refreshCompletions() async {
    final svc = DevotionalsService.instance;
    final allSeries = _groups.expand((g) => g.series).toList();
    final completionLists = await Future.wait(
      allSeries.map((s) => svc.getCompleted(s.id)),
    );
    if (!mounted) return;
    setState(() {
      _completions = {
        for (var i = 0; i < allSeries.length; i++)
          allSeries[i].id: completionLists[i],
      };
    });
  }

  List<DevotionalSeries> get _inProgress => _groups
      .expand((g) => g.series)
      .where((s) {
        final c = _completions[s.id] ?? [];
        return c.isNotEmpty && c.length < s.days;
      })
      .toList();

  Color _accentFor(String seriesId, AbideThemeData theme) =>
      _seriesColors[seriesId] ?? theme.textAccent;

  String _stateLabel(String seriesId, int totalDays) {
    final completed = _completions[seriesId] ?? [];
    if (completed.isEmpty) return 'Begin';
    final set = completed.toSet();
    for (int d = 1; d <= totalDays; d++) {
      if (!set.contains(d)) return 'Continue — Day $d';
    }
    return 'Complete ✓';
  }

  double _progress(String seriesId, int totalDays) {
    final c = _completions[seriesId] ?? [];
    return totalDays > 0 ? (c.length / totalDays).clamp(0.0, 1.0) : 0.0;
  }

  void _openSeries(DevotionalSeries series) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, __, ___) => DevotionalSeriesScreen(series: series),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    await _refreshCompletions();
  }

  void _openAuthor(AuthorGroup group) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => DevotionalAuthorScreen(
          group: group,
          completions: _completions,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
    await _refreshCompletions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: AtmosphericBackground(
        baseColor: theme.bgApp,
        accentColor: theme.textAccent,
        child: FadeTransition(
          opacity: _loading ? const AlwaysStoppedAnimation(1.0) : _fade,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(theme)),

              // ── In Progress ──────────────────────────────────────────────────
              if (!_loading && _inProgress.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: _buildSectionLabel('IN PROGRESS', theme)),
                SliverToBoxAdapter(child: _buildInProgressRow(theme)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // ── Loading spinner ───────────────────────────────────────────────
              if (_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: theme.textAccent.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Author cards ──────────────────────────────────────────────────
              if (!_loading) ...[
                SliverToBoxAdapter(
                    child: _buildSectionLabel('AUTHORS', theme)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final group = _groups[i];
                      final imagePath = DevotionalsService.instance
                          .getAuthorImageAsset(group.author.image);
                      return _AuthorCard(
                        group: group,
                        completions: _completions,
                        theme: theme,
                        imagePath: imagePath,
                        onTap: () => _openAuthor(group),
                      );
                    },
                    childCount: _groups.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AbideThemeData theme) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(28, top + 24, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + eyebrow row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.textAccent.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.textAccent.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 13,
                      color: theme.textPrimary.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'DEVOTIONALS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: theme.textAccent.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Abide Deeply',
            style: theme.bodyFont(40).copyWith(
              color: theme.textPrimary,
              height: 1.1,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 1.5,
            color: theme.textAccent.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Classic writings and original series for your walk with God.',
            style: TextStyle(
              fontSize: 13,
              color: theme.textPrimary.withValues(alpha: 0.42),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, AbideThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: theme.textAccent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: theme.textAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressRow(AbideThemeData theme) {
    return SizedBox(
      height: 176,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        itemCount: _inProgress.length,
        itemBuilder: (ctx, i) {
          final s = _inProgress[i];
          final accent = _accentFor(s.id, theme);
          final completed = _completions[s.id] ?? [];
          final pct = s.days > 0 ? completed.length / s.days : 0.0;
          return _InProgressCard(
            series: s,
            accentColor: accent,
            progress: pct,
            completedCount: completed.length,
            theme: theme,
            onTap: () => _openSeries(s),
          );
        },
      ),
    );
  }
}

// ── Author Card (cinematic, full-width) ───────────────────────────────────────

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({
    required this.group,
    required this.completions,
    required this.theme,
    required this.imagePath,
    required this.onTap,
  });

  final AuthorGroup group;
  final Map<String, List<int>> completions;
  final AbideThemeData theme;
  final String? imagePath;
  final VoidCallback onTap;

  double get _overallProgress {
    final total = group.totalDays;
    if (total == 0) return 0.0;
    final done = group.series.fold<int>(
      0,
      (sum, s) => sum + (completions[s.id]?.length ?? 0),
    );
    return (done / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final seriesCount = group.series.length;
    final totalDays = group.totalDays;
    final progress = _overallProgress;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.surface,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: image or gradient fallback ───────────────────────
            _buildBackground(),

            // ── Dark gradient overlay ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // ── Top-right badge ───────────────────────────────────────────────
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  '$seriesCount series · $totalDays days',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // ── Bottom-left: author name + subtitle ───────────────────────────
            Positioned(
              left: 18,
              right: 80,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.author.name,
                    style: theme.bodyFont(28).copyWith(
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    group.author.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: theme.textAccent,
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom progress bar (shown only when progress > 0) ────────────
            if (progress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 2,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(color: theme.textAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }
    // Gradient fallback when no image is available
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.textAccent.withValues(alpha: 0.25),
            theme.bgApp,
          ],
        ),
      ),
    );
  }
}

// ── In-Progress Card (horizontal scroll) ─────────────────────────────────────

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({
    required this.series,
    required this.accentColor,
    required this.progress,
    required this.completedCount,
    required this.theme,
    required this.onTap,
  });

  final DevotionalSeries series;
  final Color accentColor;
  final double progress;
  final int completedCount;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: accent band with initial
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom:
                      BorderSide(color: accentColor.withValues(alpha: 0.18)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    series.title.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: accentColor.withValues(alpha: 0.7),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary.withValues(alpha: 0.88),
                        letterSpacing: -0.1,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.5,
                        backgroundColor: accentColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor.withValues(alpha: 0.75)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$completedCount / ${series.days} days',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: accentColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-Width Series Card ────────────────────────────────────────────────────
// Kept for completeness; series cards in the library now appear inside the
// author screen (see _AuthorSeriesCard in devotional_author_screen.dart).

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.series,
    required this.accentColor,
    required this.stateLabel,
    required this.progress,
    required this.completedCount,
    required this.theme,
    required this.onTap,
  });

  final DevotionalSeries series;
  final Color accentColor;
  final String stateLabel;
  final double progress;
  final int completedCount;
  final AbideThemeData theme;
  final VoidCallback onTap;

  bool get _isComplete => completedCount >= series.days && series.days > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: _isComplete
              ? accentColor.withValues(alpha: 0.05)
              : theme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isComplete
                ? accentColor.withValues(alpha: 0.25)
                : accentColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent column ──────────────────────────────────────────
              Container(
                width: 64,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  border: Border(
                    right: BorderSide(
                        color: accentColor.withValues(alpha: 0.15)),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3.5,
                        color: accentColor.withValues(alpha: 0.75),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: _isComplete
                            ? Icon(Icons.check_rounded,
                                size: 16, color: accentColor)
                            : Text(
                                series.title.characters.first.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                  height: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right content ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            series.author.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: accentColor.withValues(alpha: 0.65),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${series.days} DAYS',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color:
                                  theme.textPrimary.withValues(alpha: 0.28),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        series.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        series.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textPrimary.withValues(alpha: 0.38),
                          height: 1.35,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (series.authorNote != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          series.authorNote!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: theme.textPrimary.withValues(alpha: 0.3),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 2,
                          backgroundColor: accentColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor.withValues(alpha: 0.65)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            stateLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _isComplete
                                  ? accentColor.withValues(alpha: 0.6)
                                  : accentColor,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (!_isComplete) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 9,
                                color: accentColor.withValues(alpha: 0.6)),
                          ],
                          const Spacer(),
                          if (completedCount > 0 && !_isComplete)
                            Text(
                              '$completedCount of ${series.days}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.textPrimary
                                    .withValues(alpha: 0.28),
                              ),
                            ),
                        ],
                      ),
                    ],
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
