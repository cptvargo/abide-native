import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/abide_theme.dart';
import '../data/seek_entry.dart';

class SeekAnswerScreen extends StatelessWidget {
  const SeekAnswerScreen({
    super.key,
    required this.entry,
    required this.all,
  });

  final SeekEntry entry;
  final List<SeekEntry> all;

  static void open(
    BuildContext context,
    SeekEntry entry,
    List<SeekEntry> all,
  ) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            SeekAnswerScreen(entry: entry, all: all),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 340),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final relatedEntries = entry.related
        .map((id) => SeekIndexService.instance.byId(id, all))
        .whereType<SeekEntry>()
        .toList();

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          Container(
            color: theme.bgMenu,
            padding: EdgeInsets.only(top: topPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: theme.textPrimary),
                  ),
                ),
                Expanded(
                  child: Text(
                    'SEEK',
                    style: theme.bodyFont(14).copyWith(
                          color: theme.textAccent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Wrap(
                    spacing: 6,
                    children: entry.topics.map((t) => _TopicBadge(
                      label: t, theme: theme,
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 28, 20, bottomPad + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    entry.question,
                    style: theme.bodyFont(24).copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Short Answer
                  _SectionLabel(label: 'SHORT ANSWER', theme: theme),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.textAccent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.textAccent.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      entry.shortAnswer,
                      style: theme.bodyFont(16).copyWith(
                            color: theme.textPrimary,
                            height: 1.6,
                          ),
                    ),
                  ),

                  // Expanded
                  if (entry.expanded != null && entry.expanded!.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionLabel(label: 'EXPLANATION', theme: theme),
                    const SizedBox(height: 10),
                    ..._buildExpandedParagraphs(entry.expanded!, theme),
                  ],

                  // Scripture References
                  if (entry.refs.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionLabel(label: 'SCRIPTURE REFERENCES', theme: theme),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.refs
                          .map((r) => _RefChip(ref: r, theme: theme))
                          .toList(),
                    ),
                  ],

                  // Historical Voices
                  if (entry.sources.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionLabel(label: 'HISTORICAL VOICES', theme: theme),
                    const SizedBox(height: 10),
                    ...entry.sources.map(
                      (s) => _SourceCard(source: s, theme: theme),
                    ),
                  ],

                  // Related Questions
                  if (relatedEntries.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionLabel(label: 'RELATED QUESTIONS', theme: theme),
                    const SizedBox(height: 10),
                    ...relatedEntries.map(
                      (e) => _RelatedCard(
                        entry: e,
                        all: all,
                        theme: theme,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandedParagraphs(String text, AbideThemeData theme) {
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty);
    return paragraphs.map((p) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        p.trim(),
        style: theme.bodyFont(15).copyWith(
              color: theme.textPrimary.withValues(alpha: 0.88),
              height: 1.65,
            ),
      ),
    )).toList();
  }
}

// ── Author color map ──────────────────────────────────────────────────────────

Color _authorColor(String author) {
  switch (author.toLowerCase()) {
    case 'barnes':   return const Color(0xFF5B8DD9);
    case 'gill':     return const Color(0xFF6BAA82);
    case 'jfb':      return const Color(0xFFB8863A);
    case 'spurgeon': return const Color(0xFFD97B8B);
    default:         return const Color(0xFF9B7BD9);
  }
}

String _authorFull(String author) {
  switch (author.toLowerCase()) {
    case 'barnes':   return 'Albert Barnes';
    case 'gill':     return 'John Gill';
    case 'jfb':      return 'Jamieson, Fausset & Brown';
    case 'spurgeon': return 'C.H. Spurgeon';
    default:         return author;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.theme});
  final String label;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.bodyFont(10).copyWith(
            color: theme.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
    );
  }
}

class _TopicBadge extends StatelessWidget {
  const _TopicBadge({required this.label, required this.theme});
  final String label;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.textAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.bodyFont(9).copyWith(
              color: theme.textAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _RefChip extends StatelessWidget {
  const _RefChip({required this.ref, required this.theme});
  final String ref;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.subtleOutline, width: 0.5),
      ),
      child: Text(
        ref,
        style: theme.bodyFont(13).copyWith(
              color: theme.textAccent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.theme});
  final SeekSource source;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = _authorColor(source.author);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.subtleOutline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  source.author.toUpperCase(),
                  style: theme.bodyFont(9).copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _authorFull(source.author),
                style: theme.bodyFont(11).copyWith(color: theme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                height: 14,
                margin: const EdgeInsets.only(top: 3, right: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Expanded(
                child: Text(
                  source.quote,
                  style: theme.bodyFont(14).copyWith(
                        color: theme.textPrimary.withValues(alpha: 0.85),
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({
    required this.entry,
    required this.all,
    required this.theme,
  });
  final SeekEntry entry;
  final List<SeekEntry> all;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SeekAnswerScreen.open(context, entry, all),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.subtleOutline, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.question,
                style: theme.bodyFont(14).copyWith(
                      color: theme.textPrimary,
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: theme.textMuted),
          ],
        ),
      ),
    );
  }
}
