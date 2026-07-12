import 'dart:async';
import 'package:flutter/material.dart';
import '../data/dictionary_service.dart';
import '../data/search_models.dart';
import '../theme/abide_theme.dart';

// ── Main list screen ──────────────────────────────────────────────────────────

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  List<DictionaryEntry> _all = [];
  List<DictionaryEntry> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await DictionaryService.instance.getAll();
    if (mounted) {
      setState(() {
        _all = List.of(entries);
        _filtered = _all;
        _loading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((e) {
              final w = e.displayWord.toLowerCase();
              final def = (e.result.definition ?? e.result.answer ?? '').toLowerCase();
              return w.contains(q) || def.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(8, top + 8, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + search row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SizedBox(
                        width: 44, height: 44,
                        child: Center(child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.textMuted)),
                      ),
                    ),
                    const Spacer(),
                    if (_all.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() {
                          _searching = !_searching;
                          if (!_searching) _searchCtrl.clear();
                        }),
                        child: SizedBox(
                          width: 44, height: 44,
                          child: Center(child: Icon(
                            _searching ? Icons.close_rounded : Icons.search_rounded,
                            size: 22, color: theme.textMuted,
                          )),
                        ),
                      ),
                  ],
                ),

                // Title + count
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abide Dictionary',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                          letterSpacing: -0.8,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _loading
                            ? ''
                            : _all.isEmpty
                                ? 'Your word study collection'
                                : '${_all.length} ${_all.length == 1 ? 'entry' : 'entries'}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: theme.textMuted),
                      ),
                    ],
                  ),
                ),

                // Search bar
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _searching
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: theme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search words or definitions…',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: theme.textMuted.withValues(alpha: 0.5),
                              ),
                              filled: true,
                              fillColor: theme.surface.withValues(alpha: 0.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              prefixIcon: Icon(Icons.search_rounded, size: 18, color: theme.textMuted),
                            ),
                            cursorColor: theme.textAccent,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),
                Divider(color: theme.hairline, height: 1),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const SizedBox.shrink()
                : _all.isEmpty
                    ? _EmptyState(theme: theme)
                    : _filtered.isEmpty
                        ? _NoResults(theme: theme)
                        : ListView.separated(
                            padding: EdgeInsets.only(bottom: bottom + 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                Divider(color: theme.hairline, height: 1, indent: 24),
                            itemBuilder: (ctx, i) => _WordCard(
                              entry: _filtered[i],
                              theme: theme,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 320),
                                    pageBuilder: (_, __, ___) =>
                                        DictionaryDetailScreen(entry: _filtered[i]),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1, 0),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: anim,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        ),
                                  ),
                                );
                                DictionaryService.instance.invalidateCache();
                                _load();
                              },
                              onDelete: () async {
                                await DictionaryService.instance.delete(_filtered[i].id);
                                DictionaryService.instance.invalidateCache();
                                _load();
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Word list card ────────────────────────────────────────────────────────────

class _WordCard extends StatelessWidget {
  const _WordCard({required this.entry, required this.theme, required this.onTap, required this.onDelete});
  final DictionaryEntry entry;
  final AbideThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color get _typeColor => entry.result.type == SeekType.wordStudy
      ? const Color(0xFF7B8AC8)
      : const Color(0xFFC87BA0);

  @override
  Widget build(BuildContext context) {
    final ol = entry.result.originalLanguage;
    final isWord = entry.result.type == SeekType.wordStudy;
    final preview = isWord
        ? (entry.result.definition ?? '')
        : (entry.result.answer ?? '');

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left type strip
            Container(width: 3, color: _typeColor),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Language tag + Strong's
                              if (ol != null)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _typeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        ol.language.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: _typeColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (ol.strongs != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        ol.strongs!,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10,
                                          color: theme.textMuted.withValues(alpha: 0.5),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      _fmtDate(entry.savedAt),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        color: theme.textMuted.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _fmtDate(entry.savedAt),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      color: theme.textMuted.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 6),

                              // Word / question
                              Text(
                                entry.displayWord,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimary,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                              ),

                              // Original script + transliteration
                              if (ol != null && (ol.word.isNotEmpty || ol.transliteration != null))
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        if (ol.word.isNotEmpty)
                                          TextSpan(
                                            text: '${ol.word}  ',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: theme.textPrimary.withValues(alpha: 0.55),
                                              fontStyle: FontStyle.normal,
                                              height: 1.4,
                                            ),
                                          ),
                                        if (ol.transliteration != null)
                                          TextSpan(
                                            text: ol.transliteration,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: theme.textMuted.withValues(alpha: 0.55),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: theme.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.textMuted.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.bgMenu,
        title: Text('Remove entry',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: theme.textPrimary)),
        content: Text('Remove "${entry.displayWord}" from your dictionary?',
            style: TextStyle(fontFamily: 'Inter', color: theme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx, true); onDelete(); },
            child: const Text('Remove',
                style: TextStyle(fontFamily: 'Inter', color: Color(0xFFB83232), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ── Empty / no-results states ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✦',
                style: TextStyle(fontSize: 32, color: theme.textAccent.withValues(alpha: 0.25)),
              ),
              const SizedBox(height: 20),
              Text(
                'Your word collection',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Words and insights you save from Seek will appear here — Hebrew roots, Greek meanings, and answers to your deepest questions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: theme.textMuted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.theme});
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'No matches',
          style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: theme.textMuted),
        ),
      );
}

// ── Detail screen ─────────────────────────────────────────────────────────────

class DictionaryDetailScreen extends StatefulWidget {
  const DictionaryDetailScreen({super.key, required this.entry});
  final DictionaryEntry entry;

  @override
  State<DictionaryDetailScreen> createState() => _DictionaryDetailScreenState();
}

class _DictionaryDetailScreenState extends State<DictionaryDetailScreen> {
  late final TextEditingController _noteCtrl;
  Timer? _saveTimer;
  bool _noteSaved = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.entry.personalNote);
    _noteCtrl.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _noteCtrl.removeListener(_onNoteChanged);
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    setState(() => _noteSaved = false);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () async {
      await DictionaryService.instance.updateNote(widget.entry.id, _noteCtrl.text);
      if (mounted) setState(() => _noteSaved = true);
    });
  }

  Future<void> _delete() async {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.bgMenu,
        title: Text('Remove entry',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: theme.textPrimary)),
        content: Text('Remove "${widget.entry.displayWord}" from your dictionary?',
            style: TextStyle(fontFamily: 'Inter', color: theme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(fontFamily: 'Inter', color: Color(0xFFB83232), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await DictionaryService.instance.delete(widget.entry.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final r = widget.entry.result;
    final ol = r.originalLanguage;
    final isWord = r.type == SeekType.wordStudy;
    final typeColor = isWord ? const Color(0xFF7B8AC8) : const Color(0xFFC87BA0);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, top + 4, 8, 0),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                    theme: theme,
                  ),
                  const Spacer(),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    onTap: _delete,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          // ── Hero language block ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Word / question title
                  Text(
                    widget.entry.displayWord,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: theme.textPrimary,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),

                  if (ol != null) ...[
                    const SizedBox(height: 14),
                    // Original language block
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: typeColor.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ol.language.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: typeColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              if (ol.strongs != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  ol.strongs!,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: typeColor.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (ol.word.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              ol.word,
                              style: TextStyle(
                                fontSize: 36,
                                color: theme.textPrimary.withValues(alpha: 0.75),
                                height: 1.2,
                              ),
                            ),
                          ],
                          if (ol.transliteration != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              ol.transliteration!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: theme.textMuted,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                          if (ol.meaning != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              ol.meaning!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: typeColor.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Divider(color: theme.hairline, height: 32),
                ],
              ),
            ),
          ),

          // ── Body sections ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWord) ...[
                    if (r.definition != null)
                      _Section(
                        label: 'Definition',
                        theme: theme,
                        typeColor: typeColor,
                        child: Text(
                          r.definition!,
                          style: theme.verseStyle(fontSize: 16).copyWith(
                            color: theme.textPrimary,
                            height: 1.75,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    if (r.significance != null)
                      _Section(
                        label: 'Significance',
                        theme: theme,
                        typeColor: typeColor,
                        child: Text(
                          r.significance!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: theme.textPrimary.withValues(alpha: 0.85),
                            height: 1.7,
                          ),
                        ),
                      ),
                  ] else ...[
                    if (r.answer != null)
                      _Section(
                        label: 'Answer',
                        theme: theme,
                        typeColor: typeColor,
                        child: Text(
                          r.answer!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: theme.textPrimary.withValues(alpha: 0.85),
                            height: 1.7,
                          ),
                        ),
                      ),
                    if (r.exegesis != null && r.exegesis!.isNotEmpty)
                      _Section(
                        label: 'Exegesis',
                        theme: theme,
                        typeColor: typeColor,
                        child: Column(
                          children: r.exegesis!
                              .map((e) => _ExegesisBlock(e: e, theme: theme, typeColor: typeColor))
                              .toList(),
                        ),
                      ),
                    if (r.pastoralCaution != null)
                      _CautionBlock(text: r.pastoralCaution!, theme: theme),
                  ],

                  // Key verses
                  if (r.verses.isNotEmpty)
                    _Section(
                      label: 'Key Verses',
                      theme: theme,
                      typeColor: typeColor,
                      child: Column(
                        children: r.verses
                            .map((v) => _VerseBlock(v: v, theme: theme, typeColor: typeColor))
                            .toList(),
                      ),
                    ),

                  // Reflection
                  if (r.reflection != null)
                    _Section(
                      label: 'Reflection',
                      theme: theme,
                      typeColor: typeColor,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: typeColor, width: 3)),
                        ),
                        child: Text(
                          r.reflection!,
                          style: theme.verseStyle(fontSize: 15).copyWith(
                            color: theme.textPrimary.withValues(alpha: 0.85),
                            height: 1.7,
                            letterSpacing: 0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                  // Personal note
                  _Section(
                    label: 'Personal Note',
                    theme: theme,
                    typeColor: typeColor,
                    trailing: AnimatedOpacity(
                      opacity: _noteSaved ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        'Saved',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: typeColor.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    child: TextField(
                      controller: _noteCtrl,
                      maxLines: null,
                      minLines: 3,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: theme.textPrimary,
                        height: 1.65,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your personal reflection or insight…',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: theme.textMuted.withValues(alpha: 0.4),
                          height: 1.65,
                        ),
                        filled: true,
                        fillColor: theme.surface.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      ),
                      cursorColor: typeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section wrapper ──────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.theme,
    required this.typeColor,
    required this.child,
    this.trailing,
  });
  final String label;
  final AbideThemeData theme;
  final Color typeColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: typeColor.withValues(alpha: 0.65),
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

// ── Verse blockquote ──────────────────────────────────────────────────────────

class _VerseBlock extends StatelessWidget {
  const _VerseBlock({required this.v, required this.theme, required this.typeColor});
  final SeekVerse v;
  final AbideThemeData theme;
  final Color typeColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: typeColor.withValues(alpha: 0.5), width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.ref,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: typeColor.withValues(alpha: 0.8),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                v.text,
                style: theme.verseStyle(fontSize: 15).copyWith(
                  color: theme.textPrimary.withValues(alpha: 0.88),
                  height: 1.7,
                  letterSpacing: 0,
                ),
              ),
              if (v.note != null) ...[
                const SizedBox(height: 8),
                Text(
                  v.note!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: theme.textMuted,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

// ── Exegesis block ────────────────────────────────────────────────────────────

class _ExegesisBlock extends StatelessWidget {
  const _ExegesisBlock({required this.e, required this.theme, required this.typeColor});
  final SeekExegesis e;
  final AbideThemeData theme;
  final Color typeColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.passage,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: typeColor.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              e.explanation,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: theme.textPrimary.withValues(alpha: 0.8),
                height: 1.65,
              ),
            ),
            if (e.keyInsight != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✦ ', style: TextStyle(fontSize: 10, color: typeColor.withValues(alpha: 0.6))),
                  Expanded(
                    child: Text(
                      e.keyInsight!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: typeColor.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                        height: 1.55,
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

// ── Pastoral caution ──────────────────────────────────────────────────────────

class _CautionBlock extends StatelessWidget {
  const _CautionBlock({required this.text, required this.theme});
  final String text;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFD4A843).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4A843).withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: theme.textPrimary.withValues(alpha: 0.75),
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, required this.theme});
  final IconData icon;
  final VoidCallback onTap;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Icon(icon, size: 18, color: theme.textMuted)),
        ),
      );
}
