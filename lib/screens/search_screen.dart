import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/abide_theme.dart';
import '../data/search_models.dart';
import '../data/search_service.dart';
import '../data/seek_service.dart';
import '../data/highlights_service.dart';
import '../data/dictionary_service.dart';
import 'scripture_screen.dart';

// ── Topic chip data ────────────────────────────────────────────────────────────

const _kSeekTopics = [
  'What is grace?', 'What does abide mean?', 'Who is the Holy Spirit?',
  'What is the gospel?', 'Faith vs works', 'What is shalom?',
  'What is the kingdom of God?', 'Define repentance',
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
                _SeekTab(theme: theme, translation: _translation),
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
    this.textInputAction = TextInputAction.search,
  });
  final TextEditingController controller;
  final AbideThemeData theme;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

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
              textInputAction: textInputAction,
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

// ── Shared: topic chips ────────────────────────────────────────────────────────

class _TopicChips extends StatelessWidget {
  const _TopicChips({required this.chips, required this.theme, required this.onTap});
  final List<String> chips;
  final AbideThemeData theme;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          return GestureDetector(
            onTap: () => onTap(chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: theme.subtleFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.subtleOutline, width: 0.5),
              ),
              child: Text(
                chip,
                style: theme.bodyFont(12).copyWith(
                      color: theme.textMuted,
                      letterSpacing: 0.1,
                    ),
              ),
            ),
          );
        },
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
  const _SeekTab({required this.theme, required this.translation});
  final AbideThemeData theme;
  final String translation;

  @override
  State<_SeekTab> createState() => _SeekTabState();
}

class _SeekTabState extends State<_SeekTab>
    with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  SeekResult? _result;
  String _lastQuery = '';
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  bool _saved = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.collapsed(offset: q.length);
    _seek(q);
  }

  Future<void> _seek(String q) async {
    if (q.trim().isEmpty) return;
    _lastQuery = q.trim();
    setState(() { _loading = true; _error = null; _hasSearched = true; _saved = false; });
    try {
      final res = await SeekService.instance.seek(q, translation: widget.translation);
      if (mounted) setState(() { _result = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _saveToDict() async {
    if (_result == null) return;
    await DictionaryService.instance.save(_result!, _lastQuery);
    HapticFeedback.mediumImpact();
    if (mounted) setState(() => _saved = true);
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
            hint: 'Ask a question or define a word…',
            onSubmitted: _seek,
            textInputAction: TextInputAction.done,
          ),
        ),
        if (!_hasSearched)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: _TopicChips(chips: _kSeekTopics, theme: t, onTap: _setQuery),
          ),
        Expanded(
          child: _loading
              ? ListView.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) => const _ShimmerCard(),
                )
              : _error != null
                  ? _EmptyState(theme: t, message: 'Something went wrong.\nTry again.')
                  : !_hasSearched
                      ? _EmptyState(theme: t, message: 'Word studies & questions\nanswered from Scripture')
                      : _result == null
                          ? _EmptyState(theme: t, message: 'No result')
                          : _SeekResultCard(
                              result: _result!,
                              theme: t,
                              saved: _saved,
                              onSave: _saveToDict,
                            ),
        ),
      ],
    );
  }
}

// ── Seek result card ──────────────────────────────────────────────────────────

class _SeekResultCard extends StatelessWidget {
  const _SeekResultCard({
    required this.result,
    required this.theme,
    required this.saved,
    required this.onSave,
  });
  final SeekResult result;
  final AbideThemeData theme;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.type == SeekType.wordStudy) ..._buildWordStudy(),
          if (result.type == SeekType.question) ..._buildQuestion(),
          if (result.verses.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel(label: 'KEY VERSES', theme: theme),
            const SizedBox(height: 8),
            ...result.verses.map((v) => _SeekVerseCard(verse: v, theme: theme)),
          ],
          if (result.reflection != null) ...[
            const SizedBox(height: 16),
            _ReflectionCard(text: result.reflection!, theme: theme),
          ],
          const SizedBox(height: 20),
          _SaveDictionaryButton(saved: saved, onSave: onSave, theme: theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildWordStudy() {
    final t = theme;
    return [
      if (result.word != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.subtleOutline, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      result.word!,
                      style: t.bodyFont(26).copyWith(
                            color: t.textAccent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  if (result.fromCache) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.subtleFill,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: t.subtleOutline, width: 0.5),
                      ),
                      child: Text(
                        'Strong\'s',
                        style: t.bodyFont(9).copyWith(
                              color: t.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
              if (result.originalLanguage != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Badge(
                      label: result.originalLanguage!.language,
                      theme: t,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${result.originalLanguage!.word}  ·  ${result.originalLanguage!.transliteration}',
                      style: t.bodyFont(13).copyWith(
                            color: t.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.originalLanguage!.strongs,
                  style: t.bodyFont(11).copyWith(
                        color: t.textMuted,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
              if (result.definition != null) ...[
                const SizedBox(height: 14),
                Container(height: 0.5, color: t.hairline),
                const SizedBox(height: 14),
                Text(result.definition!, style: t.bodyFont(15).copyWith(color: t.textPrimary, height: 1.6)),
              ],
              if (result.significance != null) ...[
                const SizedBox(height: 14),
                Text(
                  result.significance!,
                  style: t.bodyFont(14).copyWith(
                        color: t.textPrimary.withValues(alpha: 0.7),
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildQuestion() {
    final t = theme;
    return [
      if (result.answer != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.subtleOutline, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.question != null)
                Text(
                  result.question!,
                  style: t.bodyFont(13).copyWith(
                        color: t.textAccent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                ),
              const SizedBox(height: 12),
              Text(result.answer!, style: t.bodyFont(16).copyWith(color: t.textPrimary, height: 1.65)),
              if (result.context != null) ...[
                const SizedBox(height: 12),
                Text(
                  result.context!,
                  style: t.bodyFont(14).copyWith(
                        color: t.textPrimary.withValues(alpha: 0.65),
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      if (result.exegesis != null && result.exegesis!.isNotEmpty) ...[
        const SizedBox(height: 16),
        _SectionLabel(label: 'EXEGESIS', theme: t),
        const SizedBox(height: 8),
        ...result.exegesis!.map((e) => _ExegesisCard(exegesis: e, theme: t)),
      ],
      if (result.pastoralCaution != null) ...[
        const SizedBox(height: 12),
        _PastoralCautionCard(text: result.pastoralCaution!, theme: t),
      ],
    ];
  }
}

class _SeekVerseCard extends StatelessWidget {
  const _SeekVerseCard({required this.verse, required this.theme});
  final SeekVerse verse;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.subtleOutline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verse.ref,
            style: theme.bodyFont(11).copyWith(
                  color: theme.textAccent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            verse.text,
            style: theme.bodyFont(14).copyWith(color: theme.textPrimary, height: 1.55),
          ),
          if (verse.note != null) ...[
            const SizedBox(height: 6),
            Text(
              verse.note!,
              style: theme.bodyFont(12).copyWith(
                    color: theme.textMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExegesisCard extends StatelessWidget {
  const _ExegesisCard({required this.exegesis, required this.theme});
  final SeekExegesis exegesis;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.subtleOutline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exegesis.passage,
            style: theme.bodyFont(12).copyWith(
                  color: theme.textAccent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 7),
          Text(exegesis.explanation,
              style: theme.bodyFont(14).copyWith(color: theme.textPrimary, height: 1.55)),
          if (exegesis.keyInsight.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 2, height: 14, margin: const EdgeInsets.only(top: 2, right: 8),
                    color: theme.textAccent.withValues(alpha: 0.5)),
                Expanded(
                  child: Text(
                    exegesis.keyInsight,
                    style: theme.bodyFont(13).copyWith(
                          color: theme.textPrimary.withValues(alpha: 0.65),
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PastoralCautionCard extends StatelessWidget {
  const _PastoralCautionCard({required this.text, required this.theme});
  final String text;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.christAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.christAccent.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: theme.christAccent.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.bodyFont(13).copyWith(
                    color: theme.textPrimary.withValues(alpha: 0.75),
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.text, required this.theme});
  final String text;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.textAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textAccent.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFLECT',
            style: theme.bodyFont(10).copyWith(
                  color: theme.textAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.bodyFont(15).copyWith(
                  color: theme.textPrimary,
                  height: 1.65,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Save to Dictionary button ─────────────────────────────────────────────────

class _SaveDictionaryButton extends StatelessWidget {
  const _SaveDictionaryButton({
    required this.saved,
    required this.onSave,
    required this.theme,
  });
  final bool saved;
  final VoidCallback onSave;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saved ? null : onSave,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: saved
              ? theme.textAccent.withValues(alpha: 0.10)
              : theme.textAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
              size: 16,
              color: saved ? theme.textAccent : theme.bgApp,
            ),
            const SizedBox(width: 8),
            Text(
              saved ? 'Saved to Dictionary' : 'Save to Dictionary',
              style: theme.bodyFont(14).copyWith(
                    color: saved ? theme.textAccent : theme.bgApp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
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
    if (mounted) setState(() {
      _allHighlights = List.from(all);
      _loading = false;
      if (_activeTag != 'All' && !_userTags.contains(_activeTag)) {
        _activeTag = 'All';
      }
    });
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

// ── Shared: section label ─────────────────────────────────────────────────────

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
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.theme});
  final String label;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.textAccent.withValues(alpha: 0.12),
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
