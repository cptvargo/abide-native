import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/christ_revealed_models.dart';
import '../services/christ_revealed_service.dart';
import 'christ_revealed_reader_screen.dart';

class ChristRevealedHubScreen extends StatefulWidget {
  const ChristRevealedHubScreen({super.key});

  @override
  State<ChristRevealedHubScreen> createState() =>
      _ChristRevealedHubScreenState();
}

class _ChristRevealedHubScreenState extends State<ChristRevealedHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _pulse;

  List<CRIndexEntry> _index = [];
  ({String book, int chapter})? _position;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _fadeIn =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final svc = ChristRevealedService.instance;
    final results = await Future.wait([
      svc.loadIndex(),
      svc.getJourneyPosition(),
    ]);
    if (!mounted) return;
    setState(() {
      _index = results[0] as List<CRIndexEntry>;
      _position = results[1] as ({String book, int chapter})?;
      _loading = false;
    });
    _entranceCtrl.forward();
  }

  void _openBook(CRIndexEntry entry) async {
    final svc = ChristRevealedService.instance;
    final book = await svc.loadBook(entry.book);
    if (book == null || !mounted) return;
    final chapter =
        await svc.getCurrentChapter(entry.book) ?? 1;
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => ChristRevealedReaderScreen(
          bookData: book,
          startChapter: chapter,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
    if (mounted) {
      final pos = await svc.getJourneyPosition();
      setState(() => _position = pos);
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: CRColors.bg,
      body: Stack(
        children: [
          // Cosmic background
          Positioned.fill(
            child: CustomPaint(painter: _CosmicPainter(size)),
          ),
          // Nebula glow
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: size.width * 0.7,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    CRColors.gold.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          if (_loading)
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: CRColors.gold.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            FadeTransition(
              opacity: _fadeIn,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: top + 24)),
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_position != null)
                    SliverToBoxAdapter(child: _buildContinueCard()),
                  SliverToBoxAdapter(
                      child: _buildJourneyHeader('THE OLD TESTAMENT')),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      _buildBookNodes(
                          _index.where((e) => e.testament == 'OT').toList()),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildTestamentDivider()),
                  SliverToBoxAdapter(
                      child: _buildJourneyHeader('THE NEW TESTAMENT')),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      _buildBookNodes(
                          _index.where((e) => e.testament == 'NT').toList()),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),

          // Back button
          Positioned(
            top: top + 16,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                      color: CRColors.gold.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.close_rounded,
                    color: CRColors.parchment.withValues(alpha: 0.6),
                    size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold bar
          Container(
            width: 24,
            height: 1.5,
            color: CRColors.gold.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'CHRIST REVEALED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 4.5,
              color: CRColors.gold.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Jesus from\nGenesis to Revelation',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: CRColors.parchment,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Christ in you, the hope of glory.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: CRColors.parchmentDim.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Colossians 1:27',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.5,
              color: CRColors.gold.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueCard() {
    final pos = _position!;
    final entry =
        _index.where((e) => e.book == pos.book).firstOrNull;
    if (entry == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: GestureDetector(
        onTap: () => _openBook(entry),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: CRColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: CRColors.gold.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: CRColors.gold.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Gold candle icon area
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CRColors.gold.withValues(alpha: 0.1),
                  border: Border.all(
                      color: CRColors.gold.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: 18,
                      color: CRColors.gold.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTINUE YOUR JOURNEY',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: CRColors.gold.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.displayName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CRColors.parchment,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chapter ${pos.chapter}',
                      style: TextStyle(
                        fontSize: 12,
                        color: CRColors.parchmentDim.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: CRColors.gold.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: CRColors.gold.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildTestamentDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  CRColors.gold.withValues(alpha: 0.3),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 14,
                color: CRColors.gold.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  CRColors.gold.withValues(alpha: 0.3),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBookNodes(List<CRIndexEntry> books) {
    return books.asMap().entries.map((entry) {
      final i = entry.key;
      final book = entry.value;
      final isLast = i == books.length - 1;
      return _BookNode(
        entry: book,
        isLast: isLast,
        pulse: _pulse,
        onTap: book.available ? () => _openBook(book) : null,
        isCurrentPosition: _position?.book == book.book,
      );
    }).toList();
  }
}

// ── Book Node ─────────────────────────────────────────────────────────────────

class _BookNode extends StatelessWidget {
  const _BookNode({
    required this.entry,
    required this.isLast,
    required this.pulse,
    required this.onTap,
    required this.isCurrentPosition,
  });

  final CRIndexEntry entry;
  final bool isLast;
  final Animation<double> pulse;
  final VoidCallback? onTap;
  final bool isCurrentPosition;

  @override
  Widget build(BuildContext context) {
    final isAvailable = entry.available;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Connector line above
                Expanded(
                  child: Center(
                    child: Container(
                      width: 1.5,
                      color: isAvailable
                          ? CRColors.gold.withValues(alpha: 0.25)
                          : CRColors.parchmentDim.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Node
                if (isAvailable)
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isCurrentPosition)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CRColors.gold
                                  .withValues(alpha: 0.15 * pulse.value),
                            ),
                          ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrentPosition
                                ? CRColors.gold
                                : CRColors.gold.withValues(alpha: 0.6),
                            boxShadow: [
                              BoxShadow(
                                color: CRColors.gold.withValues(
                                    alpha: isCurrentPosition
                                        ? 0.5 * pulse.value
                                        : 0.25),
                                blurRadius: 10,
                                spreadRadius: isCurrentPosition ? 3 : 1,
                              ),
                            ],
                          ),
                          child: isCurrentPosition
                              ? null
                              : Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CRColors.bg,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CRColors.parchmentDim.withValues(alpha: 0.12),
                    ),
                  ),
                // Connector line below
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1.5,
                        color: isAvailable
                            ? CRColors.gold.withValues(alpha: 0.25)
                            : CRColors.parchmentDim.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                if (isLast) const SizedBox(height: 12),
              ],
            ),
          ),

          // Content column
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 24, 6),
                child: isAvailable
                    ? _AvailableBookCard(
                        entry: entry, isCurrent: isCurrentPosition)
                    : _UnavailableBookRow(entry: entry),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableBookCard extends StatelessWidget {
  const _AvailableBookCard(
      {required this.entry, required this.isCurrent});
  final CRIndexEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: CRColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? CRColors.gold.withValues(alpha: 0.35)
              : CRColors.gold.withValues(alpha: 0.15),
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: CRColors.gold.withValues(alpha: 0.07),
                  blurRadius: 16,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: CRColors.parchment,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.eventCount} revelation${entry.eventCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: CRColors.gold.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 11,
              color: CRColors.gold.withValues(alpha: 0.35)),
        ],
      ),
    );
  }
}

class _UnavailableBookRow extends StatelessWidget {
  const _UnavailableBookRow({required this.entry});
  final CRIndexEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            entry.displayName,
            style: TextStyle(
              fontSize: 13,
              color: CRColors.parchmentDim.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '·',
            style: TextStyle(
              color: CRColors.parchmentDim.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.3,
              color: CRColors.parchmentDim.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cosmic Background Painter ─────────────────────────────────────────────────

class _CosmicPainter extends CustomPainter {
  _CosmicPainter(this.size);
  final Size size;

  @override
  void paint(Canvas canvas, Size s) {
    final rng = math.Random(42);
    final paint = Paint();

    // Draw stars
    for (var i = 0; i < 180; i++) {
      final x = rng.nextDouble() * s.width;
      final y = rng.nextDouble() * s.height;
      final r = rng.nextDouble() * 1.2 + 0.3;
      final alpha = rng.nextDouble() * 0.4 + 0.05;
      paint.color = CRColors.star.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // A few larger star glints
    for (var i = 0; i < 12; i++) {
      final x = rng.nextDouble() * s.width;
      final y = rng.nextDouble() * s.height;
      paint.color = CRColors.star.withValues(alpha: 0.12);
      canvas.drawCircle(Offset(x, y), 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
