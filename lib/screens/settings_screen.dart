import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/backup_service.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';

// ── Metadata ──────────────────────────────────────────────────────────────────

class _ThemeMeta {
  const _ThemeMeta(this.key, this.name, this.description, this.swatch);
  final String key;
  final String name;
  final String description;
  final Color swatch;
}

const _kThemes = [
  _ThemeMeta('classic',         'Classic',           'Traditional Scripture',   Color(0xFFCBB27C)),
  _ThemeMeta('still-waters',    'Still Waters',      'Calm & Reflective',       Color(0xFF4A9B8E)),
  _ThemeMeta('stone-fire',      'Stone & Fire',      'Bold & Prophetic',        Color(0xFFF97316)),
  _ThemeMeta('olive-parchment', 'Olive & Parchment', 'Ancient Manuscript',      Color(0xFF8A9E5C)),
  _ThemeMeta('parchment',       'Parchment',         'Classic Book Style',       Color(0xFF9B6B3C)),
];

class _TransMeta {
  const _TransMeta(this.key, this.label, this.tagline, this.desc, this.badge, this.source);
  final String key;
  final String label;
  final String tagline;
  final String desc;
  final String badge;
  final String source;
}

const _kTranslations = [
  _TransMeta('KJV', 'King James Version', 'The historic 1769 English translation',
    'The most widely read English Bible in history. Majestic, poetic language that has shaped the Church for centuries. Ideal for devotional reading, memorization, and those who grew up with its beloved cadence.',
    'Classic', 'Authorized Version (1769)'),
  _TransMeta('ASR', 'ABIDE Source Reading', 'A study-oriented rendering close to the source',
    'Based on the Berean Standard Bible, the ASR is designed for readers who want to stay close to the original language structure — ideal for word studies, cross-referencing, and deeper theological reading. As a derived translation, minor edits may be present for study clarity and consistency.',
    'For Study', 'Derived from the Berean Standard Bible (BSB)'),
  _TransMeta('WAE', 'Webster ABIDE Edition', "Noah Webster's classic revision, refined for ABIDE",
    "Webster's 1833 revision of the King James Bible — updated spelling, clarified archaic language, and refined for modern devotional use. Reverent in tone, accessible in language. Ideal for those who love the cadence of the KJV but want clearer expression.",
    'Revised Classic', "Derived from Noah Webster's Bible, 1833"),
];

// ── Root ──────────────────────────────────────────────────────────────────────

enum _View { main, appearance, textSize, translation, contact }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.resetKey,
    required this.themeKey,
    required this.onThemeChanged,
    required this.textScale,
    required this.onTextScaleChanged,
    required this.chapterlessMode,
    required this.onChapterlessModeChanged,
  });

  final int resetKey;
  final String themeKey;
  final ValueChanged<String> onThemeChanged;
  final double textScale;
  final ValueChanged<double> onTextScaleChanged;
  final bool chapterlessMode;
  final ValueChanged<bool> onChapterlessModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _View _view = _View.main;
  bool _deeper = true;

  @override
  void didUpdateWidget(SettingsScreen old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey && _view != _View.main) {
      setState(() { _deeper = false; _view = _View.main; });
    }
  }

  void _push(_View v) => setState(() { _deeper = true; _view = v; });
  void _back() => setState(() { _deeper = false; _view = _View.main; });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final bot = MediaQuery.paddingOf(context).bottom;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(_deeper ? 0.04 : -0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: switch (_view) {
        _View.main => _MainView(
            key: const ValueKey(_View.main),
            t: t, top: top, bot: bot,
            themeKey: widget.themeKey,
            textScale: widget.textScale,
            chapterlessMode: widget.chapterlessMode,
            onChapterlessModeChanged: widget.onChapterlessModeChanged,
            onPush: _push,
          ),
        _View.appearance => _AppearanceView(
            key: const ValueKey(_View.appearance),
            t: t, top: top, bot: bot,
            themeKey: widget.themeKey,
            onThemeChanged: widget.onThemeChanged,
            onBack: _back,
          ),
        _View.textSize => _TextSizeView(
            key: const ValueKey(_View.textSize),
            t: t, top: top, bot: bot,
            textScale: widget.textScale,
            onChanged: widget.onTextScaleChanged,
            onBack: _back,
          ),
        _View.translation => _TranslationView(
            key: const ValueKey(_View.translation),
            t: t, top: top, bot: bot,
            onBack: _back,
          ),
        _View.contact => _ContactView(
            key: const ValueKey(_View.contact),
            t: t, top: top, bot: bot,
            onBack: _back,
          ),
      },
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

extension _ThemeX on AbideThemeData {
  Color get line => isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.07);
  Color get divLine => isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05);
  Color get faint => isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.04);
}

class _Shell extends StatelessWidget {
  const _Shell({required this.t, required this.child});
  final AbideThemeData t;
  final Widget child;

  @override
  Widget build(BuildContext context) => AtmosphericBackground(
    baseColor: t.bgApp,
    accentColor: t.textAccent,
    child: child,
  );
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.t, required this.top, required this.title, required this.onBack});
  final AbideThemeData t;
  final double top;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
    child: Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: t.textAccent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: t.textAccent.withValues(alpha: 0.15), width: 1),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 17, color: t.textAccent),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
            color: t.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.t, required this.label});
  final AbideThemeData t;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9, fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: t.textAccent.withValues(alpha: 0.45),
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.t, required this.children});
  final AbideThemeData t;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      decoration: BoxDecoration(
        color: t.bgMenu,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line, width: 1),
      ),
      child: Column(children: children),
    ),
  );
}

class _CardDivider extends StatelessWidget {
  const _CardDivider({required this.t});
  final AbideThemeData t;

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 18),
    color: t.divLine,
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.t,
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });
  final AbideThemeData t;
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: t.textAccent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: t.textAccent.withValues(alpha: 0.75)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: t.textPrimary, letterSpacing: -0.1,
              ),
            ),
          ),
          if (value != null) ...[
            Text(
              value!,
              style: TextStyle(
                fontSize: 12, color: t.textAccent.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(Icons.chevron_right_rounded, size: 18,
              color: t.isLight ? Colors.black.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.18)),
        ],
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.t, required this.onToggle});
  final bool value;
  final AbideThemeData t;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: 46, height: 27,
      decoration: BoxDecoration(
        color: value ? t.textAccent : t.textAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: value ? null : Border.all(color: t.textAccent.withValues(alpha: 0.2), width: 1),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            left: value ? 21 : 3, top: 3,
            child: Container(
              width: 21, height: 21,
              decoration: BoxDecoration(
                color: value ? t.bgApp : t.textAccent.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Backup helpers ────────────────────────────────────────────────────────────

Future<void> _handleExport(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    await BackupService.instance.export(sharePositionOrigin: origin);
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Export failed: $e')),
    );
  }
}

Future<void> _handleImport(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restore Backup?'),
      content: const Text(
        'This will replace your current highlights, journal entries, '
        'bookmarks, and saved dictionary entries.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Restore'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  try {
    final restored = await BackupService.instance.import();
    if (!context.mounted) return;
    if (restored) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup restored successfully.')),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Import failed. Make sure you selected a valid ABIDE backup file.'),
      ),
    );
  }
}

// ── Main view ─────────────────────────────────────────────────────────────────

class _MainView extends StatelessWidget {
  const _MainView({
    super.key,
    required this.t, required this.top, required this.bot,
    required this.themeKey, required this.textScale,
    required this.chapterlessMode, required this.onChapterlessModeChanged,
    required this.onPush,
  });

  final AbideThemeData t;
  final double top, bot;
  final String themeKey;
  final double textScale;
  final bool chapterlessMode;
  final ValueChanged<bool> onChapterlessModeChanged;
  final ValueChanged<_View> onPush;

  String get _themeName =>
      _kThemes.firstWhere((m) => m.key == themeKey, orElse: () => _kThemes.first).name;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      t: t,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Page header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, top + 18, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIGURE',
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      letterSpacing: 3.5,
                      color: t.textAccent.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Settings',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 46, fontWeight: FontWeight.w300,
                      letterSpacing: -0.5, height: 1,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 40, height: 1.5,
                    color: t.textAccent.withValues(alpha: 0.28),
                  ),
                ],
              ),
            ),
          ),

          // ── Reading ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(t: t, label: 'READING')),
          SliverToBoxAdapter(
            child: _SettingsCard(
              t: t,
              children: [
                _SettingsRow(
                  t: t, icon: Icons.menu_book_outlined,
                  label: 'Translations',
                  onTap: () => onPush(_View.translation),
                ),
                _CardDivider(t: t),
                _SettingsRow(
                  t: t, icon: Icons.palette_outlined,
                  label: 'Appearance',
                  value: _themeName,
                  onTap: () => onPush(_View.appearance),
                ),
                _CardDivider(t: t),
                _SettingsRow(
                  t: t, icon: Icons.text_fields_rounded,
                  label: 'Bible Text Size',
                  value: '${textScale.toStringAsFixed(1)}×',
                  onTap: () => onPush(_View.textSize),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Display ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(t: t, label: 'DISPLAY')),
          SliverToBoxAdapter(
            child: _SettingsCard(
              t: t,
              children: [
                GestureDetector(
                  onTap: () => onChapterlessModeChanged(!chapterlessMode),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: t.textAccent.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.visibility_outlined, size: 16,
                              color: t.textAccent.withValues(alpha: 0.75)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chapterless Mode',
                                style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500,
                                  color: t.textPrimary, letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hides chapter titles and verse numbers',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: t.isLight
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _Toggle(value: chapterlessMode, t: t, onToggle: () => onChapterlessModeChanged(!chapterlessMode)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Data ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(t: t, label: 'DATA')),
          SliverToBoxAdapter(
            child: _SettingsCard(
              t: t,
              children: [
                _SettingsRow(
                  t: t,
                  icon: Icons.upload_rounded,
                  label: 'Export Data',
                  onTap: () => _handleExport(context),
                ),
                _CardDivider(t: t),
                _SettingsRow(
                  t: t,
                  icon: Icons.download_rounded,
                  label: 'Import Data',
                  onTap: () => _handleImport(context),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Support ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(t: t, label: 'SUPPORT')),
          SliverToBoxAdapter(
            child: _SettingsCard(
              t: t,
              children: [
                _SettingsRow(
                  t: t, icon: Icons.mail_outline_rounded,
                  label: 'Contact',
                  onTap: () => onPush(_View.contact),
                ),
              ],
            ),
          ),

          // ── Watermark ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 44, 24, bot + 100),
              child: Text(
                'ABIDE',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: t.textAccent.withValues(alpha: 0.11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appearance view ───────────────────────────────────────────────────────────

class _AppearanceView extends StatelessWidget {
  const _AppearanceView({
    super.key,
    required this.t, required this.top, required this.bot,
    required this.themeKey, required this.onThemeChanged, required this.onBack,
  });

  final AbideThemeData t;
  final double top, bot;
  final String themeKey;
  final ValueChanged<String> onThemeChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      t: t,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _SubHeader(t: t, top: top, title: 'Appearance', onBack: onBack),
          ),
          SliverToBoxAdapter(child: _SectionLabel(t: t, label: 'CHOOSE THEME')),
          SliverToBoxAdapter(
            child: _SettingsCard(
              t: t,
              children: [
                for (int i = 0; i < _kThemes.length; i++) ...[
                  _ThemeRow(
                    meta: _kThemes[i],
                    isActive: _kThemes[i].key == themeKey,
                    t: t,
                    onTap: () => onThemeChanged(_kThemes[i].key),
                  ),
                  if (i < _kThemes.length - 1) _CardDivider(t: t),
                ],
              ],
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: bot + 100)),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.meta, required this.isActive,
    required this.t, required this.onTap,
  });

  final _ThemeMeta meta;
  final bool isActive;
  final AbideThemeData t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isActive ? meta.swatch.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Swatch dot
            Container(
              width: 13, height: 13,
              decoration: BoxDecoration(
                color: meta.swatch,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: meta.swatch.withValues(alpha: 0.45), blurRadius: 6, offset: const Offset(0, 1))]
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? t.textPrimary : t.textPrimary.withValues(alpha: 0.75),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: t.textPrimary.withValues(alpha: isActive ? 0.45 : 0.30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? meta.swatch : Colors.transparent,
                border: Border.all(
                  color: isActive ? meta.swatch : t.textPrimary.withValues(alpha: 0.18),
                  width: isActive ? 0 : 1.5,
                ),
              ),
              child: isActive
                  ? Icon(Icons.check_rounded, size: 13,
                      color: t.isLight ? Colors.white : Colors.black.withValues(alpha: 0.85))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Text size view ────────────────────────────────────────────────────────────

class _TextSizeView extends StatelessWidget {
  const _TextSizeView({
    super.key,
    required this.t, required this.top, required this.bot,
    required this.textScale, required this.onChanged, required this.onBack,
  });

  final AbideThemeData t;
  final double top, bot;
  final double textScale;
  final ValueChanged<double> onChanged;
  final VoidCallback onBack;

  void _step(double delta) {
    final next = double.parse((textScale + delta).toStringAsFixed(1));
    onChanged(next.clamp(0.8, 2.0));
  }

  @override
  Widget build(BuildContext context) {
    final canDec = textScale > 0.8 + 0.001;
    final canInc = textScale < 2.0 - 0.001;

    return _Shell(
      t: t,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _SubHeader(t: t, top: top, title: 'Bible Text Size', onBack: onBack),
          ),

          // ── Stepper ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: t.bgMenu,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.line, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StepBtn(label: '−', enabled: canDec, t: t, onTap: () => _step(-0.1)),
                    Column(
                      children: [
                        Text(
                          textScale.toStringAsFixed(1),
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 56, fontWeight: FontWeight.w300,
                            letterSpacing: -1.5, height: 1,
                            color: t.textAccent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'SCALE',
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: t.textAccent.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                    _StepBtn(label: '+', enabled: canInc, t: t, onTap: () => _step(0.1)),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Live preview ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(t: t, label: 'PREVIEW')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: t.bgMenu,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.line, width: 1),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '¹ ',
                        style: TextStyle(
                          fontSize: textScale * 13,
                          color: t.textAccent.withValues(alpha: 0.6),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      TextSpan(
                        text: 'In the beginning God created the heavens and the earth. ',
                        style: t.verseStyle(fontSize: textScale * 18),
                      ),
                      TextSpan(
                        text: '² ',
                        style: TextStyle(
                          fontSize: textScale * 13,
                          color: t.textAccent.withValues(alpha: 0.6),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      TextSpan(
                        text: 'And the earth was without form and empty, and darkness lay over the face of the deep.',
                        style: t.verseStyle(fontSize: textScale * 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: bot + 100)),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.label, required this.enabled, required this.t, required this.onTap});
  final String label;
  final bool enabled;
  final AbideThemeData t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1.0 : 0.22,
      child: Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: t.textAccent.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.textAccent.withValues(alpha: 0.18), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w300,
              color: t.textAccent, height: 1,
            ),
          ),
        ),
      ),
    ),
  );
}

// ── Translation view ──────────────────────────────────────────────────────────

class _TranslationView extends StatefulWidget {
  const _TranslationView({
    super.key,
    required this.t, required this.top, required this.bot, required this.onBack,
  });

  final AbideThemeData t;
  final double top, bot;
  final VoidCallback onBack;

  @override
  State<_TranslationView> createState() => _TranslationViewState();
}

class _TranslationViewState extends State<_TranslationView> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return _Shell(
      t: t,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _SubHeader(t: t, top: widget.top, title: 'Translations', onBack: widget.onBack),
          ),
          SliverToBoxAdapter(child: _SectionLabel(t: t, label: 'AVAILABLE TRANSLATIONS')),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, widget.bot + 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final meta = _kTranslations[i];
                  return _TransCard(
                    meta: meta, t: t,
                    isExpanded: _expanded == meta.key,
                    onToggle: () => setState(() {
                      _expanded = _expanded == meta.key ? null : meta.key;
                    }),
                  );
                },
                childCount: _kTranslations.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransCard extends StatelessWidget {
  const _TransCard({required this.meta, required this.t, required this.isExpanded, required this.onToggle});
  final _TransMeta meta;
  final AbideThemeData t;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: t.bgMenu,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? t.textAccent.withValues(alpha: 0.28) : t.line,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.textAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.textAccent.withValues(alpha: 0.20), width: 1),
                    ),
                    child: Text(
                      meta.key,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        letterSpacing: 0.5, color: t.textAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.label,
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: t.textPrimary, letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          meta.tagline,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 12, fontStyle: FontStyle.italic,
                            color: t.textPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.textAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      meta.badge,
                      style: TextStyle(
                        fontSize: 8.5, fontWeight: FontWeight.w700,
                        letterSpacing: 0.8, color: t.textAccent.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Expand toggle ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Text(
                    'About this translation',
                    style: TextStyle(
                      fontSize: 10, letterSpacing: 0.4,
                      color: t.textAccent.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 3),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded, size: 14,
                        color: t.textAccent.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),

            // ── Expanded body ────────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 1, color: t.divLine),
                    const SizedBox(height: 14),
                    Text(
                      meta.desc,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14, height: 1.78,
                        color: t.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      meta.source.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8.5, fontWeight: FontWeight.w700,
                        letterSpacing: 1.6, color: t.textAccent.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact view ──────────────────────────────────────────────────────────────

enum _ContactCategory {
  bug, feature, bible, devotional, question, general;

  String get label => switch (this) {
    _ContactCategory.bug        => 'Report a Bug',
    _ContactCategory.feature    => 'Feature Request',
    _ContactCategory.bible      => 'Bible / Translation',
    _ContactCategory.devotional => 'Devotional Feedback',
    _ContactCategory.question   => 'Ask a Question',
    _ContactCategory.general    => 'General Feedback',
  };

  IconData get icon => switch (this) {
    _ContactCategory.bug        => Icons.bug_report_outlined,
    _ContactCategory.feature    => Icons.lightbulb_outline,
    _ContactCategory.bible      => Icons.menu_book_outlined,
    _ContactCategory.devotional => Icons.auto_stories,
    _ContactCategory.question   => Icons.help_outline,
    _ContactCategory.general    => Icons.favorite_border,
  };
}

const _kFaqs = [
  (q: 'How do I highlight a verse?', a: 'Tap the numbered badge or anywhere in the verse text to select it, then choose a color from the panel that appears at the bottom.'),
  (q: 'Can I use ABIDE offline?', a: 'Yes — all Bible translations, devotionals, and Christ Revealed are fully bundled. Only Seek (AI answers) and Daily Abiding require a connection.'),
  (q: 'How do I switch Bible translations?', a: 'Tap the translation abbreviation (ASR, KJV, WAE) in the header bar while reading any chapter.'),
  (q: 'How do I change the theme or text size?', a: 'Open Settings, then tap Appearance to change themes or Text Size to adjust the reading size.'),
  (q: 'Is my data backed up?', a: 'Your data is stored locally on your device. To back it up or transfer it to a new device, go to Settings → Data → Export Data to save a backup file, then use Import Data on your new device to restore everything.'),
];

class _ContactView extends StatefulWidget {
  const _ContactView({
    super.key,
    required this.t, required this.top, required this.bot, required this.onBack,
  });

  final AbideThemeData t;
  final double top, bot;
  final VoidCallback onBack;

  @override
  State<_ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<_ContactView> {
  _ContactCategory? _category;
  bool _faqPassed = false;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  final _messageCtrl = TextEditingController();
  final _titleCtrl   = TextEditingController();
  final _refCtrl     = TextEditingController();
  String _translation = 'ASR';

  // Diagnostics (loaded async)
  String _appVer = '';
  String _buildNum = '';
  String _device = '';
  String _os = '';
  String _locale = '';
  String _themeKey = '';

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _titleCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnostics() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      final di = DeviceInfoPlugin();
      String device = '';
      String os = '';
      if (Platform.isAndroid) {
        final a = await di.androidInfo;
        device = '${a.manufacturer} ${a.model}';
        os = 'Android ${a.version.release}';
      } else if (Platform.isIOS) {
        final i = await di.iosInfo;
        device = i.model;
        os = 'iOS ${i.systemVersion}';
      } else {
        device = Platform.operatingSystem;
        os = Platform.operatingSystemVersion;
      }
      if (!mounted) return;
      setState(() {
        _appVer   = info.version;
        _buildNum = info.buildNumber;
        _device   = device;
        _os       = os;
        _locale   = Platform.localeName;
        _themeKey = prefs.getString('themeKey') ?? 'classic';
      });
    } catch (_) {}
  }

  String _buildPayload() {
    final sb = StringBuffer()
      ..writeln('CATEGORY: ${_category!.label}');
    if (_titleCtrl.text.trim().isNotEmpty) sb.writeln('TITLE: ${_titleCtrl.text.trim()}');
    if (_refCtrl.text.trim().isNotEmpty) sb.writeln('SCRIPTURE: ${_refCtrl.text.trim()}');
    if (_category == _ContactCategory.bible) sb.writeln('TRANSLATION: $_translation');
    sb
      ..writeln()
      ..writeln(_messageCtrl.text.trim())
      ..writeln()
      ..writeln('────────────────────────')
      ..writeln('App: $_appVer+$_buildNum')
      ..writeln('Device: $_device')
      ..writeln('OS: $_os')
      ..writeln('Theme: $_themeKey')
      ..writeln('Locale: $_locale')
      ..writeln('Time: ${DateTime.now().toIso8601String()}');
    return sb.toString();
  }

  Future<void> _send() async {
    if (_messageCtrl.text.trim().isEmpty || _sending) return;

    // Rate limit: one submission per 5 minutes
    final prefs = await SharedPreferences.getInstance();
    final lastSent = prefs.getInt('contact_last_sent') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastSent < 5 * 60 * 1000) {
      setState(() { _error = 'Please wait a few minutes before sending another message.'; });
      return;
    }

    setState(() { _sending = true; _error = null; });
    try {
      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      );
      req.headers.set('Content-Type', 'application/json');
      req.write(jsonEncode({
        'service_id': 'service_z9q4col',
        'template_id': 'template_fyclurw',
        'user_id': 'tTCVbghqW-ocRbMLd',
        'template_params': {'message': _buildPayload()},
      }));
      final resp = await req.close();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await prefs.setInt('contact_last_sent', now);
        if (mounted) setState(() { _sent = true; _sending = false; });
      } else {
        if (mounted) setState(() { _sending = false; _error = 'Could not send. Please try again.'; });
      }
    } catch (_) {
      if (mounted) setState(() { _sending = false; _error = 'No connection. Please check and try again.'; });
    }
  }

  void _handleBack() {
    setState(() {
      _sent = false; _error = null; _category = null; _faqPassed = false;
      _messageCtrl.clear(); _titleCtrl.clear(); _refCtrl.clear();
    });
    widget.onBack();
  }

  void _selectCategory(_ContactCategory cat) => setState(() {
    _category = cat; _faqPassed = false; _error = null;
    _messageCtrl.clear(); _titleCtrl.clear(); _refCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return _Shell(
      t: t,
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _SubHeader(t: t, top: widget.top, title: 'Contact', onBack: _handleBack),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Have feedback, found a bug, or just want to say hello? Every message is read and helps improve ABIDE.',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 15, height: 1.75,
                          color: t.textPrimary.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCategoryGrid(t),
                      if (_category != null) ...[
                        const SizedBox(height: 24),
                        ..._buildForm(t),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: widget.bot + 100)),
            ],
          ),
          if (_sent) _SentState(t: t, onClose: _handleBack),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(AbideThemeData t) {
    final cats = _ContactCategory.values;
    return Column(
      children: [
        for (int i = 0; i < cats.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _CategoryCard(cat: cats[i], selected: _category == cats[i], theme: t, onTap: () => _selectCategory(cats[i]))),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < cats.length
                ? _CategoryCard(cat: cats[i + 1], selected: _category == cats[i + 1], theme: t, onTap: () => _selectCategory(cats[i + 1]))
                : const SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _buildForm(AbideThemeData t) {
    final widgets = <Widget>[];
    final cat = _category!;

    // FAQ gate for questions
    if (cat == _ContactCategory.question && !_faqPassed) {
      for (final faq in _kFaqs) {
        widgets.add(_FaqItem(question: faq.q, answer: faq.a, theme: t));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(GestureDetector(
        onTap: () => setState(() => _faqPassed = true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.line, width: 1),
          ),
          child: Center(child: Text(
            'My question isn\'t answered here',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.textPrimary.withValues(alpha: 0.70)),
          )),
        ),
      ));
      return widgets;
    }

    // Title field for feature requests
    if (cat == _ContactCategory.feature) {
      widgets.add(_ContactFormField(ctrl: _titleCtrl, hint: 'Give your idea a short title…', theme: t, minLines: 1, maxLines: 1));
      widgets.add(const SizedBox(height: 10));
    }

    // Scripture + translation for Bible feedback
    if (cat == _ContactCategory.bible) {
      widgets.add(_ContactFormField(ctrl: _refCtrl, hint: 'Scripture reference — e.g. John 3:16, Romans 8', theme: t, minLines: 1, maxLines: 1));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_TranslationChips(selected: _translation, theme: t, onSelect: (v) => setState(() => _translation = v)));
      widgets.add(const SizedBox(height: 10));
    }

    // Message field
    final hint = switch (cat) {
      _ContactCategory.bug        => 'Describe what happened — steps to reproduce, what you expected…',
      _ContactCategory.feature    => 'Describe the feature and why it would be valuable…',
      _ContactCategory.bible      => 'What did you notice? Translation issue, typo, missing verse…',
      _ContactCategory.devotional => 'Which devotional, and what feedback do you have?',
      _ContactCategory.question   => 'What\'s your question?',
      _ContactCategory.general    => 'Say anything — feedback, appreciation, ideas, prayers…',
    };
    widgets.add(_ContactFormField(ctrl: _messageCtrl, hint: hint, theme: t, minLines: cat == _ContactCategory.general ? 6 : 4, maxLines: 10));

    if (_error != null) {
      widgets.add(const SizedBox(height: 10));
      widgets.add(Text(_error!, style: TextStyle(fontSize: 12, color: Colors.redAccent.withValues(alpha: 0.80))));
    }

    widgets.add(const SizedBox(height: 14));

    // Send button
    widgets.add(ValueListenableBuilder(
      valueListenable: _messageCtrl,
      builder: (_, value, __) {
        final canSend = value.text.trim().isNotEmpty && !_sending;
        return GestureDetector(
          onTap: canSend ? _send : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: canSend ? t.textAccent.withValues(alpha: 0.13) : t.faint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canSend ? t.textAccent.withValues(alpha: 0.38) : t.textAccent.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Center(child: Text(
              _sending ? 'Sending…' : 'Send',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.4,
                color: canSend ? t.textAccent : t.textAccent.withValues(alpha: 0.25),
              ),
            )),
          ),
        );
      },
    ));

    widgets.add(const SizedBox(height: 16));
    widgets.add(Text(
      'ABIDE is independently developed by one person. While I may not be able to respond to every message individually, I genuinely read every submission.',
      style: TextStyle(fontSize: 12, height: 1.6, color: t.textPrimary.withValues(alpha: 0.30)),
    ));

    return widgets;
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.cat, required this.selected, required this.theme, required this.onTap});
  final _ContactCategory cat;
  final bool selected;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? t.textAccent.withValues(alpha: 0.10) : t.surface,
          border: Border.all(
            color: selected ? t.textAccent.withValues(alpha: 0.50) : t.line,
            width: selected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(cat.icon, size: 20, color: selected ? t.textAccent : t.textMuted),
            const SizedBox(height: 8),
            Text(
              cat.label,
              style: TextStyle(
                fontSize: 12, height: 1.3,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? t.textAccent : t.textPrimary.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ item ──────────────────────────────────────────────────────────────────

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer, required this.theme});
  final String question;
  final String answer;
  final AbideThemeData theme;
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: _open ? t.textAccent.withValues(alpha: 0.30) : t.line, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(widget.question, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.textPrimary, height: 1.4))),
              const SizedBox(width: 8),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: t.textMuted),
            ]),
            if (_open) ...[
              const SizedBox(height: 10),
              Text(widget.answer, style: TextStyle(fontSize: 13, height: 1.65, color: t.textPrimary.withValues(alpha: 0.60))),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Form text field ───────────────────────────────────────────────────────────

class _ContactFormField extends StatelessWidget {
  const _ContactFormField({required this.ctrl, required this.hint, required this.theme, this.minLines = 4, this.maxLines = 10});
  final TextEditingController ctrl;
  final String hint;
  final AbideThemeData theme;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      decoration: BoxDecoration(
        color: t.bgMenu,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line, width: 1),
      ),
      child: TextField(
        controller: ctrl,
        minLines: minLines,
        maxLines: maxLines,
        style: TextStyle(fontSize: 15, height: 1.65, color: t.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: t.textPrimary.withValues(alpha: 0.28)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        cursorColor: t.textAccent,
        onChanged: (_) {},
      ),
    );
  }
}

// ── Translation chips ─────────────────────────────────────────────────────────

class _TranslationChips extends StatelessWidget {
  const _TranslationChips({required this.selected, required this.theme, required this.onSelect});
  final String selected;
  final AbideThemeData theme;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      children: ['ASR', 'KJV', 'WAE'].map((tr) {
        final sel = selected == tr;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(tr),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? t.textAccent.withValues(alpha: 0.12) : t.surface,
                border: Border.all(color: sel ? t.textAccent.withValues(alpha: 0.50) : t.line, width: sel ? 1.5 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tr, style: TextStyle(
                fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
                color: sel ? t.textAccent : t.textPrimary.withValues(alpha: 0.60),
              )),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Success overlay ───────────────────────────────────────────────────────────

class _SentState extends StatefulWidget {
  const _SentState({required this.t, required this.onClose});
  final AbideThemeData t;
  final VoidCallback onClose;
  @override
  State<_SentState> createState() => _SentStateState();
}

class _SentStateState extends State<_SentState> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Container(
      color: t.bgApp,
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: t.textAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: t.textAccent.withValues(alpha: 0.30), width: 1.5),
                    ),
                    child: Icon(Icons.check_rounded, size: 32, color: t.textAccent),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Message sent',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: t.textPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Thank you for taking the time. Every submission is read and helps ABIDE grow.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(fontSize: 16, height: 1.7, color: t.textPrimary.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 8),
                Text(
                  'ABIDE is independently developed by one person. While I may not be able to respond to every message individually, I genuinely read every submission.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.6, color: t.textPrimary.withValues(alpha: 0.35)),
                ),
                const SizedBox(height: 36),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Text(
                    'Back to Settings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
