import 'package:flutter/material.dart';
import '../data/devotional_models.dart';
import '../services/devotionals_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'devotional_reader_screen.dart';

// Same color map as devotionals_screen — keep in sync.
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

class DevotionalSeriesScreen extends StatefulWidget {
  const DevotionalSeriesScreen({super.key, required this.series});
  final DevotionalSeries series;

  @override
  State<DevotionalSeriesScreen> createState() => _DevotionalSeriesScreenState();
}

class _DevotionalSeriesScreenState extends State<DevotionalSeriesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  List<DevotionalDay?> _days = [];
  List<int> _completed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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
    final s = widget.series;

    // Load completions and all days in parallel
    final results = await Future.wait<dynamic>([
      svc.getCompleted(s.id),
      Future.wait(
        List.generate(s.days, (i) => _loadDaySafe(svc, s.id, i + 1)),
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _completed = results[0] as List<int>;
      _days = results[1] as List<DevotionalDay?>;
      _loading = false;
    });
    _ctrl.forward();
  }

  Future<DevotionalDay?> _loadDaySafe(
      DevotionalsService svc, String seriesId, int dayNum) async {
    try {
      return await svc.loadDay(seriesId, dayNum);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshCompleted() async {
    final completed =
        await DevotionalsService.instance.getCompleted(widget.series.id);
    if (mounted) setState(() => _completed = completed);
  }

  Color get _accent =>
      _seriesColors[widget.series.id] ??
      Theme.of(context).extension<AbideThemeData>()!.textAccent;

  _DayStatus _status(int dayNum) {
    final svc = DevotionalsService.instance;
    if (_completed.contains(dayNum)) return _DayStatus.complete;
    if (svc.isDayLocked(dayNum, _completed)) return _DayStatus.locked;
    return _DayStatus.available;
  }

  void _openDay(int index) async {
    final day = _days[index];
    if (day == null) return;
    final dayNum = index + 1;
    final status = _status(dayNum);
    if (status == _DayStatus.locked) return;

    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => DevotionalReaderScreen(
          seriesId: widget.series.id,
          day: day,
          initiallyComplete: status == _DayStatus.complete,
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
    final accent = _seriesColors[s.id] ?? theme.textAccent;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: AtmosphericBackground(
        baseColor: theme.bgApp,
        accentColor: accent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Atmospheric gradient header bg
                  Container(
                    height: top + 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.12),
                          accent.withValues(alpha: 0.03),
                          theme.bgApp,
                        ],
                        stops: const [0.0, 0.5, 1.0],
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
                          color: accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: accent.withValues(alpha: 0.25)),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: theme.textPrimary.withValues(alpha: 0.7),
                            size: 14),
                      ),
                    ),
                  ),
                  // Title block
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Accent bar
                        Container(
                          width: 28,
                          height: 2.5,
                          color: accent.withValues(alpha: 0.65),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.author.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: accent.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          s.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textPrimary.withValues(alpha: 0.45),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Description + progress summary ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: theme.textPrimary.withValues(alpha: 0.55),
                        height: 1.65,
                      ),
                    ),
                    if (!_loading) ...[
                      const SizedBox(height: 20),
                      _buildProgressSummary(theme, accent),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Loading ───────────────────────────────────────────────────────
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
                        color: accent.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Day list label ────────────────────────────────────────────────
            if (!_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                  child: Text(
                    'DAYS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: accent.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),

            // ── Day rows ──────────────────────────────────────────────────────
            if (!_loading)
              SliverFadeTransition(
                opacity: _fade,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final dayNum = i + 1;
                      final day = i < _days.length ? _days[i] : null;
                      final status = _status(dayNum);
                      return _DayRow(
                        dayNum: dayNum,
                        title: day?.title,
                        status: status,
                        theme: theme,
                        accentColor: accent,
                        onTap: status != _DayStatus.locked
                            ? () => _openDay(i)
                            : null,
                      );
                    },
                    childCount: s.days,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(AbideThemeData theme, Color accent) {
    final total = widget.series.days;
    final done = _completed.length;
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
                      ? 'All days complete!'
                      : '$done of $total days complete',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary.withValues(alpha: 0.45),
              ),
            ),
            const Spacer(),
            if (done > 0)
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent.withValues(alpha: 0.65),
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
            backgroundColor: accent.withValues(alpha: 0.12),
            valueColor:
                AlwaysStoppedAnimation<Color>(accent.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

// ── Day Status ────────────────────────────────────────────────────────────────

enum _DayStatus { locked, available, complete }

// ── Day Row ───────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.dayNum,
    required this.title,
    required this.status,
    required this.theme,
    required this.accentColor,
    required this.onTap,
  });

  final int dayNum;
  final String? title;
  final _DayStatus status;
  final AbideThemeData theme;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = status == _DayStatus.locked;
    final isComplete = status == _DayStatus.complete;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.35 : 1.0,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: isComplete
                ? accentColor.withValues(alpha: 0.06)
                : theme.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isComplete
                  ? accentColor.withValues(alpha: 0.25)
                  : accentColor.withValues(alpha: 0.08),
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
                      ? accentColor.withValues(alpha: 0.14)
                      : accentColor.withValues(alpha: 0.06),
                  border: Border.all(
                    color: isComplete
                        ? accentColor.withValues(alpha: 0.5)
                        : accentColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isComplete
                      ? Icon(Icons.check_rounded,
                          size: 14, color: accentColor)
                      : Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isLocked
                                ? theme.textPrimary.withValues(alpha: 0.25)
                                : accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? 'Day $dayNum',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary
                            .withValues(alpha: isLocked ? 0.35 : 0.88),
                        letterSpacing: -0.1,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isComplete || isLocked) ...[
                      const SizedBox(height: 2),
                      Text(
                        isComplete ? 'Complete' : 'Locked',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isComplete
                              ? accentColor.withValues(alpha: 0.55)
                              : theme.textPrimary.withValues(alpha: 0.25),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing
              const SizedBox(width: 10),
              if (isLocked)
                Icon(Icons.lock_outline_rounded,
                    size: 13,
                    color: theme.textPrimary.withValues(alpha: 0.2))
              else if (!isComplete)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: accentColor.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
