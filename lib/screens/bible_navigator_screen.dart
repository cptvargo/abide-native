import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/bible_books.dart';
import '../theme/abide_theme.dart';
import '../widgets/atmospheric_bg.dart';

class BibleNavigatorScreen extends StatefulWidget {
  const BibleNavigatorScreen({
    super.key,
    required this.currentBook,
    required this.currentChapter,
    required this.onSelect,
  });

  final String currentBook;
  final int currentChapter;
  final void Function(String book, int chapter) onSelect;

  @override
  State<BibleNavigatorScreen> createState() => _BibleNavigatorScreenState();
}

class _BibleNavigatorScreenState extends State<BibleNavigatorScreen> {
  BibleBook? _selectedBook;

  @override
  void initState() {
    super.initState();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavHeader(
              theme: theme,
              topPad: topPad,
              selectedBook: _selectedBook,
              onBack: () => setState(() => _selectedBook = null),
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_selectedBook != null ? 0.04 : -0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _selectedBook != null
                    ? _ChapterGrid(
                        key: ValueKey('ch:${_selectedBook!.name}'),
                        book: _selectedBook!,
                        currentChapter: _selectedBook!.name == widget.currentBook
                            ? widget.currentChapter
                            : null,
                        theme: theme,
                        onSelect: (ch) {
                          widget.onSelect(_selectedBook!.name, ch);
                          Navigator.of(context).pop();
                        },
                      )
                    : _AllBooksList(
                        key: const ValueKey('books'),
                        theme: theme,
                        currentBook: widget.currentBook,
                        onSelect: (book) => setState(() => _selectedBook = book),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav header ────────────────────────────────────────────────────────────────

class _NavHeader extends StatelessWidget {
  const _NavHeader({
    required this.theme,
    required this.topPad,
    required this.selectedBook,
    required this.onBack,
    required this.onClose,
  });

  final AbideThemeData theme;
  final double topPad;
  final BibleBook? selectedBook;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 16, 12),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectedBook != null
                ? GestureDetector(
                    key: const ValueKey('back'),
                    onTap: onBack,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_back_rounded,
                          color: theme.textAccent, size: 22),
                    ),
                  )
                : const SizedBox(key: ValueKey('none')),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              selectedBook != null
                  ? selectedBook!.name.toUpperCase()
                  : 'SCRIPTURE',
              key: ValueKey(selectedBook?.name ?? 'scripture'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.8,
                color: theme.textAccent.withValues(alpha: 0.55),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.subtleFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.subtleOutline, width: 1),
              ),
              child: Icon(Icons.close_rounded, size: 17, color: theme.mutedIcon),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Book list — all 66 books in one scrollable list ───────────────────────────

class _AllBooksList extends StatelessWidget {
  const _AllBooksList({
    super.key,
    required this.theme,
    required this.currentBook,
    required this.onSelect,
  });

  final AbideThemeData theme;
  final String currentBook;
  final ValueChanged<BibleBook> onSelect;

  @override
  Widget build(BuildContext context) {
    final allSections = [...otSections, ...ntSections];
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        for (final section in allSections) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                children: [
                  Text(
                    section.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: theme.textAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 1, color: theme.hairline)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final book = section.books[i];
                  final isActive = book.name == currentBook;
                  return _BookTile(
                    book: book,
                    isActive: isActive,
                    theme: theme,
                    onTap: () => onSelect(book),
                  );
                },
                childCount: section.books.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  final BibleBook book;
  final bool isActive;
  final AbideThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive
              ? theme.textAccent.withValues(alpha: 0.12)
              : theme.subtleFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? theme.textAccent.withValues(alpha: 0.30)
                : theme.subtleOutline,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.name,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isActive ? theme.textAccent : theme.textPrimary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${book.chapters} ch',
              style: TextStyle(
                fontSize: 9,
                color: isActive
                    ? theme.textAccent.withValues(alpha: 0.6)
                    : theme.textPrimary.withValues(alpha: 0.28),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chapter grid ──────────────────────────────────────────────────────────────

class _ChapterGrid extends StatelessWidget {
  const _ChapterGrid({
    super.key,
    required this.book,
    required this.currentChapter,
    required this.theme,
    required this.onSelect,
  });

  final BibleBook book;
  final int? currentChapter;
  final AbideThemeData theme;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Book title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                    color: theme.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                        width: 28,
                        height: 1.5,
                        color: theme.textAccent.withValues(alpha: 0.35)),
                    const SizedBox(width: 10),
                    Text(
                      '${book.chapters} CHAPTERS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: theme.textAccent.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Chapter grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final ch = i + 1;
                final isActive = ch == currentChapter;
                return GestureDetector(
                  onTap: () => onSelect(ch),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.textAccent.withValues(alpha: 0.18)
                          : theme.subtleFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? theme.textAccent.withValues(alpha: 0.4)
                            : theme.subtleOutline,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$ch',
                        style: TextStyle(
                          fontSize: isActive ? 14 : 13,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? theme.textAccent
                              : theme.textPrimary.withValues(alpha: 0.60),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: book.chapters,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }
}
