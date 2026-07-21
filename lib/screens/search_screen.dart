import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/abide_theme.dart';
import '../data/search_models.dart';
import '../data/search_service.dart';
import '../data/seek_entry.dart';
import '../data/highlights_service.dart';
import 'scripture_screen.dart';
import 'seek_answer_screen.dart';

// ── SEEK topic categories ─────────────────────────────────────────────────────

const _kSeekTopics = [
  ('Salvation',     Icons.favorite_rounded),
  ('Jesus Christ',  Icons.brightness_7_rounded),
  ('Holy Spirit',   Icons.air_rounded),
  ('Prayer',        Icons.volunteer_activism_rounded),
  ('Theology',      Icons.menu_book_rounded),
  ('Christian Life',Icons.directions_walk_rounded),
  ('Church',        Icons.people_rounded),
  ('Old Testament', Icons.history_edu_rounded),
];

// ── Shell ─────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _highlightsKey = GlobalKey<_HighlightsTabState>();
  static const _translation = 'ASR';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.index == 2 && !_tabs.indexIsChanging) {
      _highlightsKey.currentState?._load();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Column(
        children: [
          _SearchHeader(tabs: _tabs, topPad: top, theme: theme),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ScriptureTab(translation: _translation, theme: theme),
                _SeekTab(theme: theme),
                _HighlightsTab(key: _highlightsKey, theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header with tab bar ────────────────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.tabs,
    required this.topPad,
    required this.theme,
  });
  final TabController tabs;
  final double topPad;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.bgMenu,
      child: Column(
        children: [
          SizedBox(height: topPad + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Search',
                  style: theme.bodyFont(22).copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: tabs,
            labelColor: theme.textAccent,
            unselectedLabelColor: theme.textMuted,
            indicatorColor: theme.textAccent,
            indicatorWeight: 1.5,
            labelStyle: theme.bodyFont(13).copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
            unselectedLabelStyle: theme.bodyFont(13).copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                ),
            tabs: const [
              Tab(text: 'SCRIPTURE'),
              Tab(text: 'SEEK'),
              Tab(text: 'HIGHLIGHTS'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared: search field ───────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.theme,
    required this.hint,
    this.onSubmitted,
    this.onChanged,
  });
  final TextEditingController controller;
  final AbideThemeData theme;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.subtleFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.subtleOutline, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 18, color: theme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: theme.bodyFont(15).copyWith(
                    color: theme.textPrimary,
                    letterSpacing: 0,
                  ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.bodyFont(15).copyWith(color: theme.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, val, child) => val.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () => controller.clear(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.close_rounded, size: 16, color: theme.textMuted),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}


// ── Shared: shimmer placeholder ────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final op = 0.04 + _anim.value * 0.05;
        final bg = theme.isLight ? Colors.black.withValues(alpha: op) : Colors.white.withValues(alpha: op);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.subtleOutline, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 11, width: 80, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 10),
              Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Container(height: 10, width: double.infinity * 0.8, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Container(height: 10, width: 180, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        );
      },
    );
  }
}

// ── Scripture tab ─────────────────────────────────────────────────────────────

class _ScriptureTab extends StatefulWidget {
  const _ScriptureTab({required this.translation, required this.theme});
  final String translation;
  final AbideThemeData theme;

  @override
  State<_ScriptureTab> createState() => _ScriptureTabState();
}

class _ScriptureTabState extends State<_ScriptureTab>
    with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<VerseResult> _results = [];
  bool _loading = false;
  bool _indexing = false; // true only on the very first search (corpus load)
  bool _hasSearched = false;
  String _lastQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    SearchService.instance.warmUp(widget.translation);
  }

  @override
  void didUpdateWidget(_ScriptureTab old) {
    super.didUpdateWidget(old);
    if (old.translation != widget.translation) {
      SearchService.instance.warmUp(widget.translation);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; _loading = false; _indexing = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(q));
  }

  Future<void> _run(String q) async {
    if (q == _lastQuery) return;
    _lastQuery = q;
    // Show "Building index…" only on first-ever search for this translation
    final firstLoad = !SearchService.instance.hasCorpus(widget.translation);
    setState(() { _loading = true; _indexing = firstLoad; _hasSearched = true; });
    try {
      final res = await SearchService.instance.search(q, widget.translation);
      if (mounted && _lastQuery == q) {
        setState(() { _results = res; _loading = false; _indexing = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _indexing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = widget.theme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: _SearchField(
            controller: _ctrl,
            theme: t,
            hint: 'Search scripture…',
            onChanged: _onChanged,
            onSubmitted: _run,
          ),
        ),
        Expanded(
          child: _loading
              ? _indexing
                  ? _IndexingState(theme: t)
                  : ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) => const _ShimmerCard(),
                    )
              : !_hasSearched
                  ? _EmptyState(theme: t, message: 'Search the living Word')
                  : _results.isEmpty
                      ? _EmptyState(theme: t, message: 'No verses found for\n"${_ctrl.text}"')
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: _results.length,
                          itemBuilder: (_, i) => _VerseResultCard(
                            result: _results[i],
                            query: _ctrl.text,
                            theme: t,
                          ),
                        ),
        ),
      ],
    );
  }
}

class _IndexingState extends StatelessWidget {
  const _IndexingState({required this.theme});
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.textAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Building search index…',
            style: theme.bodyFont(14).copyWith(color: theme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Only happens once',
            style: theme.bodyFont(12).copyWith(color: theme.textMuted.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// ── Verse result card ─────────────────────────────────────────────────────────

class _VerseResultCard extends StatelessWidget {
  const _VerseResultCard({
    required this.result,
    required this.query,
    required this.theme,
  });
  final VerseResult result;
  final String query;
  final AbideThemeData theme;

  void _openDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => _VerseDetailPage(result: result),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                Text(
                  result.displayRef,
                  style: theme.bodyFont(11).copyWith(
                        color: theme.textAccent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const Spacer(),
                Text(
                  result.translation,
                  style: theme.bodyFont(10).copyWith(
                        color: theme.textMuted,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _HighlightedText(
              text: result.text,
              query: query,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.theme,
  });
  final String text;
  final String query;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    final base = theme.bodyFont(14).copyWith(
          color: theme.textPrimary.withValues(alpha: 0.85),
          height: 1.55,
        );

    // Only highlight when the full phrase is found — no first-word fallback
    final lc = text.toLowerCase();
    final phrase = query.trim().toLowerCase();
    final start = lc.indexOf(phrase);

    if (start == -1) return Text(text, style: base);

    final end = start + phrase.length;
    return Text.rich(TextSpan(children: [
      TextSpan(text: text.substring(0, start), style: base),
      TextSpan(
        text: text.substring(start, end),
        style: base.copyWith(
          color: theme.textAccent,
          fontWeight: FontWeight.w600,
          backgroundColor: theme.textAccent.withValues(alpha: 0.12),
        ),
      ),
      TextSpan(text: text.substring(end), style: base),
    ]));
  }
}

// ── Seek tab ──────────────────────────────────────────────────────────────────

class _SeekTab extends StatefulWidget {
  const _SeekTab({required this.theme});
  final AbideThemeData theme;

  @override
  State<_SeekTab> createState() => _SeekTabState();
}

class _SeekTabState extends State<_SeekTab>
    with AutomaticKeepAliveClientMixin {
  List<SeekEntry> _all = [];
  bool _loading = true;
  String? _activeTopic;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await SeekIndexService.instance.loadAll();
    if (mounted) setState(() { _all = entries; _loading = false; });
  }

  void _selectTopic(String topic) {
    setState(() {
      _activeTopic = _activeTopic == topic ? null : topic;
    });
  }

  List<SeekEntry> get _displayList {
    if (_activeTopic != null) {
      return _all.where((e) => e.topics.contains(_activeTopic)).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = widget.theme;

    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 14),
        itemCount: 5,
        itemBuilder: (_, _) => const _ShimmerCard(),
      );
    }

    if (_activeTopic == null) {
      return _SeekLanding(
        all: _all,
        topics: _kSeekTopics,
        theme: t,
        onTopicTap: _selectTopic,
      );
    }

    return _SeekResultList(
      entries: _displayList,
      all: _all,
      activeTopic: _activeTopic!,
      theme: t,
      onClearTopic: () => setState(() => _activeTopic = null),
    );
  }
}

// ── Landing ───────────────────────────────────────────────────────────────────

class _SeekLanding extends StatelessWidget {
  const _SeekLanding({
    required this.all,
    required this.topics,
    required this.theme,
    required this.onTopicTap,
  });
  final List<SeekEntry> all;
  final List<(String, IconData)> topics;
  final AbideThemeData theme;
  final ValueChanged<String> onTopicTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEEK',
            style: t.bodyFont(42).copyWith(
                  color: t.textAccent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Biblical questions answered from\nBarnes & Jamieson-Fausset-Brown',
            style: t.bodyFont(13).copyWith(
                  color: t.textMuted,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 28),
          Text(
            'TOPICS',
            style: t.bodyFont(10).copyWith(
                  color: t.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemCount: topics.length,
            itemBuilder: (_, i) {
              final (label, icon) = topics[i];
              final count = all.where((e) => e.topics.contains(label)).length;
              return _TopicCard(
                label: label,
                icon: icon,
                count: count,
                theme: t,
                onTap: () => onTopicTap(label),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.label,
    required this.icon,
    required this.count,
    required this.theme,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final int count;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.subtleOutline, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: t.textAccent.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: t.bodyFont(13).copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count > 0)
                    Text(
                      '$count question${count == 1 ? '' : 's'}',
                      style: t.bodyFont(11).copyWith(color: t.textMuted),
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

// ── Result list ───────────────────────────────────────────────────────────────

class _SeekResultList extends StatelessWidget {
  const _SeekResultList({
    required this.entries,
    required this.all,
    required this.activeTopic,
    required this.theme,
    required this.onClearTopic,
  });
  final List<SeekEntry> entries;
  final List<SeekEntry> all;
  final String activeTopic;
  final AbideThemeData theme;
  final VoidCallback onClearTopic;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic header with clear button
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  activeTopic,
                  style: t.bodyFont(14).copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClearTopic,
                  child: Text(
                    'All topics',
                    style: t.bodyFont(13).copyWith(color: t.textAccent),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: entries.isEmpty
              ? _EmptyState(
                  theme: t,
                  message: 'No questions found\nfor "$activeTopic"',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _SeekQuestionCard(
                    entry: entries[i],
                    all: all,
                    theme: t,
                  ),
                ),
        ),
      ],
    );
  }
}

class _SeekQuestionCard extends StatelessWidget {
  const _SeekQuestionCard({
    required this.entry,
    required this.all,
    required this.theme,
  });
  final SeekEntry entry;
  final List<SeekEntry> all;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: () => SeekAnswerScreen.open(context, entry, all),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.subtleOutline, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.question,
                    style: t.bodyFont(15).copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.shortAnswer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyFont(12).copyWith(
                          color: t.textMuted,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Highlights tab ────────────────────────────────────────────────────────────

class _HighlightsTab extends StatefulWidget {
  const _HighlightsTab({super.key, required this.theme});
  final AbideThemeData theme;

  @override
  State<_HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends State<_HighlightsTab>
    with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  List<Highlight> _allHighlights = [];
  bool _loading = true;
  String _activeTag = 'All';

  @override
  bool get wantKeepAlive => true;

  List<String> get _userTags {
    final set = <String>{};
    for (final h in _allHighlights) {
      set.addAll(h.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

  // Groups highlights by groupId, sorted by verse within each group.
  List<List<Highlight>> get _groupedFiltered {
    final q = _ctrl.text.trim().toLowerCase();
    var list = _allHighlights;
    if (q.isNotEmpty) {
      list = list.where((h) =>
        h.text.toLowerCase().contains(q) ||
        h.ref.toLowerCase().contains(q) ||
        h.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }
    if (_activeTag != 'All') {
      list = list.where((h) => h.tags.contains(_activeTag)).toList();
    }
    // Group by groupId preserving insertion order, sort each group by verse
    final order = <String>[];
    final map = <String, List<Highlight>>{};
    for (final h in list) {
      if (!map.containsKey(h.groupId)) {
        order.add(h.groupId);
        map[h.groupId] = [];
      }
      map[h.groupId]!.add(h);
    }
    for (final g in map.values) {
      g.sort((a, b) => a.verse.compareTo(b.verse));
    }
    // Sort groups by most-recently created (descending)
    order.sort((a, b) {
      final ta = map[a]!.first.createdAt;
      final tb = map[b]!.first.createdAt;
      return tb.compareTo(ta);
    });
    return order.map((id) => map[id]!).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await HighlightsService.instance.getAll();
    if (mounted) {
      setState(() {
        _allHighlights = List.from(all);
        _loading = false;
        if (_activeTag != 'All' && !_userTags.contains(_activeTag)) {
          _activeTag = 'All';
        }
      });
    }
  }

  Future<void> _updateGroup(String groupId, {String? colorId, List<String>? tags}) async {
    await HighlightsService.instance.updateGroup(groupId, colorId: colorId, tags: tags);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = widget.theme;
    final userTags = _userTags;
    final groups = _groupedFiltered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: _SearchField(
            controller: _ctrl,
            theme: t,
            hint: 'Filter highlights…',
            onChanged: (_) {},
          ),
        ),
        // Tag filter bar
        if (!_loading && _allHighlights.isNotEmpty) ...[
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', ...userTags].map((tag) {
                final isActive = _activeTag == tag;
                return GestureDetector(
                  onTap: () => setState(() => _activeTag = tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? t.textAccent : t.subtleFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isActive ? Colors.transparent : t.subtleOutline,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? t.bgApp : t.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: _loading
              ? ListView.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) => const _ShimmerCard(),
                )
              : groups.isEmpty
                  ? _EmptyState(
                      theme: t,
                      message: _allHighlights.isEmpty
                          ? 'No highlights yet.\nTap a verse to highlight it.'
                          : _activeTag != 'All'
                              ? 'No highlights tagged "$_activeTag"'
                              : 'No highlights match\n"${_ctrl.text}"',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: groups.length,
                      itemBuilder: (_, i) => _HighlightCard(
                        key: ValueKey(groups[i].first.groupId),
                        group: groups[i],
                        theme: t,
                        userTags: userTags,
                        onUpdateGroup: _updateGroup,
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Highlight color map ───────────────────────────────────────────────────────

Color _highlightColor(String colorId, AbideThemeData theme) {
  const map = {
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
    // Legacy IDs
    'blue':   Color(0xFF5B8DD9),
    'green':  Color(0xFF5BAD7A),
    'purple': Color(0xFF9B7BD9),
  };
  return map[colorId] ?? theme.textAccent;
}

class _HighlightCard extends StatefulWidget {
  const _HighlightCard({
    super.key,
    required this.group,
    required this.theme,
    required this.userTags,
    required this.onUpdateGroup,
  });
  // All highlights sharing the same groupId, sorted by verse ascending
  final List<Highlight> group;
  final AbideThemeData theme;
  final List<String> userTags;
  final Future<void> Function(String groupId, {String? colorId, List<String>? tags}) onUpdateGroup;

  @override
  State<_HighlightCard> createState() => _HighlightCardState();
}

class _HighlightCardState extends State<_HighlightCard> {
  bool _tagPanelOpen = false;
  final _newTagCtrl = TextEditingController();

  @override
  void dispose() {
    _newTagCtrl.dispose();
    super.dispose();
  }

  Highlight get _first => widget.group.first;
  List<String> get _currentTags => _first.tags;

  String get _ref {
    final g = widget.group;
    final book = g.first.book;
    final chapter = g.first.chapter;
    if (g.length == 1) return '$book $chapter:${g.first.verse}';
    return '$book $chapter:${g.first.verse}–${g.last.verse}';
  }

  String get _combinedText => widget.group.map((h) => h.text).join(' ');

  Future<void> _toggleTag(String tag) async {
    final newTags = _currentTags.contains(tag)
        ? _currentTags.where((t) => t != tag).toList()
        : [..._currentTags, tag];
    await widget.onUpdateGroup(_first.groupId, tags: newTags);
  }

  Future<void> _addNewTag() async {
    final tag = _newTagCtrl.text.trim();
    if (tag.isEmpty || _currentTags.contains(tag)) return;
    _newTagCtrl.clear();
    await widget.onUpdateGroup(_first.groupId, tags: [..._currentTags, tag]);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final color = _highlightColor(_first.colorId, t);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.subtleOutline, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent rail
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: ref + translation
                  Row(
                    children: [
                      Text(
                        _ref,
                        style: t.bodyFont(11).copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        _first.translation,
                        style: t.bodyFont(10).copyWith(color: t.textMuted, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  // Combined verse text
                  Text(
                    _combinedText,
                    style: t.bodyFont(14).copyWith(
                          color: t.textPrimary.withValues(alpha: 0.88),
                          height: 1.55,
                        ),
                  ),
                  // Applied tag chips
                  if (_currentTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _currentTags.map((tag) => GestureDetector(
                        onTap: () => _toggleTag(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
                          ),
                          child: Text(
                            tag,
                            style: t.bodyFont(11).copyWith(color: color, letterSpacing: 0.2),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // + Tag button
                  GestureDetector(
                    onTap: () => setState(() => _tagPanelOpen = !_tagPanelOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _tagPanelOpen
                              ? color.withValues(alpha: 0.4)
                              : t.subtleOutline,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _tagPanelOpen ? '✕ Close' : '+ Tag',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _tagPanelOpen ? color : t.textAccent,
                        ),
                      ),
                    ),
                  ),
                  // Expandable tag panel
                  if (_tagPanelOpen) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.userTags.isNotEmpty) ...[
                            Text(
                              'YOUR TAGS',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                letterSpacing: 1.4,
                                color: color.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: widget.userTags.map((tag) {
                                final active = _currentTags.contains(tag);
                                return GestureDetector(
                                  onTap: () => _toggleTag(tag),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 130),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: active ? color.withValues(alpha: 0.18) : t.subtleFill,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: active ? color.withValues(alpha: 0.4) : t.subtleOutline,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${active ? "✓ " : ""}$tag',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: active ? color : t.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Container(height: 0.5, color: color.withValues(alpha: 0.12)),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            'NEW TAG',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              letterSpacing: 1.4,
                              color: color.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: t.subtleFill,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: t.subtleOutline, width: 0.5),
                                  ),
                                  child: TextField(
                                    controller: _newTagCtrl,
                                    onSubmitted: (_) => _addNewTag(),
                                    textInputAction: TextInputAction.done,
                                    style: t.bodyFont(13).copyWith(color: t.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. faith, grace…',
                                      hintStyle: t.bodyFont(13).copyWith(color: t.textMuted),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _addNewTag,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Add',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
}

// ── Verse detail page ─────────────────────────────────────────────────────────

class _VerseDetailPage extends StatelessWidget {
  const _VerseDetailPage({required this.result});
  final VerseResult result;

  void _readChapter(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => ScriptureScreen(
          initialBook: result.book,
          initialChapter: result.chapter,
          initialTranslation: result.translation.toLowerCase(),
          showNav: true,
          skipSavedPosition: true,
        ),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            color: theme.bgMenu,
            padding: EdgeInsets.only(top: topPad),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: theme.textPrimary),
                  ),
                ),
                Expanded(
                  child: Text(
                    result.displayRef,
                    style: theme.bodyFont(17).copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.subtleFill,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.subtleOutline, width: 0.5),
                  ),
                  child: Text(
                    result.translation,
                    style: theme.bodyFont(11).copyWith(
                          color: theme.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // ── Verse text ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
              child: Text(
                result.text,
                style: theme.bodyFont(22).copyWith(
                      color: theme.textPrimary,
                      height: 1.7,
                      letterSpacing: -0.2,
                    ),
              ),
            ),
          ),
          // ── Read chapter button ───────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
            decoration: BoxDecoration(
              color: theme.bgMenu,
              border: Border(top: BorderSide(color: theme.hairline, width: 0.5)),
            ),
            child: GestureDetector(
              onTap: () => _readChapter(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: theme.textAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 16, color: theme.bgApp),
                    const SizedBox(width: 8),
                    Text(
                      'Read ${result.book} ${result.chapter}',
                      style: theme.bodyFont(15).copyWith(
                            color: theme.bgApp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared: empty state ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.message});
  final AbideThemeData theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.bodyFont(15).copyWith(
                color: theme.textMuted,
                height: 1.6,
                letterSpacing: 0.1,
              ),
        ),
      ),
    );
  }
}
