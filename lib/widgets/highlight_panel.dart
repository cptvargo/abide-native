import 'package:flutter/material.dart';
import '../data/search_models.dart';
import '../theme/abide_theme.dart';

// ── Global color registry — covers all theme palettes ────────────────────────
const kAllHighlightColors = <String, Color>{
  'gold':      Color(0xFFD4A843),
  'rose':      Color(0xFFD97B8B),
  'teal':      Color(0xFF4FB5BE),
  'aqua':      Color(0xFF4BB8C8),
  'sage':      Color(0xFF6BAA82),
  'amber':     Color(0xFFE67E22),
  'crimson':   Color(0xFFB83232),
  'olive':     Color(0xFF8A9E5C),
  'forest':    Color(0xFF5A8A50),
  'warm-gold': Color(0xFFB8863A),
};

const kHighlightOpacity = 0.38;

Color resolveHighlightBg(String colorId) =>
    (kAllHighlightColors[colorId] ?? kAllHighlightColors['gold']!)
        .withValues(alpha: kHighlightOpacity);

// ── Panel ─────────────────────────────────────────────────────────────────────

class HighlightPanel extends StatelessWidget {
  const HighlightPanel({
    super.key,
    required this.selectedVerses,
    required this.chapterHighlights,
    required this.onColorPick,
    required this.onRemove,
    required this.onDismiss,
    required this.onShare,
    required this.theme,
    required this.book,
    required this.chapter,
  });

  final Set<int> selectedVerses;
  final Map<int, Highlight> chapterHighlights;
  final ValueChanged<String> onColorPick;
  final VoidCallback onRemove;
  final VoidCallback onDismiss;
  final VoidCallback onShare;
  final AbideThemeData theme;
  final String book;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    final verseList = selectedVerses.toList()..sort();
    if (verseList.isEmpty) return const SizedBox.shrink();

    final ref = _buildRef(verseList);
    final hasHighlight = verseList.any((v) => chapterHighlights.containsKey(v));
    final palette = theme.highlightColors;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.bgMenu,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.subtleOutline, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main row: ref / colors / share / divider / close ─────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    ref,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textMuted,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                // 3 theme-specific color dots
                ...palette.map((opt) {
                  final isActive =
                      verseList.every((v) => chapterHighlights[v]?.colorId == opt.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ColorDot(
                      color: opt.color,
                      isActive: isActive,
                      onTap: () => onColorPick(opt.id),
                    ),
                  );
                }),
                // Remove button (only if at least one is highlighted)
                if (hasHighlight) ...[
                  _PanelBtn(
                    icon: Icons.remove_circle_outline_rounded,
                    color: theme.textMuted,
                    onTap: onRemove,
                  ),
                  const SizedBox(width: 2),
                ],
                // Share icon
                _PanelBtn(
                  icon: Icons.ios_share_rounded,
                  color: theme.textMuted,
                  onTap: onShare,
                ),
                Container(width: 1, height: 20, color: theme.hairline),
                const SizedBox(width: 2),
                // Dismiss
                _PanelBtn(
                  icon: Icons.close_rounded,
                  color: theme.textMuted,
                  onTap: onDismiss,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildRef(List<int> verses) {
    const abbrs = <String, String>{
      'Genesis': 'Gen', 'Exodus': 'Ex', 'Leviticus': 'Lev', 'Numbers': 'Num',
      'Deuteronomy': 'Deut', 'Joshua': 'Josh', 'Judges': 'Judg',
      '1 Samuel': '1 Sam', '2 Samuel': '2 Sam',
      '1 Kings': '1 Kgs', '2 Kings': '2 Kgs',
      'Psalms': 'Ps', 'Proverbs': 'Prov', 'Ecclesiastes': 'Ecc',
      'Song of Solomon': 'Song', 'Isaiah': 'Isa', 'Jeremiah': 'Jer',
      'Matthew': 'Matt', 'Mark': 'Mk', 'Luke': 'Lk', 'John': 'Jn',
      'Romans': 'Rom', '1 Corinthians': '1 Cor', '2 Corinthians': '2 Cor',
      'Galatians': 'Gal', 'Ephesians': 'Eph', 'Philippians': 'Phil',
      'Colossians': 'Col', 'Hebrews': 'Heb', 'Revelation': 'Rev',
    };
    final abbr = abbrs[book] ?? book;
    if (verses.length == 1) return '$abbr $chapter:${verses.first}';
    bool consecutive = true;
    for (int i = 1; i < verses.length; i++) {
      if (verses[i] != verses[i - 1] + 1) {
        consecutive = false;
        break;
      }
    }
    return consecutive
        ? '$abbr $chapter:${verses.first}–${verses.last}'
        : '$abbr $chapter:${verses.join(', ')}';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.isActive, required this.onTap});
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isActive ? 30 : 25,
        height: isActive ? 30 : 25,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.75)
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)]
              : null,
        ),
      ),
    );
  }
}

class _PanelBtn extends StatelessWidget {
  const _PanelBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Center(child: Icon(icon, color: color, size: 19)),
      ),
    );
  }
}

