import 'package:flutter/material.dart';
import '../data/daily_abiding_models.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'daily_series_detail_screen.dart';

class BibleProjectHubScreen extends StatelessWidget {
  const BibleProjectHubScreen({super.key, required this.series});
  final List<DailyAbidingSeries> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: AtmosphericBackground(
        baseColor: theme.bgApp,
        accentColor: theme.textAccent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Cover hero ──
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: top + 220,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/bible_project_old_testament.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.textAccent.withValues(alpha: 0.12),
                              theme.bgApp,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient to app bg
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.0),
                            theme.bgApp.withValues(alpha: 0.7),
                            theme.bgApp,
                          ],
                          stops: const [0.0, 0.35, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: top + 14,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                  // Title content
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/the_bible_project.png',
                          height: 24,
                          errorBuilder: (_, __, ___) => Text(
                            'THE BIBLE PROJECT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: theme.textPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Old Testament',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Animated overviews of the Hebrew Scriptures',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textPrimary.withValues(alpha: 0.48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Description ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Text(
                  'The Bible Project creates free animated videos that explore the Bible as a unified story leading to Jesus. Watch, reflect, and pray through each book.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textPrimary.withValues(alpha: 0.5),
                    height: 1.65,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

            // ── Book list ──
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _BookCard(
                  series: series[i],
                  theme: theme,
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 340),
                      pageBuilder: (_, __, ___) =>
                          DailySeriesDetailScreen(series: series[i]),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(
                        opacity: CurvedAnimation(
                            parent: anim, curve: Curves.easeOut),
                        child: child,
                      ),
                    ),
                  ),
                ),
                childCount: series.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard(
      {required this.series, required this.theme, required this.onTap});
  final DailyAbidingSeries series;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbUrl = series.coverVideoId != null
        ? 'https://img.youtube.com/vi/${series.coverVideoId}/hqdefault.jpg'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.surface.withValues(alpha: 0.4),
          border: Border.all(color: theme.textAccent.withValues(alpha: 0.09)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: 72,
                child: thumbUrl != null
                    ? Image.network(
                        thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary.withValues(alpha: 0.9),
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      series.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.textPrimary.withValues(alpha: 0.38),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: theme.textPrimary.withValues(alpha: 0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: Center(
          child: Icon(Icons.play_circle_outline_rounded,
              color: Colors.white.withValues(alpha: 0.2), size: 24),
        ),
      );
}
