import 'package:flutter/material.dart';
import '../data/daily_abiding_models.dart';
import '../services/daily_abiding_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'day_experience_screen.dart';

class DailySeriesDetailScreen extends StatefulWidget {
  const DailySeriesDetailScreen({super.key, required this.series});
  final DailyAbidingSeries series;

  @override
  State<DailySeriesDetailScreen> createState() =>
      _DailySeriesDetailScreenState();
}

class _DailySeriesDetailScreenState extends State<DailySeriesDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  DailyAbidingSeriesDetail? _detail;
  Set<String> _completed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _load();
  }

  Future<void> _load() async {
    final svc = DailyAbidingService.instance;
    final results = await Future.wait([
      svc.loadSeriesDetail(widget.series.id),
      svc.getCompletedDays(),
    ]);
    if (!mounted) return;
    setState(() {
      _detail = results[0] as DailyAbidingSeriesDetail;
      _completed = results[1] as Set<String>;
      _loading = false;
    });
    _ctrl.forward();
  }

  Future<void> _refreshCompleted() async {
    final completed = await DailyAbidingService.instance.getCompletedDays();
    if (mounted) setState(() => _completed = completed);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  DayStatus _status(DailyAbidingDay day, int index) {
    if (_completed.contains(day.id)) return DayStatus.complete;
    if (day.unlockAfter != null && !_completed.contains(day.unlockAfter)) {
      return DayStatus.locked;
    }
    // first day always available; subsequent available if prev complete
    if (index == 0) return DayStatus.available;
    return DayStatus.available;
  }

  void _openDay(DailyAbidingDay day) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => DayExperienceScreen(
          series: widget.series,
          detail: _detail!,
          day: day,
          completed: _completed,
          onComplete: (dayId) async {
            await DailyAbidingService.instance.markComplete(dayId);
            await _refreshCompleted();
          },
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
    await _refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final s = widget.series;

    final thumbUrl = s.coverVideoId != null
        ? 'https://img.youtube.com/vi/${s.coverVideoId}/hqdefault.jpg'
        : null;

    return AtmosphericBackground(
      baseColor: theme.bgApp,
      accentColor: theme.textAccent,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Cover hero ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Cover image
                SizedBox(
                  height: top + 240,
                  width: double.infinity,
                  child: s.coverImage != null
                      ? Image.asset(
                          'assets/images/${s.coverImage}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientCover(theme),
                        )
                      : thumbUrl != null
                          ? Image.network(
                              thumbUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _gradientCover(theme),
                            )
                          : _gradientCover(theme),
                ),
                // Gradient overlay bottom
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  height: top + 240,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.0),
                          theme.bgApp.withValues(alpha: 0.85),
                          theme.bgApp,
                        ],
                        stops: const [0.0, 0.15, 0.55, 0.82, 1.0],
                      ),
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: top + 16,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                ),
                // Author source badge
                if (s.isBibleProject)
                  Positioned(
                    top: top + 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Text(
                        'BibleProject',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                // Title content at bottom of cover
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: theme.textPrimary,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Description + Progress ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textPrimary.withValues(alpha: 0.6),
                      height: 1.6,
                    ),
                  ),
                  if (_detail != null) ...[
                    const SizedBox(height: 20),
                    _buildProgressBar(theme),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Loading ──
          if (_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.textAccent.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            )
          else ...[
            // ── Section label ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'SESSIONS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: theme.textAccent.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),

            // ── Day list ──
            SliverFadeTransition(
              opacity: _fade,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final day = _detail!.days[i];
                    final status = _status(day, i);
                    return _DayRow(
                      day: day,
                      index: i,
                      status: status,
                      theme: theme,
                      onTap: status != DayStatus.locked
                          ? () => _openDay(day)
                          : null,
                      seriesVideoId: _detail!.seriesVideoId,
                    );
                  },
                  childCount: _detail!.days.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AbideThemeData theme) {
    final total = _detail!.days.length;
    final done = _detail!.days.where((d) => _completed.contains(d.id)).length;
    final pct = total > 0 ? done / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              done == 0
                  ? 'Not started'
                  : done == total
                      ? 'Complete!'
                      : '$done of $total sessions complete',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            if (done > 0)
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textAccent.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 2.5,
            backgroundColor: theme.textAccent.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
                theme.textAccent.withValues(alpha: 0.75)),
          ),
        ),
      ],
    );
  }

  Widget _gradientCover(AbideThemeData theme) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.textAccent.withValues(alpha: 0.15),
              theme.textAccent.withValues(alpha: 0.04),
            ],
          ),
        ),
      );
}

enum DayStatus { locked, available, complete }

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.index,
    required this.status,
    required this.theme,
    required this.onTap,
    this.seriesVideoId,
  });

  final DailyAbidingDay day;
  final int index;
  final DayStatus status;
  final AbideThemeData theme;
  final VoidCallback? onTap;
  final String? seriesVideoId;

  @override
  Widget build(BuildContext context) {
    final isLocked = status == DayStatus.locked;
    final isComplete = status == DayStatus.complete;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.38 : 1.0,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: isComplete
                ? theme.textAccent.withValues(alpha: 0.05)
                : theme.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isComplete
                  ? theme.textAccent.withValues(alpha: 0.28)
                  : theme.textAccent.withValues(alpha: 0.09),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Numbered circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete
                      ? theme.textAccent.withValues(alpha: 0.15)
                      : theme.textAccent.withValues(alpha: 0.06),
                  border: Border.all(
                    color: isComplete
                        ? theme.textAccent.withValues(alpha: 0.55)
                        : theme.textAccent.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isComplete
                      ? Icon(Icons.check_rounded,
                          size: 14, color: theme.textAccent)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isLocked
                                ? theme.textPrimary.withValues(alpha: 0.25)
                                : theme.textAccent.withValues(alpha: 0.7),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (day.subtitle.isNotEmpty)
                      Text(
                        day.subtitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isComplete
                              ? theme.textAccent.withValues(alpha: 0.65)
                              : theme.textAccent.withValues(alpha: 0.4),
                        ),
                      ),
                    if (day.subtitle.isNotEmpty) const SizedBox(height: 3),
                    Text(
                      day.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary
                            .withValues(alpha: isLocked ? 0.4 : 0.88),
                        letterSpacing: -0.15,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (day.theme != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        day.theme!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: theme.textPrimary.withValues(alpha: 0.32),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing icon
              const SizedBox(width: 10),
              isLocked
                  ? Icon(Icons.lock_outline_rounded,
                      size: 14,
                      color: theme.textPrimary.withValues(alpha: 0.2))
                  : isComplete
                      ? const SizedBox.shrink()
                      : Icon(Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: theme.textAccent.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
