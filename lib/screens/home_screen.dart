import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/daily_verses.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import 'biblical_dictionary_screen.dart';
import 'daily_abiding_screen.dart';
import 'christ_revealed_hub_screen.dart';
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

  String _name = '';
  Future<String>? _verseFuture;

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
    _loadName();
    _verseFuture = _loadDailyVerse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _name = prefs.getString('abide_name') ?? '');
  }

  Future<String> _loadDailyVerse() async {
    final v = todaysVerse();
    try {
      final raw = await rootBundle
          .loadString('assets/asr/${v.book}/${v.chapter}.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final verses = json['verses'];
      if (verses is Map) {
        final verse = verses['${v.verse}'];
        if (verse is String) return verse;
        if (verse is Map) {
          if (verse.containsKey('segments')) {
            final segs = verse['segments'] as List? ?? [];
            return segs.map((s) => (s is Map ? s['text'] : s) ?? '').join(' ');
          }
          return (verse['text'] as String?) ?? '';
        }
      }
    } catch (_) {}
    return '';
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
                SliverToBoxAdapter(child: _buildPractice(theme)),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────────────

  Widget _buildGreeting(AbideThemeData theme) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = _fmtDate(now).toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
              color: theme.textPrimary.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 10),
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
          Text(
            _name.isNotEmpty ? _name.toUpperCase() : 'ABIDE',
            style: theme.bodyFont(_name.isNotEmpty ? 36 : 48).copyWith(
              letterSpacing: _name.isNotEmpty ? 6 : 10,
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

  // ── Verse of the Day ────────────────────────────────────────────────────────

  Widget _buildVerseHero(AbideThemeData theme) {
    final v = todaysVerse();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => ScriptureScreen(
            initialBook: v.book,
            initialChapter: v.chapter,
            initialTranslation: 'asr',
            showNav: true,
            skipSavedPosition: true,
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          ),
        ),
      ),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
                FutureBuilder<String>(
                  future: _verseFuture,
                  builder: (ctx, snap) {
                    final v = todaysVerse();
                    final text = snap.data ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        text.isEmpty
                            ? SizedBox(
                                height: 20,
                                child: LinearProgressIndicator(
                                  backgroundColor:
                                      theme.textAccent.withValues(alpha: 0.1),
                                  color: theme.textAccent.withValues(alpha: 0.3),
                                ),
                              )
                            : Text(
                                '"$text"',
                                style: theme.christStyle(
                                    fontSize: theme.verseFontSize + 2),
                              ),
                        const SizedBox(height: 20),
                        Text(
                          '${v.ref}  ·  ASR',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: theme.textAccent.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  // ── Your Practice ───────────────────────────────────────────────────────────



  Widget _buildPractice(AbideThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'YOUR PRACTICE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: theme.textAccent.withValues(alpha: 0.45),
              ),
            ),
          ),
          // Christ Revealed — featured, full-width hero card
          _PracticeCard(
            theme: theme,
            label: 'Christ Revealed',
            title: 'Jesus from Genesis to Revelation',
            subtitle: 'See Christ woven through all of Scripture',
            image: 'assets/images/practice-christ-revealed.png',
            featured: true,
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 600),
                pageBuilder: (_, __, ___) => const ChristRevealedHubScreen(),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                  child: child,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PracticeCard(
            theme: theme,
            label: 'Daily Practice',
            title: 'Reading Plans & Video Series',
            subtitle: 'Devotionals, video experiences, and guided plans',
            image: 'assets/images/practice-daily-abiding.png',
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 320),
                pageBuilder: (_, __, ___) => const DailyAbidingScreen(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PracticeCard(
            theme: theme,
            label: 'Abide Dictionary',
            title: 'Biblical reference library',
            subtitle: 'People, places, doctrines, and terms',
            image: 'assets/images/practice-dictionary.png',
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 320),
                pageBuilder: (_, __, ___) =>
                    const BiblicalDictionaryScreen(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}

// ── Practice Card ─────────────────────────────────────────────────────────────

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.theme,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
    this.featured = false,
  });

  final AbideThemeData theme;
  final String label;
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final accent = theme.textAccent;
    final cardHeight = featured ? 110.0 : 94.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: featured
              ? accent.withValues(alpha: 0.06)
              : theme.surface.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: featured
                ? accent.withValues(alpha: 0.22)
                : accent.withValues(alpha: 0.09),
            width: featured ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: featured ? 0.22 : 0.14),
              blurRadius: featured ? 18 : 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: accent.withValues(alpha: featured ? 0.85 : 0.5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: featured ? 15 : 14,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: theme.textPrimary.withValues(alpha: 0.35),
                        height: 1.35,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Right: image
            SizedBox(
              width: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      color: accent.withValues(alpha: 0.08),
                    ),
                  ),
                  // Left-edge gradient to blend into card background
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          (featured ? accent.withValues(alpha: 0.06) : theme.surface.withValues(alpha: 0.60)),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
