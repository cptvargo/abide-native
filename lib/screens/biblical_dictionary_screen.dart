import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/bible_dictionary_service.dart';
import '../theme/abide_theme.dart';
import 'biblical_dictionary_entry_screen.dart';

class BiblicalDictionaryScreen extends StatefulWidget {
  const BiblicalDictionaryScreen({super.key});

  @override
  State<BiblicalDictionaryScreen> createState() =>
      _BiblicalDictionaryScreenState();
}

class _BiblicalDictionaryScreenState extends State<BiblicalDictionaryScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<BibDictEntry> _all = [];
  List<BibDictEntry> _filtered = [];
  bool _isFiltered = false;
  String _activeCategory = '';
  bool _loading = true;

  late final AnimationController _loadCtrl;
  late final Animation<double> _loadFade;

  static const _popular = [
    'Grace',
    'Faith',
    'Jerusalem',
    'Passover',
    'Tabernacle',
    'Justification',
  ];

  static const _categories = [
    ('People', Icons.people_rounded),
    ('Places', Icons.place_rounded),
    ('Doctrine', Icons.auto_awesome_rounded),
    ('Biblical Terms', Icons.translate_rounded),
    ('Objects', Icons.category_rounded),
    ('Customs', Icons.history_edu_rounded),
    ('Feasts', Icons.event_rounded),
    ('Nations', Icons.public_rounded),
    ('Animals', Icons.pets_rounded),
    ('Plants', Icons.eco_rounded),
    ('Weights & Measures', Icons.scale_rounded),
    ('Prophecy', Icons.visibility_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _loadFade =
        CurvedAnimation(parent: _loadCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(_onQuery);
    _load();
  }

  @override
  void dispose() {
    _loadCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await BibDictService.instance.loadAll();
    if (!mounted) return;
    setState(() {
      _all = entries;
      _loading = false;
    });
    _loadCtrl.forward();
  }

  void _onQuery() {
    final q = _searchCtrl.text.trim();
    setState(() {
      if (q.isEmpty && _activeCategory.isEmpty) {
        _isFiltered = false;
        _filtered = [];
      } else if (q.isEmpty) {
        _filtered = _all.where((e) => e.category == _activeCategory).toList();
        _isFiltered = true;
      } else {
        _filtered = BibDictService.instance.search(q, _all);
        _isFiltered = true;
        _activeCategory = '';
      }
    });
  }

  void _browseCategory(String cat) {
    HapticFeedback.lightImpact();
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _activeCategory = cat;
      _isFiltered = true;
      _filtered = _all.where((e) => e.category == cat).toList();
    });
  }

  void _clearFilter() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _activeCategory = '';
      _isFiltered = false;
      _filtered = [];
    });
  }

  void _openEntry(BibDictEntry entry) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => BiblicalDictionaryEntryScreen(
            entry: entry, allEntries: _all),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Column(
        children: [
          _buildHeader(theme, top),
          Expanded(
            child: _loading
                ? _buildShimmer(theme)
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: _isFiltered
                        ? _buildResults(theme)
                        : _buildLanding(theme),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(AbideThemeData theme, double topInset) {
    return Container(
      color: theme.bgApp,
      padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              if (_activeCategory.isNotEmpty) ...[
                Text(
                  _activeCategory,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearFilter,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.subtleFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 12,
                            color:
                                theme.textMuted.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: theme.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Search field
          _SearchField(
            controller: _searchCtrl,
            focus: _searchFocus,
            theme: theme,
            onClear: _clearFilter,
          ),
        ],
      ),
    );
  }

  // ── Landing ──────────────────────────────────────────────────────────────────

  Widget _buildLanding(AbideThemeData theme) {
    final counts = BibDictService.instance.categoryCounts(_all);
    return FadeTransition(
      key: const ValueKey('landing'),
      opacity: _loadFade,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABIDE DICTIONARY',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: theme.textAccent.withValues(alpha: 0.50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Explore biblical people, places, doctrines, customs, and terms through trusted historical sources.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: theme.textPrimary.withValues(alpha: 0.60),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Popular entries
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 12),
              child: Text(
                'POPULAR ENTRIES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: theme.textAccent.withValues(alpha: 0.45),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _popular.map((name) {
                  final entry = _all
                      .where((e) => e.term == name)
                      .cast<BibDictEntry?>()
                      .firstOrNull;
                  return _PopularChip(
                    label: name,
                    theme: theme,
                    onTap: entry != null ? () => _openEntry(entry) : null,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // Category grid
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 12),
              child: Text(
                'BROWSE BY CATEGORY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: theme.textAccent.withValues(alpha: 0.45),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.9,
              ),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final (name, icon) = _categories[i];
                return _CategoryCard(
                  theme: theme,
                  name: name,
                  icon: icon,
                  count: counts[name] ?? 0,
                  onTap: () => _browseCategory(name),
                );
              },
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────────

  Widget _buildResults(AbideThemeData theme) {
    final query = _searchCtrl.text.trim();
    return Column(
      key: const ValueKey('results'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_filtered.isEmpty)
          Expanded(child: _buildEmptyState(theme, query))
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
            child: Text(
              '${_filtered.length} ${_filtered.length == 1 ? 'entry' : 'entries'}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: theme.textMuted.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: theme.hairline,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (_, i) => _EntryRow(
                entry: _filtered[i],
                query: query,
                theme: theme,
                onTap: () => _openEntry(_filtered[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(AbideThemeData theme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦',
              style: TextStyle(
                fontSize: 22,
                color: theme.textAccent.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'No entries in this category yet'
                  : 'No results for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'More entries are added as the dictionary grows.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: theme.textMuted.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer ──────────────────────────────────────────────────────────────────

  Widget _buildShimmer(AbideThemeData theme) {
    return _ShimmerLoader(theme: theme);
  }
}

// ── Search Field ──────────────────────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.theme,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final AbideThemeData theme;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focus.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() => _focused = widget.focus.hasFocus);

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? t.textAccent.withValues(alpha: 0.45)
              : t.subtleOutline,
          width: _focused ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: _focused
                  ? t.textAccent.withValues(alpha: 0.7)
                  : t.textMuted.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focus,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: t.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText:
                    'Search grace, Abraham, Passover, faith…',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: t.textMuted.withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: widget.onClear,
              child: Padding(
                padding:
                    const EdgeInsets.only(right: 12, left: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: t.textMuted.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Popular Chip ──────────────────────────────────────────────────────────────

class _PopularChip extends StatefulWidget {
  const _PopularChip(
      {required this.label, required this.theme, required this.onTap});

  final String label;
  final AbideThemeData theme;
  final VoidCallback? onTap;

  @override
  State<_PopularChip> createState() => _PopularChipState();
}

class _PopularChipState extends State<_PopularChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: t.textAccent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: t.textAccent.withValues(alpha: 0.20),
                width: 0.5,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textAccent.withValues(alpha: 0.85),
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.theme,
    required this.name,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final AbideThemeData theme;
  final String name;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.subtleOutline, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: t.textAccent.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.count > 0) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${widget.count} '
                        '${widget.count == 1 ? 'entry' : 'entries'}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: t.textMuted.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Entry Row ─────────────────────────────────────────────────────────────────

class _EntryRow extends StatefulWidget {
  const _EntryRow({
    required this.entry,
    required this.query,
    required this.theme,
    required this.onTap,
  });

  final BibDictEntry entry;
  final String query;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
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
      child: AnimatedOpacity(
        opacity: _pressed ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _HighlightText(
                            text: widget.entry.term,
                            query: widget.query,
                            base: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            highlight: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: t.textAccent,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.subtleFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: t.subtleOutline, width: 0.5),
                          ),
                          child: Text(
                            widget.entry.category,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: t.textMuted.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.entry.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: t.textPrimary.withValues(alpha: 0.50),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: t.textMuted.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Highlight Text ────────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.query,
    required this.base,
    required this.highlight,
  });

  final String text;
  final String query;
  final TextStyle base;
  final TextStyle highlight;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: base);

    final lower = text.toLowerCase();
    final lq = query.toLowerCase();
    if (!lower.contains(lq)) return Text(text, style: base);

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(lq, start);
      if (idx == -1) break;
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: base));
      }
      spans.add(TextSpan(
          text: text.substring(idx, idx + query.length),
          style: highlight));
      start = idx + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: base));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerLoader extends StatefulWidget {
  const _ShimmerLoader({required this.theme});
  final AbideThemeData theme;

  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.04, end: 0.11)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, _) {
        final fill = t.textPrimary.withValues(alpha: _a.value);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 5; i++) ...[
                Row(children: [
                  Expanded(
                      flex: 3,
                      child: Container(
                          height: 15, color: fill,
                          margin: const EdgeInsets.only(right: 8))),
                  Expanded(
                      flex: 2,
                      child: Container(height: 15, color: fill)),
                ]),
                const SizedBox(height: 8),
                Container(height: 12, color: fill),
                const SizedBox(height: 5),
                Container(width: 220, height: 12, color: fill),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
  }
}
