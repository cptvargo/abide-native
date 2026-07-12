import 'package:flutter/material.dart';
import '../data/devotional_models.dart';
import '../services/devotionals_service.dart';
import '../theme/abide_theme.dart';
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

class DevotionalAuthorScreen extends StatefulWidget {
  const DevotionalAuthorScreen({
    super.key,
    required this.group,
    required this.completions,
  });

  final AuthorGroup group;
  final Map<String, List<int>> completions;

  @override
  State<DevotionalAuthorScreen> createState() =>
      _DevotionalAuthorScreenState();
}

class _DevotionalAuthorScreenState extends State<DevotionalAuthorScreen> {
  late Map<String, List<int>> _completions;

  @override
  void initState() {
    super.initState();
    _completions = Map.of(widget.completions);
  }

  Future<void> _refreshCompletions() async {
    final svc = DevotionalsService.instance;
    final completionLists = await Future.wait(
      widget.group.series.map((s) => svc.getCompleted(s.id)),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < widget.group.series.length; i++) {
        _completions[widget.group.series[i].id] = completionLists[i];
      }
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final group = widget.group;
    final imagePath =
        DevotionalsService.instance.getAuthorImageAsset(group.author.image);

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // A. Hero header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHero(context, theme, top, imagePath, group),
          ),

          // B. About text ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildAbout(theme, group),
          ),

          // C. Quote (only if present) ──────────────────────────────────────────
          if (group.author.quote != null)
            SliverToBoxAdapter(
              child: _buildQuote(theme, group),
            ),

          // D. Section label ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSectionLabel('DEVOTIONALS', theme),
          ),

          // E. Series cards ─────────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final s = group.series[i];
                final accent = _seriesColors[s.id] ?? theme.textAccent;
                return _AuthorSeriesCard(
                  series: s,
                  accentColor: accent,
                  stateLabel: _stateLabel(s.id, s.days),
                  progress: _progress(s.id, s.days),
                  completedCount: (_completions[s.id] ?? []).length,
                  theme: theme,
                  onTap: () => _openSeries(s),
                );
              },
              childCount: group.series.length,
            ),
          ),

          // F. Bottom padding ───────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    AbideThemeData theme,
    double top,
    String? imagePath,
    AuthorGroup group,
  ) {
    final heroHeight = top + 320.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or gradient
          _heroBackground(imagePath, theme),

          // Gradient overlay fading into bgApp
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  theme.bgApp,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Floating back button
          Positioned(
            top: top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Bottom: author name + subtitle
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.author.name,
                  style: theme.bodyFont(38).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group.author.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: theme.textAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBackground(String? imagePath, AbideThemeData theme) {
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }
    // Gradient placeholder
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.textAccent.withValues(alpha: 0.35),
            theme.bgApp,
          ],
        ),
      ),
    );
  }

  Widget _buildAbout(AbideThemeData theme, AuthorGroup group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      child: Text(
        group.author.about,
        style: theme.bodyFont(15.5).copyWith(
          fontStyle: FontStyle.italic,
          height: 1.95,
          color: theme.textPrimary.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  Widget _buildQuote(AbideThemeData theme, AuthorGroup group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.textAccent.withValues(alpha: 0.35),
              width: 2.5,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“${group.author.quote!}”',
              style: TextStyle(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: theme.textAccent.withValues(alpha: 0.85),
                height: 1.75,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '— ${group.author.name}',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                color: theme.textAccent.withValues(alpha: 0.42),
              ),
            ),
          ],
        ),
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
}

// ── Author Series Card ────────────────────────────────────────────────────────
// Same left-accent-strip design as _SeriesCard in devotionals_screen; defined
// here to avoid coupling between screen files.

class _AuthorSeriesCard extends StatelessWidget {
  const _AuthorSeriesCard({
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
              // ── Left accent column ────────────────────────────────────────
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

              // ── Right content ─────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day count eyebrow
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            '${series.days} DAYS',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: theme.textPrimary
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Title
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
                      // Subtitle
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
                      // Author note
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
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 2,
                          backgroundColor:
                              accentColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor.withValues(alpha: 0.65)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // State label
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
