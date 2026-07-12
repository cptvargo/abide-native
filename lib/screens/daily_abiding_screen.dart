import 'dart:io';
import 'dart:math' show max;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/daily_abiding_models.dart';
import '../services/daily_abiding_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'bible_project_hub_screen.dart';
import 'daily_series_detail_screen.dart';
import 'scripture_guided_screen.dart';

class DailyAbidingScreen extends StatefulWidget {
  const DailyAbidingScreen({super.key});

  @override
  State<DailyAbidingScreen> createState() => _DailyAbidingScreenState();
}

class _DailyAbidingScreenState extends State<DailyAbidingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  List<DailyAbidingSeries>? _series;
  Set<String> _completed = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _load();
  }

  Future<void> _load() async {
    try {
      final svc = DailyAbidingService.instance;
      final series = await svc.loadIndex();
      final completed = await svc.getCompletedDays();
      if (!mounted) return;
      setState(() {
        _series = series;
        _completed = completed;
        _error = null;
      });
      _ctrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  DailyAbidingSeries? get _featured =>
      _series?.firstWhere((s) => s.id == 'blood-of-christ',
          orElse: () => _series!.first);

  DailyAbidingSeries? get _holySpirit =>
      _series?.firstWhere((s) => s.id == 'holy-spirit',
          orElse: () => _series!.first);

  List<DailyAbidingSeries> get _bibleProject =>
      _series?.where((s) => s.isBibleProject).toList() ?? [];

  void _openSeries(DailyAbidingSeries s) {
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => s.isScriptureGuided
          ? ScriptureGuidedScreen(series: s)
          : DailySeriesDetailScreen(series: s),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    Navigator.push(context, route);
  }

  int _completedCountForSeries(String prefix) =>
      _completed.where((id) => id.startsWith(prefix)).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: AtmosphericBackground(
        baseColor: theme.bgApp,
        accentColor: theme.textAccent,
        child: FadeTransition(
          opacity: _fade,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (_error != null) ...[
                SliverToBoxAdapter(child: _buildFloatingNav(theme)),
                SliverToBoxAdapter(child: _buildError(theme, _error!)),
              ] else if (_series == null) ...[
                SliverToBoxAdapter(child: _buildFloatingNav(theme)),
                SliverToBoxAdapter(child: _buildLoading(theme)),
              ] else ...[
                if (_featured != null)
                  SliverToBoxAdapter(
                      child: _buildCinematicHero(theme, _featured!)),
                if (_holySpirit != null)
                  SliverToBoxAdapter(
                      child: _buildScriptureGuidedCard(theme, _holySpirit!)),
                if (_bibleProject.isNotEmpty)
                  SliverToBoxAdapter(
                      child: _buildBibleProjectCard(theme)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Floating nav (used only while loading / error) ────────────────────────

  Widget _buildFloatingNav(AbideThemeData theme) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios_new_rounded,
                size: 13, color: theme.textAccent.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text('HOME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: theme.textAccent.withValues(alpha: 0.6),
                )),
          ],
        ),
      ),
    );
  }

  // ── Cinematic Hero ────────────────────────────────────────────────────────

  Widget _buildCinematicHero(AbideThemeData theme, DailyAbidingSeries s) {
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final heroH = max(360.0, size.height * 0.58);
    final completedCount = _completedCountForSeries('blood-day');
    final hasProgress = completedCount > 0;
    final isComplete = completedCount >= s.days;

    return SizedBox(
      height: heroH,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image — edge to edge
          Image.asset(
            'assets/images/the_blood_of_christ.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.0, -0.2),
            errorBuilder: (_, __, ___) => Container(
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

          // Cinematic vignette gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.62),
                  Colors.black.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.18, 0.42, 0.68, 1.0],
              ),
            ),
          ),

          // Fade into app bg at bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: 80,
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

          // Nav bar floating over image
          Positioned(
            top: top + 14,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
                const Spacer(),
                Text(
                  'DAILY ABIDING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.8,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
          ),

          // Content — bottom anchored
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1),
                  ),
                  child: Text(
                    '${s.days}-DAY VIDEO SERIES',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Large title
                Text(
                  s.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  s.subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.62),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Progress bar (only if started)
                if (hasProgress && !isComplete) ...[
                  _HeroProgress(
                      completed: completedCount,
                      total: s.days),
                  const SizedBox(height: 16),
                ],

                // CTA
                GestureDetector(
                  onTap: () => _openSeries(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.5),
                    ),
                    child: Text(
                      isComplete
                          ? 'Watch Again'
                          : hasProgress
                              ? 'Continue — Day ${completedCount + 1}'
                              : 'Begin the Journey',
                      style: const TextStyle(
                        fontSize: 13.5,
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

  // ── Scripture Guided (Holy Spirit) ────────────────────────────────────────

  Widget _buildScriptureGuidedCard(AbideThemeData theme, DailyAbidingSeries s) {
    final thumbUrl = s.coverVideoId != null
        ? 'https://img.youtube.com/vi/${s.coverVideoId}/hqdefault.jpg'
        : null;
    final isComplete = _completed.contains('scripture-guided-${s.id}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openSeries(s),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail — shown clearly, not blurred
                    if (thumbUrl != null)
                      Image.network(
                        thumbUrl,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.1),
                        errorBuilder: (_, __, ___) =>
                            _sgFallbackBg(theme),
                      )
                    else
                      _sgFallbackBg(theme),

                    // Cinematic overlay — left tinted panel
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            theme.bgApp.withValues(alpha: 0.97),
                            theme.bgApp.withValues(alpha: 0.82),
                            theme.bgApp.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.38, 0.65, 1.0],
                        ),
                      ),
                    ),

                    // Bottom gradient
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      height: 70,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              theme.bgApp.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Border
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.textAccent.withValues(alpha: 0.14),
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      left: 22,
                      top: 0,
                      bottom: 0,
                      right: 80,
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
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: theme.textPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            s.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: theme.textPrimary,
                              letterSpacing: -0.4,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            s.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textPrimary.withValues(alpha: 0.48),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                isComplete
                                    ? 'Completed  ✓'
                                    : 'Enter Experience →',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textAccent,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bible Project entry card ──────────────────────────────────────────────

  Widget _buildBibleProjectCard(AbideThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 340),
            pageBuilder: (_, __, ___) =>
                BibleProjectHubScreen(series: _bibleProject),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover image
                Image.asset(
                  'assets/images/bible_project_old_testament.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.centerRight,
                        radius: 1.2,
                        colors: [
                          theme.textAccent.withValues(alpha: 0.15),
                          theme.bgApp,
                        ],
                      ),
                    ),
                  ),
                ),
                // Left-to-right gradient
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        theme.bgApp.withValues(alpha: 0.97),
                        theme.bgApp.withValues(alpha: 0.8),
                        theme.bgApp.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.38, 0.65, 1.0],
                    ),
                  ),
                ),
                // Bottom gradient
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  height: 70,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          theme.bgApp.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Border
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.textAccent.withValues(alpha: 0.12)),
                  ),
                ),
                // Content
                Positioned(
                  left: 22, top: 0, bottom: 0, right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/the_bible_project.png',
                        height: 22,
                        errorBuilder: (_, __, ___) => Text(
                          'THE BIBLE PROJECT',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: theme.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Old Testament',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: theme.textPrimary,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_bibleProject.length} animated overviews',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textPrimary.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Explore →',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary.withValues(alpha: 0.55),
                          letterSpacing: 0.2,
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

  Widget _sgFallbackBg(AbideThemeData theme) => DecoratedBox(
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

  // ── Error / Loading ───────────────────────────────────────────────────────

  Widget _buildError(AbideThemeData theme, String error) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
              const SizedBox(height: 8),
              Text(error,
                  style: TextStyle(
                      fontSize: 10,
                      color: theme.textPrimary.withValues(alpha: 0.35)),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis),
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
      ),
    );
  }

  Widget _buildLoading(AbideThemeData theme) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.textAccent.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PREPARING YOUR PRACTICE',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                color: theme.textAccent.withValues(alpha: 0.35),
              ),
            ),
          ],
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
          width: 120,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$completed of $total days',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}


Future<void> openYouTube(String videoId) async {
  final url = 'https://www.youtube.com/watch?v=$videoId';
  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', url]);
  }
}
