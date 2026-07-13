import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/abide_theme.dart';
import '../data/reflection_service.dart';
import '../data/cross_ref_service.dart';

// ── Chapter footer: Reflection + Cross References ────────────────────────────
// Inline at the bottom of the scroll — no modal. Better than the PWA.

class ChapterFooter extends StatefulWidget {
  const ChapterFooter({
    super.key,
    required this.book,
    required this.chapter,
    required this.translation,
    required this.onNavigate,
  });

  final String book;
  final int chapter;
  final String translation;
  final void Function(String book, int chapter) onNavigate;

  @override
  State<ChapterFooter> createState() => _ChapterFooterState();
}

class _ChapterFooterState extends State<ChapterFooter> {
  bool _showReflection = false;
  bool _showCrossRefs = false;
  final _toggleKey = GlobalKey();

  @override
  void didUpdateWidget(ChapterFooter old) {
    super.didUpdateWidget(old);
    if (old.book != widget.book || old.chapter != widget.chapter) {
      setState(() {
        _showReflection = false;
        _showCrossRefs = false;
      });
    }
  }

  void _scrollToToggles() {
    final ctx = _toggleKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ornamental divider ────────────────────────────────────────────
        _OrnamentalDivider(theme: theme),
        const SizedBox(height: 28),

        // ── Section toggles ───────────────────────────────────────────────
        Padding(
          key: _toggleKey,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              _SectionToggle(
                label: 'REFLECTION',
                icon: Icons.auto_awesome_rounded,
                active: _showReflection,
                theme: theme,
                onTap: () => setState(() {
                  _showReflection = !_showReflection;
                  if (_showReflection) _showCrossRefs = false;
                }),
              ),
              const SizedBox(width: 12),
              _SectionToggle(
                label: 'CROSS REFERENCES',
                icon: Icons.account_tree_outlined,
                active: _showCrossRefs,
                theme: theme,
                onTap: () => setState(() {
                  _showCrossRefs = !_showCrossRefs;
                  if (_showCrossRefs) _showReflection = false;
                }),
              ),
            ],
          ),
        ),

        // ── Reflection panel ──────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _showReflection
              ? _ReflectionPanel(
                  book: widget.book,
                  chapter: widget.chapter,
                  theme: theme,
                  onScrollToTop: _scrollToToggles,
                )
              : const SizedBox.shrink(),
        ),

        // ── Cross references panel ────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _showCrossRefs
              ? _CrossRefsPanel(
                  book: widget.book,
                  chapter: widget.chapter,
                  translation: widget.translation,
                  theme: theme,
                  onNavigate: widget.onNavigate,
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 160),
      ],
    );
  }
}

// ── Ornamental divider ────────────────────────────────────────────────────────

class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider({required this.theme});
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5, color: theme.hairline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3, height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.textMuted.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.textAccent.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3, height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.textMuted.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Container(height: 0.5, color: theme.hairline)),
        ],
      ),
    );
  }
}

// ── Section toggle button ─────────────────────────────────────────────────────

class _SectionToggle extends StatelessWidget {
  const _SectionToggle({
    required this.label,
    required this.icon,
    required this.active,
    required this.theme,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? theme.textAccent.withValues(alpha: 0.12)
              : theme.subtleFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? theme.textAccent.withValues(alpha: 0.35) : theme.subtleOutline,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? theme.textAccent : theme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.bodyFont(11).copyWith(
                    color: active ? theme.textAccent : theme.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reflection panel ──────────────────────────────────────────────────────────

class _ReflectionPanel extends StatefulWidget {
  const _ReflectionPanel({
    required this.book,
    required this.chapter,
    required this.theme,
    required this.onScrollToTop,
  });
  final String book;
  final int chapter;
  final AbideThemeData theme;
  final VoidCallback onScrollToTop;

  @override
  State<_ReflectionPanel> createState() => _ReflectionPanelState();
}

class _ReflectionPanelState extends State<_ReflectionPanel> {
  List<String>? _paragraphs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ReflectionPanel old) {
    super.didUpdateWidget(old);
    if (old.book != widget.book || old.chapter != widget.chapter) {
      setState(() { _paragraphs = null; _loading = true; _error = null; });
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final p = await ReflectionService.instance.load(widget.book, widget.chapter);
      if (mounted) setState(() { _paragraphs = p; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load reflection'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.textAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.textAccent.withValues(alpha: 0.1), width: 0.5),
        ),
        child: _loading
            ? _ReflectionShimmer(theme: t)
            : _error != null
                ? Text(_error!, style: t.bodyFont(14).copyWith(color: t.textMuted))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 13, color: t.textAccent.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.book} ${widget.chapter}',
                            style: t.bodyFont(11).copyWith(
                                  color: t.textAccent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Paragraphs
                      ...(_paragraphs ?? []).asMap().entries.map((e) => Padding(
                            padding: EdgeInsets.only(bottom: e.key < (_paragraphs!.length - 1) ? 16 : 0),
                            child: Text(
                              e.value,
                              style: t.bodyFont(16).copyWith(
                                    color: t.textPrimary.withValues(alpha: 0.88),
                                    height: 1.85,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                          )),
                      // ── Disclaimer ──────────────────────────────────────
                      const SizedBox(height: 20),
                      Container(height: 0.5, color: t.textAccent.withValues(alpha: 0.12)),
                      const SizedBox(height: 14),
                      Text(
                        'These are AI-generated reflections to engage in meditation of the Word. They are not inspirations of the Holy Spirit. Seek God for His revelation through the Scriptures.',
                        style: t.bodyFont(12).copyWith(
                              color: t.textMuted,
                              height: 1.65,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.1,
                            ),
                      ),
                      // ── Scroll-to-top chevron ────────────────────────────
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: widget.onScrollToTop,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 20,
                              color: t.textAccent.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Back to top',
                              style: t.bodyFont(12).copyWith(
                                    color: t.textAccent.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
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

class _ReflectionShimmer extends StatefulWidget {
  const _ReflectionShimmer({required this.theme});
  final AbideThemeData theme;

  @override
  State<_ReflectionShimmer> createState() => _ReflectionShimmerState();
}

class _ReflectionShimmerState extends State<_ReflectionShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final op = 0.06 + _anim.value * 0.07;
        final bg = (t.isLight ? Colors.black : Colors.white).withValues(alpha: op);
        Widget bar(double w) => Container(
          height: 11, width: w,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(120),
            const SizedBox(height: 14),
            bar(double.infinity), bar(double.infinity), bar(200),
            const SizedBox(height: 16),
            bar(double.infinity), bar(double.infinity), bar(240),
            const SizedBox(height: 16),
            bar(double.infinity), bar(180),
          ],
        );
      },
    );
  }
}

// ── Cross references panel ────────────────────────────────────────────────────

class _CrossRefsPanel extends StatefulWidget {
  const _CrossRefsPanel({
    required this.book,
    required this.chapter,
    required this.translation,
    required this.theme,
    required this.onNavigate,
  });
  final String book;
  final int chapter;
  final String translation;
  final AbideThemeData theme;
  final void Function(String book, int chapter) onNavigate;

  @override
  State<_CrossRefsPanel> createState() => _CrossRefsPanelState();
}

class _CrossRefsPanelState extends State<_CrossRefsPanel> {
  List<CrossRef>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_CrossRefsPanel old) {
    super.didUpdateWidget(old);
    if (old.book != widget.book || old.chapter != widget.chapter) {
      setState(() { _data = null; _loading = true; });
      _load();
    }
  }

  Future<void> _load() async {
    final data = await CrossRefService.instance.load(widget.book, widget.chapter);
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: t.textAccent.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    if (_data == null || _data!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
        child: Text(
          'No cross references for this chapter',
          style: t.bodyFont(14).copyWith(color: t.textMuted),
        ),
      );
    }

    final totalRefs = _data!.fold(0, (sum, cr) => sum + cr.refs.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.subtleFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.subtleOutline, width: 0.5),
            ),
            child: Text(
              '$totalRefs references across ${_data!.length} verses',
              style: t.bodyFont(12).copyWith(
                    color: t.textMuted,
                    letterSpacing: 0.1,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // Verse groups
          ..._data!.map((cr) => _VerseGroup(
                crossRef: cr,
                book: widget.book,
                chapter: widget.chapter,
                translation: widget.translation,
                theme: t,
                onNavigate: widget.onNavigate,
              )),
        ],
      ),
    );
  }
}

// ── Verse group ───────────────────────────────────────────────────────────────

class _VerseGroup extends StatefulWidget {
  const _VerseGroup({
    required this.crossRef,
    required this.book,
    required this.chapter,
    required this.translation,
    required this.theme,
    required this.onNavigate,
  });
  final CrossRef crossRef;
  final String book;
  final int chapter;
  final String translation;
  final AbideThemeData theme;
  final void Function(String book, int chapter) onNavigate;

  @override
  State<_VerseGroup> createState() => _VerseGroupState();
}

class _VerseGroupState extends State<_VerseGroup> {
  String? _expandedRef;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final cr = widget.crossRef;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse number header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.textAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'v.${cr.verseNum}',
                  style: t.bodyFont(11).copyWith(
                        color: t.textAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 0.5, color: t.hairline)),
            ],
          ),
          const SizedBox(height: 10),
          // Reference pills + inline preview
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cr.refs.map((ref) {
              final target = CrossRefService.instance.parseRef(ref);
              if (target == null) return const SizedBox.shrink();
              final isExpanded = _expandedRef == ref;
              return _RefChip(
                ref: ref,
                target: target,
                isExpanded: isExpanded,
                theme: t,
                translation: widget.translation,
                onTap: () => setState(() => _expandedRef = isExpanded ? null : ref),
                onNavigate: widget.onNavigate,
              );
            }).toList(),
          ),
          // Expanded inline verse preview
          if (_expandedRef != null) ...[
            const SizedBox(height: 10),
            _InlineVerseCard(
              rawRef: _expandedRef!,
              translation: widget.translation,
              theme: t,
              onNavigate: widget.onNavigate,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Ref chip ──────────────────────────────────────────────────────────────────

class _RefChip extends StatelessWidget {
  const _RefChip({
    required this.ref,
    required this.target,
    required this.isExpanded,
    required this.theme,
    required this.translation,
    required this.onTap,
    required this.onNavigate,
  });
  final String ref;
  final CrossRefTarget target;
  final bool isExpanded;
  final AbideThemeData theme;
  final String translation;
  final VoidCallback onTap;
  final void Function(String, int) onNavigate;

  // OT books end before Matthew — tint them slightly differently
  bool get _isOT {
    const otBooks = {
      'Genesis','Exodus','Leviticus','Numbers','Deuteronomy','Joshua','Judges',
      'Ruth','1 Samuel','2 Samuel','1 Kings','2 Kings','1 Chronicles','2 Chronicles',
      'Ezra','Nehemiah','Esther','Job','Psalms','Proverbs','Ecclesiastes',
      'Song of Solomon','Isaiah','Jeremiah','Lamentations','Ezekiel','Daniel',
      'Hosea','Joel','Amos','Obadiah','Jonah','Micah','Nahum','Habakkuk',
      'Zephaniah','Haggai','Zechariah','Malachi',
    };
    return otBooks.contains(target.book);
  }

  String get _displayLabel {
    // "john 3:16-18" → "John 3:16"
    final slug = ref.replaceAll(RegExp(r'-\d+$'), '');
    final m = RegExp(r'^(.*?)\s+(\d+):(\d+)$').firstMatch(slug.trim());
    if (m == null) return ref;
    return '${target.book} ${m.group(2)}:${m.group(3)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final accent = _isOT
        ? t.textAccent.withValues(alpha: 0.7)
        : t.textAccent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isExpanded
              ? accent.withValues(alpha: 0.15)
              : t.subtleFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? accent.withValues(alpha: 0.4) : t.subtleOutline,
            width: 0.5,
          ),
        ),
        child: Text(
          _displayLabel,
          style: t.bodyFont(12).copyWith(
                color: isExpanded ? accent : t.textMuted,
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
              ),
        ),
      ),
    );
  }
}

// ── Inline verse card (expands below selected chip) ───────────────────────────

class _InlineVerseCard extends StatefulWidget {
  const _InlineVerseCard({
    required this.rawRef,
    required this.translation,
    required this.theme,
    required this.onNavigate,
  });
  final String rawRef;
  final String translation;
  final AbideThemeData theme;
  final void Function(String book, int chapter) onNavigate;

  @override
  State<_InlineVerseCard> createState() => _InlineVerseCardState();
}

class _InlineVerseCardState extends State<_InlineVerseCard>
    with SingleTickerProviderStateMixin {
  String? _text;
  CrossRefTarget? _target;
  bool _loading = true;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void didUpdateWidget(_InlineVerseCard old) {
    super.didUpdateWidget(old);
    if (old.rawRef != widget.rawRef) {
      setState(() { _text = null; _loading = true; });
      _load();
    }
  }

  Future<void> _load() async {
    final target = CrossRefService.instance.parseRef(widget.rawRef);
    if (target == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final text = await CrossRefService.instance.fetchVerseText(target, widget.translation);
    if (mounted) {
      setState(() { _target = target; _text = text; _loading = false; });
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.subtleOutline, width: 0.5),
        ),
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: t.textAccent.withValues(alpha: 0.4),
        ),
      );
    }

    if (_target == null || (_text?.isEmpty ?? true)) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.subtleOutline, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ref header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${_target!.book} ${_target!.chapter}:${_target!.verse}',
                    style: t.bodyFont(11).copyWith(
                          color: t.textAccent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    widget.translation.toUpperCase(),
                    style: t.bodyFont(10).copyWith(color: t.textMuted, letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
            // Verse text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _text!,
                style: t.bodyFont(14).copyWith(
                      color: t.textPrimary.withValues(alpha: 0.88),
                      height: 1.6,
                    ),
              ),
            ),
            // Go-to button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onNavigate(_target!.book, _target!.chapter);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward_ios_rounded, size: 11, color: t.textAccent),
                    const SizedBox(width: 5),
                    Text(
                      'Read ${_target!.book} ${_target!.chapter}',
                      style: t.bodyFont(12).copyWith(
                            color: t.textAccent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
