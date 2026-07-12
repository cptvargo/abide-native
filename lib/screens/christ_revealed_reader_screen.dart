import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/christ_revealed_models.dart';
import '../services/christ_revealed_service.dart';

class ChristRevealedReaderScreen extends StatefulWidget {
  const ChristRevealedReaderScreen({
    super.key,
    required this.bookData,
    required this.startChapter,
  });

  final CRBook bookData;
  final int startChapter;

  @override
  State<ChristRevealedReaderScreen> createState() =>
      _ChristRevealedReaderScreenState();
}

class _ChristRevealedReaderScreenState
    extends State<ChristRevealedReaderScreen> with TickerProviderStateMixin {
  late int _chapter;
  late final ScrollController _scrollCtrl;
  late final AnimationController _headerCtrl;
  late final AnimationController _revealCtrl;

  List<({int verse, String text})> _verses = [];
  Map<int, List<({CRObservation obs, bool isChrist, String eventTitle})>>
      _triggerMap = {};
  CRChapterSummary? _chapterSummary;
  List<CRCrossRef> _crossRefs = [];
  Set<String> _seenReveals = {};
  final Map<int, GlobalKey> _triggerKeys = {};
  bool _loading = true;
  bool _showSummary = false;

  // Current reveal state
  ({CRObservation obs, bool isChrist, String eventTitle})? _pendingReveal;

  @override
  void initState() {
    super.initState();
    _chapter = widget.startChapter;
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _loadChapter();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _headerCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChapter() async {
    setState(() {
      _loading = true;
      _verses = [];
      _triggerKeys.clear();
      _showSummary = false;
    });

    final svc = ChristRevealedService.instance;

    // Load verse data and seen reveals concurrently
    final results = await Future.wait([
      _loadVerses(),
      svc.getSeenReveals(widget.bookData.book),
    ]);

    if (!mounted) return;

    final verses = results[0] as List<({int verse, String text})>;
    _seenReveals = results[1] as Set<String>;
    _triggerMap = widget.bookData.allObservationsForChapter(_chapter);
    _chapterSummary = widget.bookData.summaryForChapter(_chapter);
    _crossRefs = widget.bookData.crossRefsForChapter(_chapter);

    // Assign keys to trigger verses
    _triggerKeys.clear();
    for (final verseNum in _triggerMap.keys) {
      _triggerKeys[verseNum] = GlobalKey();
    }

    setState(() {
      _verses = verses;
      _loading = false;
    });

    _headerCtrl.forward(from: 0);
    await svc.saveJourneyPosition(widget.bookData.book, _chapter);
  }

  Future<List<({int verse, String text})>> _loadVerses() async {
    try {
      final raw = await rootBundle
          .loadString('assets/asr/${widget.bookData.book}/$_chapter.json');
      final json = jsonDecode(raw);
      final verses = <({int verse, String text})>[];

      if (json is List) {
        // Array format: each index is a verse
        for (var i = 0; i < json.length; i++) {
          final text = _extractText(json[i]);
          if (text.isNotEmpty) verses.add((verse: i + 1, text: text));
        }
      } else if (json is Map) {
        final versesRaw = json['verses'];
        if (versesRaw is Map) {
          // Object format: {"1": "text", "2": "text", ...}
          final keys = versesRaw.keys
              .map((k) => int.tryParse(k.toString()) ?? 0)
              .toList()
            ..sort();
          for (final v in keys) {
            final text = _extractText(versesRaw['$v']);
            if (text.isNotEmpty) verses.add((verse: v, text: text));
          }
        } else if (versesRaw is List) {
          for (var i = 0; i < versesRaw.length; i++) {
            final text = _extractText(versesRaw[i]);
            if (text.isNotEmpty) verses.add((verse: i + 1, text: text));
          }
        }
      }
      return verses;
    } catch (_) {
      return [];
    }
  }

  String _extractText(dynamic item) {
    if (item is String) return item;
    if (item is Map<String, dynamic>) {
      if (item.containsKey('segments')) {
        final segs = item['segments'] as List? ?? [];
        return segs
            .map((s) => s is Map ? (s['text'] ?? '').toString() : s.toString())
            .join(' ');
      }
      return (item['text'] ?? '').toString();
    }
    return '';
  }

  void _onScroll() {
    if (_verses.isEmpty) return;
    final screenH = MediaQuery.sizeOf(context).height;
    final triggerZone = screenH * 0.42;

    for (final entry in _triggerKeys.entries) {
      final verseNum = entry.key;
      final key = entry.value;
      final revealKey = '${_chapter}:$verseNum';
      if (_seenReveals.contains(revealKey)) continue;

      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dy < triggerZone && pos.dy > -box.size.height) {
        _fireReveal(verseNum);
        break; // One at a time
      }
    }

    // Show chapter summary when near end
    if (!_showSummary && _chapterSummary != null) {
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      if (_scrollCtrl.offset > maxScroll * 0.85) {
        setState(() => _showSummary = true);
      }
    }
  }

  void _fireReveal(int verseNum) {
    final observations = _triggerMap[verseNum];
    if (observations == null || observations.isEmpty) return;
    final obs = observations.first;
    final revealKey = '${_chapter}:$verseNum';

    // Preemptively mark seen to prevent double-fire during animation
    _seenReveals.add(revealKey);
    ChristRevealedService.instance
        .markRevealSeen(widget.bookData.book, revealKey);

    setState(() => _pendingReveal = obs);
    _revealCtrl.forward(from: 0);
  }

  void _dismissReveal() {
    _revealCtrl.reverse().then((_) {
      if (mounted) setState(() => _pendingReveal = null);
    });
  }

  void _prevChapter() {
    if (_chapter <= 1) return;
    _chapter--;
    _loadChapter();
    _scrollCtrl.jumpTo(0);
  }

  void _nextChapter() {
    _chapter++;
    _loadChapter();
    _scrollCtrl.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: CRColors.bg,
      body: Stack(
        children: [
          // Star background
          Positioned.fill(
            child: CustomPaint(painter: _ReaderStarPainter(size)),
          ),

          // Main content
          Column(
            children: [
              SizedBox(height: top),
              _buildTopBar(top),
              Expanded(
                child: _loading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: CRColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : _buildVerseList(),
              ),
              _buildBottomNav(bottom),
            ],
          ),

          // Reveal Moment Overlay
          if (_pendingReveal != null)
            _RevealOverlay(
              obs: _pendingReveal!.obs,
              isChrist: _pendingReveal!.isChrist,
              eventTitle: _pendingReveal!.eventTitle,
              animation: _revealCtrl,
              onDismiss: _dismissReveal,
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double top) {
    return FadeTransition(
      opacity: _headerCtrl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                      color: CRColors.gold.withValues(alpha: 0.15)),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: CRColors.parchment.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bookData.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: CRColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                  Text(
                    'Chapter $_chapter',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CRColors.parchment,
                    ),
                  ),
                ],
              ),
            ),
            // Trigger count badge
            if (_triggerMap.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CRColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: CRColors.gold.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 9,
                        color: CRColors.gold.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_triggerMap.length} reveal${_triggerMap.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: CRColors.gold.withValues(alpha: 0.7),
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

  Widget _buildVerseList() {
    return FadeTransition(
      opacity: _headerCtrl,
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
        itemCount: _verses.length + (_showSummary && _chapterSummary != null ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _verses.length) {
            return _buildChapterSummaryCard();
          }
          final v = _verses[i];
          final triggers = _triggerMap[v.verse];
          final hasTrigger = triggers != null && triggers.isNotEmpty;
          final key = hasTrigger ? _triggerKeys[v.verse] : null;

          return _VerseRow(
            key: key,
            verse: v.verse,
            text: v.text,
            hasTrigger: hasTrigger,
            triggerIsChrist: triggers?.firstOrNull?.isChrist ?? false,
            seen: hasTrigger
                ? _seenReveals.contains('$_chapter:${v.verse}')
                : false,
          );
        },
      ),
    );
  }

  Widget _buildChapterSummaryCard() {
    final summary = _chapterSummary!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CRColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: CRColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '✦',
                  style: TextStyle(
                      fontSize: 12,
                      color: CRColors.gold.withValues(alpha: 0.7)),
                ),
                const SizedBox(width: 8),
                Text(
                  'CHAPTER ${summary.chapter} SUMMARY',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: CRColors.gold.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              summary.text,
              style: const TextStyle(
                fontSize: 14.5,
                color: CRColors.parchment,
                height: 1.75,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_crossRefs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: CRColors.gold.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Text(
                'ALSO IN SCRIPTURE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: CRColors.parchmentDim.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 10),
              ..._crossRefs.map((ref) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CRColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.reference,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: CRColors.gold.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ref.note,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: CRColors.parchmentDim
                                      .withValues(alpha: 0.6),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(double bottom) {
    return Container(
      height: 56 + bottom,
      decoration: BoxDecoration(
        color: CRColors.bgCard,
        border: Border(
          top: BorderSide(color: CRColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prev chapter
            TextButton.icon(
              onPressed: _chapter > 1 ? _prevChapter : null,
              icon: Icon(Icons.arrow_back_ios_rounded,
                  size: 13,
                  color: _chapter > 1
                      ? CRColors.gold.withValues(alpha: 0.6)
                      : CRColors.parchmentDim.withValues(alpha: 0.15)),
              label: Text(
                'Previous',
                style: TextStyle(
                  fontSize: 12,
                  color: _chapter > 1
                      ? CRColors.gold.withValues(alpha: 0.6)
                      : CRColors.parchmentDim.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Chapter indicator
            Text(
              '$_chapter',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: CRColors.parchmentDim.withValues(alpha: 0.35),
              ),
            ),
            // Next chapter
            TextButton.icon(
              onPressed: _nextChapter,
              icon: Text(
                'Next',
                style: TextStyle(
                  fontSize: 12,
                  color: CRColors.gold.withValues(alpha: 0.6),
                ),
              ),
              label: Icon(Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: CRColors.gold.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Verse Row ─────────────────────────────────────────────────────────────────

class _VerseRow extends StatelessWidget {
  const _VerseRow({
    super.key,
    required this.verse,
    required this.text,
    required this.hasTrigger,
    required this.triggerIsChrist,
    required this.seen,
  });

  final int verse;
  final String text;
  final bool hasTrigger;
  final bool triggerIsChrist;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left indicator column
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  // Top padding alignment
                  const SizedBox(height: 16),
                  if (hasTrigger)
                    Container(
                      width: 2,
                      height: 18,
                      decoration: BoxDecoration(
                        color: seen
                            ? (triggerIsChrist
                                    ? CRColors.gold
                                    : CRColors.crimson)
                                .withValues(alpha: 0.35)
                            : (triggerIsChrist
                                    ? CRColors.gold
                                    : CRColors.crimson)
                                .withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Verse content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verse number
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 10),
                      child: Text(
                        '$verse',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: hasTrigger
                              ? (triggerIsChrist ? CRColors.gold : CRColors.crimson)
                                  .withValues(alpha: seen ? 0.35 : 0.65)
                              : CRColors.parchmentDim.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // Text
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 15.5,
                          color: CRColors.parchment
                              .withValues(alpha: hasTrigger ? 0.92 : 0.72),
                          height: 1.8,
                          letterSpacing: 0.1,
                        ),
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

// ── Reveal Overlay ────────────────────────────────────────────────────────────

class _RevealOverlay extends StatefulWidget {
  const _RevealOverlay({
    required this.obs,
    required this.isChrist,
    required this.eventTitle,
    required this.animation,
    required this.onDismiss,
  });

  final CRObservation obs;
  final bool isChrist;
  final String eventTitle;
  final AnimationController animation;
  final VoidCallback onDismiss;

  @override
  State<_RevealOverlay> createState() => _RevealOverlayState();
}

class _RevealOverlayState extends State<_RevealOverlay> {
  late Animation<double> _bg;
  late Animation<double> _content;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _bg = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _content = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChrist = widget.isChrist;
    final accentColor = isChrist ? CRColors.gold : CRColors.crimson;
    final label = isChrist ? 'CHRIST REVEALED' : "THE ADVERSARY'S MOVE";
    final symbol = isChrist ? '✦' : '◈';
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (_, child) => Opacity(
          opacity: _bg.value,
          child: child,
        ),
        child: Container(
          width: size.width,
          height: size.height,
          color: const Color(0xCC000000),
          child: Stack(
            children: [
              // Radial glow behind content
              Center(
                child: AnimatedBuilder(
                  animation: _content,
                  builder: (_, __) => Opacity(
                    opacity: _content.value * 0.5,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content card
              Center(
                child: SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _content,
                    child: Container(
                      width: size.width * 0.88,
                      constraints: const BoxConstraints(maxWidth: 520),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF120E09),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.12),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top accent strip
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  accentColor.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                            child: Column(
                              children: [
                                // Symbol + Label
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      symbol,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: accentColor
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3.5,
                                        color: accentColor
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Event title
                                Text(
                                  widget.eventTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: CRColors.parchment,
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Divider
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        accentColor.withValues(alpha: 0.25),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Observation text
                                Text(
                                  widget.obs.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: CRColors.parchment
                                        .withValues(alpha: 0.85),
                                    height: 1.75,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Close button
                                GestureDetector(
                                  onTap: widget.onDismiss,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 28, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                          color: accentColor
                                              .withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      'CONTINUE READING',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2.5,
                                        color: accentColor
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ── Star Painter ──────────────────────────────────────────────────────────────

class _ReaderStarPainter extends CustomPainter {
  const _ReaderStarPainter(this.size);
  final Size size;

  @override
  void paint(Canvas canvas, Size s) {
    final rng = _Lcg(7);
    final paint = Paint();
    for (var i = 0; i < 120; i++) {
      final x = rng.nextDouble() * s.width;
      final y = rng.nextDouble() * s.height;
      final r = rng.nextDouble() * 0.9 + 0.25;
      final a = rng.nextDouble() * 0.25 + 0.03;
      paint.color = CRColors.star.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// Deterministic LCG so stars don't move on rebuild
class _Lcg {
  _Lcg(int seed) : _state = seed;
  int _state;
  double nextDouble() {
    _state = (1664525 * _state + 1013904223) & 0xFFFFFFFF;
    return (_state & 0x7FFFFFFF) / 0x7FFFFFFF;
  }
}
