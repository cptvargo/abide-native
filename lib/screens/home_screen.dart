import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'scripture_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _fadeIn = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut));
    _slideUp = Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    return AtmosphericBackground(
      baseColor: theme.bgApp,
      accentColor: theme.textAccent,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildGreeting(theme)),
                SliverToBoxAdapter(child: _buildVerseHero(theme)),
                SliverToBoxAdapter(child: _buildDevotionalSection(theme)),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(AbideThemeData theme) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          // ABIDE wordmark uses the theme's body font — each theme's personality
          // shows immediately in the app title
          Text(
            'ABIDE',
            style: theme.bodyFont(48).copyWith(
              letterSpacing: 10,
              color: theme.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 1.5,
            color: theme.textAccent.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseHero(AbideThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (ctx, anim, _) => const ScriptureScreen(),
            transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
              opacity: CurvedAnimation(
                  parent: anim, curve: Curves.easeInOutCubic),
              child: child,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.textAccent.withValues(alpha: 0.10),
                    theme.textAccent.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.textAccent.withValues(alpha: 0.14),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.textAccent.withValues(alpha: 0.07),
                    blurRadius: 48,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'VERSE OF THE DAY',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: theme.textAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_outward_rounded,
                          size: 14,
                          color: theme.textAccent.withValues(alpha: 0.35)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 24,
                    height: 1.5,
                    color: theme.textAccent.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 20),
                  // Verse text uses the theme's body font, size, and rhythm
                  Text(
                    '"For God so loved the world that He gave His one and only Son, '
                    'that everyone who believes in Him shall not perish but have eternal life."',
                    style: theme.christStyle(fontSize: theme.verseFontSize + 2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'John 3:16  ·  ASR',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: theme.textAccent.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevotionalSection(AbideThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 16),
          child: Row(
            children: [
              Text(
                'DEVOTIONALS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: theme.textAccent.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textAccent.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 216,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _devotionals.length,
            itemBuilder: (ctx, i) =>
                _DevotionalCard(data: _devotionals[i], theme: theme),
          ),
        ),
      ],
    );
  }
}

// ── Devotional cards ──────────────────────────────────────────────────────────

class _DevotionalData {
  const _DevotionalData({
    required this.title,
    required this.days,
    required this.tag,
  });
  final String title;
  final int days;
  final String tag;
}

final _devotionals = const [
  _DevotionalData(
    title: 'Lucifer — Light, Law, and the Fall',
    days: 5,
    tag: 'Origins',
  ),
  _DevotionalData(
    title: 'School of the Seven Spirits of God',
    days: 10,
    tag: 'The Spirit',
  ),
  _DevotionalData(
    title: 'Waiting on the Lord',
    days: 7,
    tag: 'Devotion',
  ),
  _DevotionalData(
    title: 'The Sermon on the Mount',
    days: 8,
    tag: 'Teaching',
  ),
];

class _DevotionalCard extends StatelessWidget {
  const _DevotionalCard({required this.data, required this.theme});
  final _DevotionalData data;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    final accent = theme.textAccent;
    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            theme.surface.withValues(alpha: 0.80),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              data.tag.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: accent,
              ),
            ),
          ),
          const Spacer(),
          // Devotional title uses the theme's body font
          Text(
            data.title,
            style: theme.bodyFont(16).copyWith(
              color: theme.textPrimary,
              height: 1.35,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 16,
                height: 1,
                color: accent.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Text(
                '${data.days}-Day',
                style: TextStyle(
                  fontSize: 10,
                  color: accent.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
