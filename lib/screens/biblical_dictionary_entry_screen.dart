import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/bible_dictionary_service.dart';
import '../theme/abide_theme.dart';
import 'scripture_screen.dart';

class BiblicalDictionaryEntryScreen extends StatelessWidget {
  const BiblicalDictionaryEntryScreen({
    super.key,
    required this.entry,
    required this.allEntries,
  });

  final BibDictEntry entry;
  final List<BibDictEntry> allEntries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: top + 4)),

          // Back
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                ),
              ),
            ),
          ),

          // Hero
          SliverToBoxAdapter(
            child: _buildHero(theme),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Container(
                  height: 0.5,
                  color: theme.textAccent.withValues(alpha: 0.14)),
            ),
          ),

          // Definition
          if (entry.definition.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'DEFINITION',
                theme: theme,
                child: Text(
                  entry.definition,
                  style: theme
                      .bodyFont(16)
                      .copyWith(
                        color: theme.textPrimary.withValues(alpha: 0.88),
                        height: 1.85,
                        letterSpacing: 0.1,
                      ),
                ),
              ),
            ),

          // Historical Background
          if ((entry.historicalBackground ?? '').isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'HISTORICAL BACKGROUND',
                theme: theme,
                child: Text(
                  entry.historicalBackground!,
                  style: theme
                      .bodyFont(16)
                      .copyWith(
                        color: theme.textPrimary.withValues(alpha: 0.88),
                        height: 1.85,
                        letterSpacing: 0.1,
                      ),
                ),
              ),
            ),

          // Biblical Significance
          if ((entry.biblicalSignificance ?? '').isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'BIBLICAL SIGNIFICANCE',
                theme: theme,
                child: Text(
                  entry.biblicalSignificance!,
                  style: theme
                      .bodyFont(16)
                      .copyWith(
                        color: theme.textPrimary.withValues(alpha: 0.88),
                        height: 1.85,
                        letterSpacing: 0.1,
                      ),
                ),
              ),
            ),

          // Scripture References
          if (entry.refs.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'SCRIPTURE REFERENCES',
                theme: theme,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.refs
                      .map((ref) => _RefChip(
                            ref: ref,
                            theme: theme,
                            onTap: () => _openRef(context, ref),
                          ))
                      .toList(),
                ),
              ),
            ),

          // Related Entries
          if (entry.related.isNotEmpty)
            SliverToBoxAdapter(
              child: _Section(
                label: 'RELATED ENTRIES',
                theme: theme,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.related
                      .map((id) {
                        final related = BibDictService.instance
                            .byId(id, allEntries);
                        if (related == null) return const SizedBox.shrink();
                        return _RelatedChip(
                          entry: related,
                          theme: theme,
                          onTap: () => _openRelated(context, related),
                        );
                      })
                      .toList(),
                ),
              ),
            ),

          // Source attribution
          SliverToBoxAdapter(child: _buildSource(theme)),

          SliverToBoxAdapter(child: SizedBox(height: bottom + 100)),
        ],
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────────

  Widget _buildHero(AbideThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.textAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: theme.textAccent.withValues(alpha: 0.18),
                  width: 0.5),
            ),
            child: Text(
              entry.category.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.textAccent.withValues(alpha: 0.80),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Term
          Text(
            entry.term,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.textAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.textAccent.withValues(alpha: 0.10),
                width: 0.5,
              ),
            ),
            child: Text(
              entry.summary,
              style: theme.bodyFont(16.5).copyWith(
                    color: theme.textPrimary.withValues(alpha: 0.80),
                    height: 1.65,
                    letterSpacing: 0.1,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Source ────────────────────────────────────────────────────────────────────

  Widget _buildSource(AbideThemeData theme) {
    if (entry.sources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Text(
        entry.sources.join(' · '),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          color: theme.textMuted.withValues(alpha: 0.35),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  void _openRef(BuildContext context, String ref) {
    final parsed = _parseRef(ref);
    if (parsed == null) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => ScriptureScreen(
          initialBook: parsed.$1,
          initialChapter: parsed.$2,
          initialTranslation: 'asr',
          showNav: true,
          skipSavedPosition: true,
        ),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity:
              CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  void _openRelated(BuildContext context, BibDictEntry related) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => BiblicalDictionaryEntryScreen(
            entry: related, allEntries: allEntries),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }
}

// ── Ref parser ────────────────────────────────────────────────────────────────

// Returns (bookKey, chapter) e.g. ("ephesians", 2) from "Ephesians 2:8-9"
(String, int)? _parseRef(String ref) {
  final m =
      RegExp(r'^(.*)\s+(\d+)[:\s]').firstMatch(ref.trim()) ??
      RegExp(r'^(.*)\s+(\d+)$').firstMatch(ref.trim());
  if (m == null) return null;

  final rawBook = m.group(1)!.trim().toLowerCase();
  final chapter = int.tryParse(m.group(2)!) ?? 1;

  final book = rawBook
      .replaceAllMapped(
          RegExp(r'\s+of\s+'), (_) => ' ')
      .replaceAll(RegExp(r'\s+'), '');

  return (book, chapter);
}

// ── Section ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section(
      {required this.label, required this.theme, required this.child});

  final String label;
  final AbideThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: theme.textAccent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Ref Chip ──────────────────────────────────────────────────────────────────

class _RefChip extends StatefulWidget {
  const _RefChip(
      {required this.ref, required this.theme, required this.onTap});

  final String ref;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  State<_RefChip> createState() => _RefChipState();
}

class _RefChipState extends State<_RefChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: t.textAccent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: t.textAccent.withValues(alpha: 0.18), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 12,
                color: t.textAccent.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 5),
              Text(
                widget.ref,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.textAccent.withValues(alpha: 0.80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Related Chip ──────────────────────────────────────────────────────────────

class _RelatedChip extends StatefulWidget {
  const _RelatedChip(
      {required this.entry, required this.theme, required this.onTap});

  final BibDictEntry entry;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  State<_RelatedChip> createState() => _RelatedChipState();
}

class _RelatedChipState extends State<_RelatedChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.subtleOutline, width: 0.5),
          ),
          child: Text(
            widget.entry.term,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: t.textPrimary.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}
