import 'package:flutter/material.dart';
import '../data/journal_models.dart';
import '../data/journal_service.dart';
import '../theme/abide_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    required this.navVisible,
    required this.isActive,
    required this.onSwitchToScripture,
  });

  final ValueNotifier<bool> navVisible;
  final bool isActive;
  final VoidCallback onSwitchToScripture;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── List state ─────────────────────────────────────────────────────────────
  List<JournalEntry> _entries = [];
  bool _loading = true;

  // ── Editor state (persists across tab switches) ────────────────────────────
  bool _editing = false;
  final _bodyCtrl = TextEditingController();
  JournalEntryType _editType = JournalEntryType.spontaneous;
  String? _editId;
  DateTime? _editCreatedAt;
  JournalEntry? _editingEntry; // null = new entry

  // Optional scripture link
  String? _scriptureBook;
  int? _scriptureChapter;
  String? _scriptureVerseRange;
  String? _scriptureText;
  String? _scriptureTranslation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await JournalService.instance.getAll();
    if (mounted) setState(() { _entries = List.of(entries); _loading = false; });
  }

  // ── Open new entry ─────────────────────────────────────────────────────────
  void _openNew() {
    _editId = DateTime.now().microsecondsSinceEpoch.toString();
    _editCreatedAt = DateTime.now();
    _editType = JournalEntryType.spontaneous;
    _bodyCtrl.clear();
    _editingEntry = null;
    _clearScripture();
    setState(() => _editing = true);
  }

  // ── Open existing entry ────────────────────────────────────────────────────
  void _openExisting(JournalEntry e) {
    _editId = e.id;
    _editCreatedAt = e.createdAt;
    _editType = e.type;
    _bodyCtrl.text = e.body;
    _editingEntry = e;
    _scriptureBook = e.scriptureBook;
    _scriptureChapter = e.scriptureChapter;
    _scriptureVerseRange = e.scriptureVerseRange;
    _scriptureText = e.scriptureText;
    _scriptureTranslation = e.translation;
    setState(() => _editing = true);
  }

  void _clearScripture() {
    _scriptureBook = null;
    _scriptureChapter = null;
    _scriptureVerseRange = null;
    _scriptureText = null;
    _scriptureTranslation = null;
  }

  // ── Save & close editor ────────────────────────────────────────────────────
  Future<void> _closeEditor() async {
    await _saveCurrentEntry();
    setState(() => _editing = false);
    JournalService.instance.invalidateCache();
    await _load();
  }

  Future<void> _saveCurrentEntry() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty && _editingEntry == null) return;
    final entry = JournalEntry(
      id: _editId!,
      createdAt: _editCreatedAt!,
      updatedAt: DateTime.now(),
      body: body,
      type: _editType,
      scriptureBook: _scriptureBook,
      scriptureChapter: _scriptureChapter,
      scriptureVerseRange: _scriptureVerseRange,
      scriptureText: _scriptureText,
      translation: _scriptureTranslation,
    );
    if (_editingEntry == null) {
      if (body.isNotEmpty) await JournalService.instance.add(entry);
    } else {
      await JournalService.instance.update(entry);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteEntry() async {
    if (_editingEntry == null) {
      // New entry never saved — just close
      setState(() => _editing = false);
      return;
    }
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(theme: theme),
    );
    if (confirm == true && mounted) {
      await JournalService.instance.delete(_editId!);
      JournalService.instance.invalidateCache();
      await _load();
      if (mounted) setState(() => _editing = false);
    }
  }

  // ── Section grouping ───────────────────────────────────────────────────────
  List<_Section> _buildSections() {
    if (_entries.isEmpty) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final onThisDay = _entries.where((e) =>
        e.createdAt.month == now.month &&
        e.createdAt.day == now.day &&
        e.createdAt.year < now.year).toList();

    final byDay = <DateTime, List<JournalEntry>>{};
    for (final e in _entries) {
      if (onThisDay.contains(e)) continue;
      final day = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      (byDay[day] ??= []).add(e);
    }

    final sections = <_Section>[];
    if (onThisDay.isNotEmpty) {
      sections.add(_Section('On This Day', onThisDay, isOnThisDay: true));
    }
    final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final day in sortedDays) {
      String label;
      if (day == today) label = 'Today';
      else if (day == yesterday) label = 'Yesterday';
      else label = _dayLabel(day, now);
      sections.add(_Section(label, byDay[day]!));
    }
    return sections;
  }

  static String _dayLabel(DateTime d, DateTime now) {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    if (d.year != now.year) return '${months[d.month - 1]} ${d.day}, ${d.year}';
    return '${months[d.month - 1]} ${d.day}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Keep nav in sync whenever this screen rebuilds (tab switch or editing toggle)
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.navVisible.value = !_editing;
      });
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: child.key == const ValueKey('editor')
                ? const Offset(0.04, 0)
                : const Offset(-0.04, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _editing
          ? _EditorView(
              key: const ValueKey('editor'),
              bodyCtrl: _bodyCtrl,
              type: _editType,
              createdAt: _editCreatedAt ?? DateTime.now(),
              isNew: _editingEntry == null,
              scriptureBook: _scriptureBook,
              scriptureChapter: _scriptureChapter,
              scriptureVerseRange: _scriptureVerseRange,
              scriptureText: _scriptureText,
              onTypeChanged: (t) => setState(() => _editType = t),
              onBack: _closeEditor,
              onDelete: _deleteEntry,
              onClearScripture: () => setState(_clearScripture),
              onScripture: () {
                widget.navVisible.value = true;
                widget.onSwitchToScripture();
              },
            )
          : _ListView(
              key: const ValueKey('list'),
              entries: _entries,
              loading: _loading,
              sections: _buildSections(),
              onNew: _openNew,
              onOpen: _openExisting,
            ),
    );
  }
}

// ── Editor view (embedded, preserves state across tab switches) ───────────────

class _EditorView extends StatelessWidget {
  const _EditorView({
    super.key,
    required this.bodyCtrl,
    required this.type,
    required this.createdAt,
    required this.isNew,
    required this.scriptureBook,
    required this.scriptureChapter,
    required this.scriptureVerseRange,
    required this.scriptureText,
    required this.onTypeChanged,
    required this.onBack,
    required this.onDelete,
    required this.onClearScripture,
    required this.onScripture,
  });

  final TextEditingController bodyCtrl;
  final JournalEntryType type;
  final DateTime createdAt;
  final bool isNew;
  final String? scriptureBook;
  final int? scriptureChapter;
  final String? scriptureVerseRange;
  final String? scriptureText;
  final ValueChanged<JournalEntryType> onTypeChanged;
  final VoidCallback onBack;
  final VoidCallback onDelete;
  final VoidCallback onClearScripture;
  final VoidCallback onScripture;

  String? get _scriptureRef {
    if (scriptureBook == null) return null;
    if (scriptureChapter == null) return scriptureBook;
    if (scriptureVerseRange == null) return '$scriptureBook $scriptureChapter';
    return '$scriptureBook $scriptureChapter:$scriptureVerseRange';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final typeColor = Color(type.colorValue);

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(8, top > 0 ? 0 : 8, 8, 0),
              child: Row(
                children: [
                  const SizedBox(width: 44), // balance the Done button on the right
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmtDate(createdAt),
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary, letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          _fmtTime(createdAt),
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: theme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Done / save
                  _HdrBtn(icon: Icons.check_rounded, theme: theme, onTap: onBack, accent: typeColor),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Type selector ─────────────────────────────────────────────
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: JournalEntryType.values.map((t) {
                  final active = t == type;
                  final c = Color(t.colorValue);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onTypeChanged(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? c.withValues(alpha: 0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? c : theme.hairline,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? c : theme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Scripture card ────────────────────────────────────────────
            if (scriptureBook != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ScriptureCard(
                  ref: _scriptureRef!,
                  text: scriptureText,
                  typeColor: typeColor,
                  theme: theme,
                  onRemove: onClearScripture,
                ),
              ),
              const SizedBox(height: 12),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: theme.hairline, height: 1),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: TextField(
                controller: bodyCtrl,
                autofocus: isNew,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.verseStyle(fontSize: 17).copyWith(
                  color: theme.textPrimary, height: 1.7, letterSpacing: 0,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 72),
                  hintText: _hint(type),
                  hintStyle: TextStyle(
                    fontFamily: 'Inter', fontSize: 17,
                    color: theme.textMuted.withValues(alpha: 0.45), height: 1.7,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                cursorColor: typeColor,
                cursorWidth: 2,
              ),
            ),

            // ── Bottom toolbar ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 10),
              decoration: BoxDecoration(
                color: theme.bgApp,
                border: Border(top: BorderSide(color: theme.hairline, width: 1)),
              ),
              child: Row(
                children: [
                  // Delete
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded, size: 20, color: theme.textMuted),
                    ),
                  ),
                  const Spacer(),
                  // Scripture quick-jump
                  GestureDetector(
                    onTap: onScripture,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 16, color: theme.textMuted),
                          const SizedBox(width: 5),
                          Text(
                            'Scripture',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: theme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Word count
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: bodyCtrl,
                    builder: (_, val, __) {
                      final words = val.text.trim().isEmpty
                          ? 0
                          : val.text.trim().split(RegExp(r'\s+')).length;
                      return Text(
                        '$words ${words == 1 ? 'word' : 'words'}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: theme.textMuted),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hint(JournalEntryType t) => switch (t) {
        JournalEntryType.sundayService => 'Notes from today\'s service…',
        JournalEntryType.timeWithGod => 'What is God speaking to you?',
        JournalEntryType.reflection => 'Reflect on what you\'ve been reading…',
        JournalEntryType.spontaneous => 'Write freely…',
      };

  static String _fmtDate(DateTime dt) {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }
}

// ── List view ─────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  const _ListView({
    super.key,
    required this.entries,
    required this.loading,
    required this.sections,
    required this.onNew,
    required this.onOpen,
  });

  final List<JournalEntry> entries;
  final bool loading;
  final List<_Section> sections;
  final VoidCallback onNew;
  final ValueChanged<JournalEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    if (loading) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, top + 20, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journal',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary, letterSpacing: -0.8, height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entries.isEmpty
                            ? 'Your journey begins here'
                            : '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: theme.textMuted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onNew,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: theme.textAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(theme: theme, onTap: onNew),
          ),

        if (entries.isNotEmpty)
          SliverList(
            delegate: SliverChildListDelegate([
              for (final section in sections) ...[
                _SectionHeader(label: section.label, isOnThisDay: section.isOnThisDay, theme: theme),
                for (final entry in section.entries)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _EntryCard(entry: entry, theme: theme, onTap: () => onOpen(entry)),
                  ),
                const SizedBox(height: 8),
              ],
              SizedBox(height: bottom + 100),
            ]),
          ),
      ],
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Section {
  _Section(this.label, this.entries, {this.isOnThisDay = false});
  final String label;
  final List<JournalEntry> entries;
  final bool isOnThisDay;
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isOnThisDay, required this.theme});
  final String label;
  final bool isOnThisDay;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: Row(
          children: [
            if (isOnThisDay) ...[
              Icon(Icons.history_rounded, size: 13, color: theme.textAccent),
              const SizedBox(width: 5),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                color: isOnThisDay ? theme.textAccent : theme.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: theme.hairline, height: 1)),
          ],
        ),
      );
}

// ── Entry card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.theme, required this.onTap});
  final JournalEntry entry;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = Color(entry.type.colorValue);
    final h = entry.createdAt.hour;
    final hDisp = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final m = entry.createdAt.minute.toString().padLeft(2, '0');
    final time = '$hDisp:$m ${h < 12 ? 'AM' : 'PM'}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.bgMenu,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.hairline, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: typeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.type.label,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                              fontWeight: FontWeight.w600, color: typeColor, letterSpacing: 0.3)),
                          if (entry.hasScripture) ...[
                            const SizedBox(width: 6),
                            Container(width: 3, height: 3,
                              decoration: BoxDecoration(color: theme.textMuted.withValues(alpha: 0.4), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(entry.scriptureRef!,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: theme.textMuted)),
                          ],
                          const Spacer(),
                          Text(time,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                              color: theme.textMuted.withValues(alpha: 0.6))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(entry.title,
                        style: theme.verseStyle(fontSize: 15).copyWith(
                          color: theme.textPrimary, fontWeight: FontWeight.w600,
                          height: 1.3, letterSpacing: 0),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (entry.preview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(entry.preview,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                            color: theme.textMuted, height: 1.5),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Text('${entry.wordCount} ${entry.wordCount == 1 ? 'word' : 'words'}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                          color: theme.textMuted.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.onTap});
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded, size: 48, color: theme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Dialoguing with God',
            style: TextStyle(fontFamily: 'Inter', fontSize: 18,
              fontWeight: FontWeight.w600, color: theme.textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'A private space to pray, reflect, and record what God is speaking to you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: theme.textMuted, height: 1.6),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(color: theme.textAccent, borderRadius: BorderRadius.circular(24)),
              child: const Text('Write your first entry',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                  fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      );
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _HdrBtn extends StatelessWidget {
  const _HdrBtn({required this.icon, required this.theme, required this.onTap, this.accent});
  final IconData icon;
  final AbideThemeData theme;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(width: 44, height: 44,
          child: Center(child: Icon(icon, size: 20, color: accent ?? theme.textMuted))),
      );
}

class _ScriptureCard extends StatelessWidget {
  const _ScriptureCard({
    required this.ref, required this.text,
    required this.typeColor, required this.theme, required this.onRemove,
  });
  final String ref;
  final String? text;
  final Color typeColor;
  final AbideThemeData theme;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: typeColor, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ref,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                      fontWeight: FontWeight.w600, color: typeColor, letterSpacing: 0.3)),
                  if (text != null) ...[
                    const SizedBox(height: 3),
                    Text(text!,
                      style: theme.verseStyle(fontSize: 13).copyWith(
                        color: theme.textPrimary.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic, height: 1.5),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 14, color: theme.textMuted),
              ),
            ),
          ],
        ),
      );
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.theme});
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: theme.bgMenu,
        title: Text('Delete Entry',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: theme.textPrimary)),
        content: Text('This entry will be permanently deleted.',
          style: TextStyle(fontFamily: 'Inter', color: theme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted, fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
              style: TextStyle(color: Color(0xFFB83232), fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
