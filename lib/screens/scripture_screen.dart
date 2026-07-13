import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/bible_service.dart';
import '../data/highlights_service.dart';
import '../data/search_models.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/chapter_footer.dart';
import '../widgets/highlight_panel.dart';
import '../widgets/verse_share_sheet.dart';
import 'bible_navigator_screen.dart';

// ── Bookmark model ────────────────────────────────────────────────────────────

class _Bookmark {
  const _Bookmark(this.book, this.chapter);
  final String book;
  final int chapter;

  String toPrefs() => '$book:$chapter';
  static _Bookmark fromPrefs(String s) {
    final i = s.lastIndexOf(':');
    return _Bookmark(s.substring(0, i), int.parse(s.substring(i + 1)));
  }
}

const _kMaxBookmarks = 5;
const _kStripH = 46.0;

const _kChapterCounts = <String, int>{
  'Genesis': 50, 'Exodus': 40, 'Leviticus': 27, 'Numbers': 36,
  'Deuteronomy': 34, 'Joshua': 24, 'Judges': 21, 'Ruth': 4,
  '1 Samuel': 31, '2 Samuel': 24, '1 Kings': 22, '2 Kings': 25,
  '1 Chronicles': 29, '2 Chronicles': 36, 'Ezra': 10, 'Nehemiah': 13,
  'Esther': 10, 'Job': 42, 'Psalms': 150, 'Proverbs': 31,
  'Ecclesiastes': 12, 'Song of Solomon': 8, 'Isaiah': 66, 'Jeremiah': 52,
  'Lamentations': 5, 'Ezekiel': 48, 'Daniel': 12, 'Hosea': 14,
  'Joel': 3, 'Amos': 9, 'Obadiah': 1, 'Jonah': 4, 'Micah': 7,
  'Nahum': 3, 'Habakkuk': 3, 'Zephaniah': 3, 'Haggai': 2,
  'Zechariah': 14, 'Malachi': 4, 'Matthew': 28, 'Mark': 16,
  'Luke': 24, 'John': 21, 'Acts': 28, 'Romans': 16,
  '1 Corinthians': 16, '2 Corinthians': 13, 'Galatians': 6,
  'Ephesians': 6, 'Philippians': 4, 'Colossians': 4,
  '1 Thessalonians': 5, '2 Thessalonians': 3, '1 Timothy': 6,
  '2 Timothy': 4, 'Titus': 3, 'Philemon': 1, 'Hebrews': 13,
  'James': 5, '1 Peter': 5, '2 Peter': 3, '1 John': 5,
  '2 John': 1, '3 John': 1, 'Jude': 1, 'Revelation': 22,
};

String _abbrev(String book) {
  const m = {
    'Genesis': 'Gen', 'Exodus': 'Ex', 'Leviticus': 'Lev', 'Numbers': 'Num',
    'Deuteronomy': 'Deut', 'Joshua': 'Josh', 'Judges': 'Judg',
    '1 Samuel': '1 Sam', '2 Samuel': '2 Sam', '1 Kings': '1 Kgs', '2 Kings': '2 Kgs',
    '1 Chronicles': '1 Chr', '2 Chronicles': '2 Chr', 'Nehemiah': 'Neh',
    'Psalms': 'Ps', 'Proverbs': 'Prov', 'Ecclesiastes': 'Ecc',
    'Song of Solomon': 'Song', 'Isaiah': 'Isa', 'Jeremiah': 'Jer',
    'Lamentations': 'Lam', 'Ezekiel': 'Ezek', 'Daniel': 'Dan',
    'Habakkuk': 'Hab', 'Zephaniah': 'Zeph', 'Zechariah': 'Zech', 'Malachi': 'Mal',
    'Matthew': 'Matt', 'Mark': 'Mk', 'Luke': 'Lk', 'John': 'Jn',
    'Romans': 'Rom', '1 Corinthians': '1 Cor', '2 Corinthians': '2 Cor',
    'Galatians': 'Gal', 'Ephesians': 'Eph', 'Philippians': 'Phil', 'Colossians': 'Col',
    '1 Thessalonians': '1 Th', '2 Thessalonians': '2 Th',
    '1 Timothy': '1 Tim', '2 Timothy': '2 Tim',
    'Philemon': 'Phm', 'Hebrews': 'Heb', 'James': 'Jas',
    '1 Peter': '1 Pet', '2 Peter': '2 Pet',
    '1 John': '1 Jn', '2 John': '2 Jn', '3 John': '3 Jn',
    'Revelation': 'Rev',
  };
  return m[book] ?? book;
}

class ScriptureScreen extends StatefulWidget {
  const ScriptureScreen({
    super.key,
    this.initialBook = 'John',
    this.initialChapter = 3,
    this.initialTranslation = 'asr',
    this.showNav = true,
    this.navVisible,
    this.textScale = 1.0,
    this.chapterlessMode = false,
    this.skipSavedPosition = false,
  });

  final String initialBook;
  final int initialChapter;
  final String initialTranslation;
  final bool showNav;
  final ValueNotifier<bool>? navVisible;
  final double textScale;
  final bool chapterlessMode;
  final bool skipSavedPosition;

  @override
  State<ScriptureScreen> createState() => _ScriptureScreenState();
}

class _ScriptureScreenState extends State<ScriptureScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _bottomNavVisible = ValueNotifier<bool>(true);

  double _lastScrollY = 0;
  List<_Bookmark> _bookmarks = [];

  late String _book;
  late int _chapter;
  late String _translation;

  BibleChapter? _chapterData;
  bool _loading = true;
  String? _error;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeIn;

  // ── Highlighting ─────────────────────────────────────────────────────────
  final Set<int> _selectedVerses = {};
  Map<int, Highlight> _chapterHighlights = {};
  final _versesKey = GlobalKey();

  // ── Swipe tracking (raw pointer — direction-locked, works on Windows + mobile)
  Offset? _pointerDownPos;
  String? _swipeDirLocked; // 'h' = horizontal, 'v' = vertical


  @override
  void initState() {
    super.initState();
    _book = widget.initialBook;
    _chapter = widget.initialChapter;
    _translation = widget.initialTranslation;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _scrollController.addListener(_onScroll);
    _loadSavedPosition();
  }

  Future<void> _loadSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBook = prefs.getString('lastBook');
    final savedChapter = prefs.getInt('lastChapter');
    final bmRaw = prefs.getStringList('bookmarks') ?? [];
    if (!mounted) return;
    setState(() {
      if (!widget.skipSavedPosition && savedBook != null && savedChapter != null) {
        _book = savedBook;
        _chapter = savedChapter;
      }
      _bookmarks = bmRaw.map(_Bookmark.fromPrefs).toList();
      _translation = prefs.getString('translation') ?? _translation;
    });
    _loadChapter();
  }

  bool get _isCurrentBookmarked =>
      _bookmarks.any((b) => b.book == _book && b.chapter == _chapter);

  Future<void> _toggleBookmark() async {
    final alreadyIn = _isCurrentBookmarked;
    setState(() {
      if (alreadyIn) {
        _bookmarks.removeWhere((b) => b.book == _book && b.chapter == _chapter);
      } else if (_bookmarks.length < _kMaxBookmarks) {
        _bookmarks.add(_Bookmark(_book, _chapter));
      }
    });
    if (!alreadyIn) HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('bookmarks', _bookmarks.map((b) => b.toPrefs()).toList());
  }

  Future<void> _loadChapter() async {
    setState(() { _loading = true; _error = null; _selectedVerses.clear(); });
    try {
      final data = await BibleService.instance.loadChapter(
        _translation, _book, _chapter,
      );
      if (mounted) {
        setState(() { _chapterData = data; _loading = false; });
        _loadHighlights();
        _entranceCtrl.forward(from: 0);
        _scrollController.jumpTo(0);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _navigateTo(String book, int chapter) async {
    setState(() {
      _book = book;
      _chapter = chapter;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('lastBook', book);
    prefs.setInt('lastChapter', chapter);
    _loadChapter();
  }

  void _onScroll() {
    final y = _scrollController.offset;
    final delta = y - _lastScrollY;
    _lastScrollY = y;
    // Use the shell's notifier when embedded as a tab, else own internal one
    final notifier = widget.navVisible ?? _bottomNavVisible;
    if (y < 10) {
      notifier.value = true;
    } else if (delta > 8) {
      notifier.value = false;
    } else if (delta < -8) {
      notifier.value = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bottomNavVisible.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    final all = await HighlightsService.instance.getForChapter(_book, _chapter);
    if (!mounted) return;
    final map = <int, Highlight>{};
    for (final h in all) {
      if (h.translation.toLowerCase() == _translation.toLowerCase()) {
        map[h.verse] = h;
      }
    }
    setState(() => _chapterHighlights = map);
  }

  void _handleVerseTap(int verseNum) {
    setState(() {
      if (_selectedVerses.contains(verseNum)) {
        _selectedVerses.remove(verseNum);
      } else {
        _selectedVerses.add(verseNum);
      }
    });
  }

  Future<void> _applyHighlight(String colorId) async {
    final verseList = _selectedVerses.toList()..sort();
    // All verses in the selection share one groupId (keyed to the min verse)
    final groupId = '${_book}_${_chapter}_${verseList.first}_$_translation';
    final now = DateTime.now();

    for (final verseNum in verseList) {
      final existing = _chapterHighlights[verseNum];
      if (existing != null) {
        // Recolor existing highlight (preserve tags, adopt new shared groupId)
        await HighlightsService.instance.updateByVerse(
          existing.copyWith(colorId: colorId, groupId: groupId),
        );
      } else {
        BibleVerse? verseObj;
        try {
          verseObj = _chapterData!.verses.firstWhere((v) => v.number == verseNum);
        } catch (_) {}
        await HighlightsService.instance.add(Highlight(
          groupId: groupId,
          book: _book,
          chapter: _chapter,
          verse: verseNum,
          translation: _translation.toUpperCase(),
          text: verseObj?.text ?? '',
          colorId: colorId,
          tags: [],
          createdAt: now,
        ));
      }
    }
    if (mounted) {
      HapticFeedback.mediumImpact();
      await _loadHighlights();
      setState(() => _selectedVerses.clear());
    }
  }

  Future<void> _removeHighlights() async {
    final verseList = _selectedVerses.toList();
    for (final verseNum in verseList) {
      final h = _chapterHighlights[verseNum];
      if (h != null) await HighlightsService.instance.remove(h.groupId);
    }
    if (mounted) {
      await _loadHighlights();
      setState(() => _selectedVerses.clear());
    }
  }

  Future<void> _addTag(BuildContext ctx) async {
    final ctrl = TextEditingController();
    final tag = await showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Theme.of(dCtx).extension<AbideThemeData>()!.bgMenu,
        title: Text('Add tag',
            style: TextStyle(
                color: Theme.of(dCtx).extension<AbideThemeData>()!.textPrimary,
                fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(
              color: Theme.of(dCtx).extension<AbideThemeData>()!.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. faith, conviction…',
            hintStyle: TextStyle(
                color: Theme.of(dCtx).extension<AbideThemeData>()!.textMuted),
          ),
          onSubmitted: (v) => Navigator.pop(dCtx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (tag == null || tag.isEmpty || !mounted) return;
    for (final verseNum in _selectedVerses) {
      final h = _chapterHighlights[verseNum];
      if (h == null || h.tags.contains(tag)) continue;
      await HighlightsService.instance.update(h.copyWith(tags: [...h.tags, tag]));
    }
    if (mounted) await _loadHighlights();
  }

  void _openShareSheet(BuildContext ctx) {
    final verseList = _selectedVerses.toList()..sort();
    final verseTexts = verseList.map((vNum) {
      try {
        return _chapterData!.verses.firstWhere((v) => v.number == vNum).text;
      } catch (_) {
        return '';
      }
    }).where((t) => t.isNotEmpty).toList();

    if (verseTexts.isEmpty) return;

    final theme = Theme.of(ctx).extension<AbideThemeData>()!;
    final sorted = verseList;
    final verseRange = sorted.length == 1
        ? '${sorted.first}'
        : '${sorted.first}–${sorted.last}';
    final refStr = '$_book $_chapter:$verseRange';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VerseShareSheet(
        verseTexts: verseTexts,
        ref: refStr,
        translation: _translation,
        theme: theme,
      ),
    );
  }

  void _swipeChapter(int delta) {
    final max = _kChapterCounts[_book] ?? 150;
    final next = _chapter + delta;
    if (next < 1 || next > max) return;
    _navigateTo(_book, next);
  }

  void _openTranslationPicker(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (_) => _TranslationSheet(
        current: _translation,
        theme: theme,
        onSelect: (t) {
          setState(() => _translation = t);
          _loadChapter();
          SharedPreferences.getInstance()
              .then((p) => p.setString('translation', t));
        },
      ),
    );
  }

  void _openNavigator(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => BibleNavigatorScreen(
          currentBook: _book,
          currentChapter: _chapter,
          onSelect: (book, chapter) => _navigateTo(book, chapter),
        ),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: AtmosphericBackground(
        baseColor: theme.bgApp,
        accentColor: theme.textAccent,
        child: Stack(
          children: [
            Listener(
              onPointerDown: (e) {
                _pointerDownPos = e.localPosition;
                _swipeDirLocked = null;
              },
              onPointerMove: (e) {
                if (_pointerDownPos == null || _swipeDirLocked != null) return;
                final dx = (e.localPosition.dx - _pointerDownPos!.dx).abs();
                final dy = (e.localPosition.dy - _pointerDownPos!.dy).abs();
                // Lock direction once 8 px threshold crossed (matches PWA logic)
                if (dx > 8) {
                  _swipeDirLocked = 'h';
                } else if (dy > 8) {
                  _swipeDirLocked = 'v';
                }
              },
              onPointerCancel: (_) {
                _pointerDownPos = null;
                _swipeDirLocked = null;
              },
              onPointerUp: (e) {
                final start = _pointerDownPos;
                final dir = _swipeDirLocked;
                _pointerDownPos = null;
                _swipeDirLocked = null;
                // Only navigate when gesture was locked to horizontal
                if (start == null || dir != 'h') return;
                final dx = e.localPosition.dx - start.dx;
                if (dx.abs() < 60) return;
                _swipeChapter(dx < 0 ? 1 : -1);
              },
              child: FadeTransition(
              opacity: _fadeIn,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ScriptureHeaderDelegate(
                      topPad: topPad,
                      theme: theme,
                      book: _book,
                      chapter: _chapter,
                      translation: _translation.toUpperCase(),
                      isBookmarked: _isCurrentBookmarked,
                      bookmarks: _bookmarks,
                      chapterlessMode: widget.chapterlessMode,
                      onBookmark: _toggleBookmark,
                      onBack: () => Navigator.of(context).pop(),
                      onNavigate: () => _openNavigator(context),
                      onTranslationTap: () => _openTranslationPicker(context),
                      onBookmarkTap: (bm) => _navigateTo(bm.book, bm.chapter),
                    ),
                  ),
                  if (_loading)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.textAccent.withValues(alpha: 0.5),
                          strokeWidth: 1.5,
                        ),
                      ),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Could not load chapter',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          widget.chapterlessMode ? theme.chapterlessPadding : 28,
                          widget.chapterlessMode ? 24 : 32,
                          widget.chapterlessMode ? theme.chapterlessPadding : 28,
                          0,
                        ),
                        child: _buildVerses(theme),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: ChapterFooter(
                          book: _book,
                          chapter: _chapter,
                          translation: _translation,
                          onNavigate: _navigateTo,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ), // GestureDetector

            // Floating highlight panel
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              bottom: _selectedVerses.isNotEmpty ? 82.0 : -100.0,
              left: 16,
              right: 16,
              child: HighlightPanel(
                selectedVerses: _selectedVerses,
                chapterHighlights: _chapterHighlights,
                onColorPick: (colorId) => _applyHighlight(colorId),
                onRemove: () => _removeHighlights(),
                onDismiss: () => setState(() => _selectedVerses.clear()),
                onShare: () => _openShareSheet(context),
                theme: theme,
                book: _book,
                chapter: _chapter,
              ),
            ),

            if (widget.showNav)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _bottomNavVisible,
                  builder: (ctx, visible, _) => AbideBottomNav(
                    current: NavTab.scripture,
                    visible: visible,
                    onTap: (tab) {
                      if (tab == NavTab.home) Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerses(AbideThemeData theme) {
    if (_chapterData == null) return const SizedBox.shrink();

    final verses = _chapterData!.verses;

    if (widget.chapterlessMode) {
      // ── Chapterless: Lora prose, no verse numbers, em-space paragraph indent
      final clSize = theme.chapterlessFontSize * widget.textScale;
      final clStyle = theme.chapterlessStyle(fontSize: clSize);
      final clChristStyle = clStyle.copyWith(color: theme.christAccent);

      final spans = <InlineSpan>[];
      // First-line paragraph indent via em spaces
      spans.add(TextSpan(text: '  ', style: clStyle));

      for (int i = 0; i < verses.length; i++) {
        final verse = verses[i];
        for (final segment in verse.segments) {
          spans.add(TextSpan(
            text: segment.text,
            style: segment.isJesus ? clChristStyle : clStyle,
          ));
        }
        if (i < verses.length - 1) {
          spans.add(TextSpan(text: ' ', style: clStyle));
        }
      }

      return Text.rich(TextSpan(children: spans));
    }

    // ── Standard verse mode ─────────────────────────────────────────────────
    // Verses flow inline in a single Text.rich. A CustomPainter behind the text
    // uses TextPainter.getBoxesForSelection to paint highlight rects that span
    // the full line height (including leading) — this covers the badge area too.
    final scaledSize = theme.verseFontSize * widget.textScale;
    final verseStyle = theme.verseStyle(fontSize: scaledSize);
    final christStyle = theme.christStyle(fontSize: scaledSize);
    final numStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: (scaledSize * 0.50).clamp(9.0, 13.0),
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1,
    );

    final spans = <InlineSpan>[];
    final highlights = <_VerseHighlight>[];
    final verseRanges = <({int start, int end, int verseNum})>[];
    int offset = 0;

    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];

      final isSelected = _selectedVerses.contains(verse.number);
      final existingHighlight = _chapterHighlights[verse.number];
      Color? bg;
      if (isSelected) {
        bg = theme.textAccent.withValues(alpha: 0.20);
      } else if (existingHighlight != null) {
        bg = resolveHighlightBg(existingHighlight.colorId);
      }

      final verseStart = offset;

      // Badge — WidgetSpan counts as 1 placeholder character in the text.
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => _handleVerseTap(verse.number),
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: theme.textAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${verse.number}', style: numStyle),
            ),
          ),
        ),
      ));
      offset += 1;

      for (final segment in verse.segments) {
        spans.add(TextSpan(
          text: segment.text,
          style: segment.isJesus ? christStyle : verseStyle,
        ));
        offset += segment.text.length;
      }

      if (i < verses.length - 1) {
        spans.add(TextSpan(text: ' ', style: verseStyle));
        offset += 1;
      }

      verseRanges.add((start: verseStart, end: offset, verseNum: verse.number));

      if (bg != null) {
        highlights.add(_VerseHighlight(verseStart, offset, bg));
      }
    }

    final fullSpan = TextSpan(children: spans);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) {
        final para = _versesKey.currentContext?.findRenderObject() as RenderParagraph?;
        if (para == null) return;
        final localPos = para.globalToLocal(details.globalPosition);
        final charOffset = para.getPositionForOffset(localPos).offset;
        for (final r in verseRanges) {
          if (charOffset > r.start && charOffset <= r.end) {
            _handleVerseTap(r.verseNum);
            break;
          }
        }
      },
      child: CustomPaint(
        painter: _HighlightPainter(textKey: _versesKey, highlights: highlights),
        child: Text.rich(fullSpan, key: _versesKey),
      ),
    );
  }
}

// ── Verse highlight painting ──────────────────────────────────────────────────

class _VerseHighlight {
  const _VerseHighlight(this.start, this.end, this.color);
  final int start;
  final int end;
  final Color color;
}

// Paints highlight rects behind Text.rich by querying the already-laid-out
// RenderParagraph via GlobalKey. This avoids the WidgetSpan dimensions issue
// that occurs when building a fresh TextPainter. BoxHeightStyle.max fills the
// full line height (including leading) so colour covers badge and text evenly.
class _HighlightPainter extends CustomPainter {
  _HighlightPainter({required this.textKey, required this.highlights});
  final GlobalKey textKey;
  final List<_VerseHighlight> highlights;

  @override
  void paint(Canvas canvas, Size size) {
    if (highlights.isEmpty) return;
    final ro = textKey.currentContext?.findRenderObject();
    if (ro is! RenderParagraph) return;
    for (final h in highlights) {
      final boxes = ro.getBoxesForSelection(
        TextSelection(baseOffset: h.start, extentOffset: h.end),
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      final paint = Paint()..color = h.color;
      for (final box in boxes) {
        canvas.drawRect(box.toRect(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.highlights != highlights;
}

// ── Morphing header delegate ──────────────────────────────────────────────────

class _ScriptureHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ScriptureHeaderDelegate({
    required this.topPad,
    required this.theme,
    required this.book,
    required this.chapter,
    required this.translation,
    required this.isBookmarked,
    required this.bookmarks,
    required this.chapterlessMode,
    required this.onBookmark,
    required this.onBack,
    required this.onNavigate,
    required this.onTranslationTap,
    required this.onBookmarkTap,
  });

  final double topPad;
  final AbideThemeData theme;
  final String book;
  final int chapter;
  final String translation;
  final bool isBookmarked;
  final List<_Bookmark> bookmarks;
  final bool chapterlessMode;
  final VoidCallback onBookmark;
  final VoidCallback onBack;
  final VoidCallback onNavigate;
  final VoidCallback onTranslationTap;
  final ValueChanged<_Bookmark> onBookmarkTap;

  bool get _hasStrip => bookmarks.isNotEmpty;
  double get _stripH => _hasStrip ? _kStripH : 0;

  @override
  double get maxExtent => topPad + (chapterlessMode ? 180 : 152) + _stripH;

  @override
  double get minExtent => topPad + 56 + _stripH;

  double get _range => maxExtent - minExtent;

  String get _bookLabel => book.toUpperCase().split('').join(' ');

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = Curves.easeInOut
        .transform((shrinkOffset / _range).clamp(0.0, 1.0));

    final expandedOpacity =
        Curves.easeIn.transform(((1 - t / 0.55)).clamp(0.0, 1.0));
    final compactOpacity =
        Curves.easeOut.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0));

    return Container(
      color: theme.bgApp.withValues(alpha: Curves.easeIn.transform(t) * 0.97),
      child: Stack(
        children: [
          // ── Utility icons — always top-right ─────────────────────────
          Positioned(
            top: topPad + 10,
            right: 16,
            child: Row(
              children: [
                _Square(
                  active: isBookmarked,
                  activeColor: theme.textAccent,
                  onTap: onBookmark,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isBookmarked
                        ? Icon(Icons.bookmark_rounded,
                            key: const ValueKey('on'),
                            size: 17, color: theme.textAccent)
                        : Icon(Icons.bookmark_border_rounded,
                            key: const ValueKey('off'),
                            size: 17,
                            color: theme.mutedIcon),
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded heading ─────────────────────────────────────────
          if (expandedOpacity > 0.01)
            Positioned(
              left: 0, right: 0, bottom: _stripH,
              child: Opacity(
                opacity: expandedOpacity,
                child: Transform.translate(
                  offset: Offset(0, -(shrinkOffset * 0.25)),
                  child: chapterlessMode
                      ? _buildChapterlessHeading()
                      : _buildStandardHeading(),
                ),
              ),
            ),

          // ── Compact: nav row ──────────────────────────────────────────
          if (compactOpacity > 0.01)
            Positioned(
              left: 0, right: 0, bottom: _stripH,
              child: Opacity(
                opacity: compactOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 100, 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onNavigate,
                        child: _Pill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book_outlined,
                                  size: 14, color: theme.textAccent),
                              const SizedBox(width: 8),
                              Text(
                                '$book  ·  $chapter',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: theme.mutedIcon),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onTranslationTap,
                        child: _Pill(
                          child: Text(
                            translation,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bookmark strip — always pinned at bottom ───────────────────
          if (_hasStrip)
            Positioned(
              left: 0, right: 0, bottom: 0, height: _kStripH,
              child: _buildBookmarkStrip(),
            ),
        ],
      ),
    );
  }

  Widget _buildBookmarkStrip() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.hairline, width: 1),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: bookmarks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final bm = bookmarks[i];
          final isActive = bm.book == book && bm.chapter == chapter;
          return GestureDetector(
            onTap: () => onBookmarkTap(bm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.textAccent.withValues(alpha: 0.16)
                    : theme.subtleFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? theme.textAccent.withValues(alpha: 0.45)
                      : theme.subtleOutline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 10,
                    color: isActive
                        ? theme.textAccent
                        : theme.textPrimary.withValues(alpha: 0.28),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_abbrev(bm.book)} ${bm.chapter}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? theme.textAccent
                          : theme.textPrimary.withValues(alpha: 0.60),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStandardHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 80, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _bookLabel,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: theme.textAccent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chapter $chapter',
            style: theme.bodyFont(46).copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
              color: theme.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 36, height: 1.5,
            color: theme.textAccent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterlessHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            book.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
              color: theme.textAccent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$chapter',
            textAlign: TextAlign.center,
            style: theme.chapterlessFont(80).copyWith(
              color: theme.textAccent.withValues(alpha: 0.88),
              height: 1,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 40, height: 1,
            color: theme.textAccent.withValues(alpha: 0.20),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ScriptureHeaderDelegate old) =>
      old.isBookmarked != isBookmarked ||
      old.book != book ||
      old.chapter != chapter ||
      old.translation != translation ||
      old.topPad != topPad ||
      old.chapterlessMode != chapterlessMode ||
      old.bookmarks.length != bookmarks.length ||
      old.theme.textAccent != theme.textAccent ||
      old.theme.bgApp != theme.bgApp;
}

// ── Primitives ────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AbideThemeData>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.subtleFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.subtleOutline, width: 1),
      ),
      child: child,
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.child,
    this.onTap,
    this.active = false,
    this.activeColor,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AbideThemeData>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? (activeColor?.withValues(alpha: 0.14) ?? t.subtleFill)
              : t.subtleFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? (activeColor?.withValues(alpha: 0.32) ?? t.subtleOutline)
                : t.subtleOutline,
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Translation picker bottom sheet ──────────────────────────────────────────

const _translations = [
  (
    key: 'asr',
    abbr: 'ASR',
    name: 'ABIDE Source Reading',
    desc: 'Modern English — derived from the BSB with red-letter Christ passages',
  ),
  (
    key: 'kjv',
    abbr: 'KJV',
    name: 'King James Version',
    desc: 'Classic 1769 edition — the enduring standard of English scripture',
  ),
  (
    key: 'wae',
    abbr: 'WAE',
    name: "Webster's American Edition",
    desc: "Noah Webster's 1833 modernization of the KJV",
  ),
];

class _TranslationSheet extends StatelessWidget {
  const _TranslationSheet({
    required this.current,
    required this.theme,
    required this.onSelect,
  });

  final String current;
  final AbideThemeData theme;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.bgApp,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: theme.subtleOutline, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: theme.mutedIcon,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'TRANSLATION',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: theme.textAccent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          for (final t in _translations) ...[
            _TranslationTile(
              translationKey: t.key,
              abbr: t.abbr,
              name: t.name,
              desc: t.desc,
              isActive: t.key == current,
              theme: theme,
              onTap: () {
                onSelect(t.key);
                Navigator.of(context).pop();
              },
            ),
            if (t.key != _translations.last.key) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TranslationTile extends StatelessWidget {
  const _TranslationTile({
    required this.translationKey,
    required this.abbr,
    required this.name,
    required this.desc,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  final String translationKey;
  final String abbr;
  final String name;
  final String desc;
  final bool isActive;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? theme.textAccent.withValues(alpha: 0.08)
              : theme.subtleFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? theme.textAccent.withValues(alpha: 0.28)
                : theme.subtleOutline,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Abbreviation badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.textAccent.withValues(alpha: 0.12)
                    : theme.subtleFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  abbr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color:
                        isActive ? theme.textAccent : theme.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isActive ? theme.textPrimary : theme.textPrimary.withValues(alpha: 0.8),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Active indicator
            if (isActive)
              Icon(Icons.check_rounded, color: theme.textAccent, size: 18)
            else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}
