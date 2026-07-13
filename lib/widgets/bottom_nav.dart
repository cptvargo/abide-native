import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/abide_theme.dart';

enum NavTab { home, scripture, journal, search, settings }

class AbideBottomNav extends StatelessWidget {
  const AbideBottomNav({
    super.key,
    required this.current,
    required this.onTap,
    this.visible = true,
  });

  final NavTab current;
  final ValueChanged<NavTab> onTap;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.6),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: visible ? 1.0 : 0.0,
        child: Padding(
          padding: EdgeInsets.only(left: 24, right: 24, bottom: bottom == 0 ? 8 : bottom),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.navRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.navPillBg.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(theme.navRadius),
                  border: Border.all(
                    color: theme.navColor.withValues(alpha: theme.isLight ? 0.40 : 0.20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 28,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: NavTab.values
                      .map((tab) => Expanded(
                            child: _NavItem(
                              tab: tab,
                              isActive: tab == current,
                              accent: theme.navColor,
                              onTap: () => onTap(tab),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  final NavTab tab;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  // PWA-matched icon paths via SVG-equivalent Material icons
  Widget _icon(Color color) {
    return switch (tab) {
      NavTab.home => Icon(
          isActive ? Icons.home_rounded : Icons.home_outlined,
          size: 22,
          color: color,
        ),
      NavTab.scripture => Icon(
          isActive ? Icons.menu_book : Icons.menu_book_outlined,
          size: 22,
          color: color,
        ),
      NavTab.journal => Icon(
          isActive ? Icons.edit_note_rounded : Icons.edit_note_outlined,
          size: 22,
          color: color,
        ),
      NavTab.search => Icon(Icons.search_rounded, size: 22, color: color),
      NavTab.settings => Icon(
          isActive ? Icons.tune : Icons.tune_rounded,
          size: 22,
          color: color,
        ),
    };
  }

  String get _label => switch (tab) {
        NavTab.home => 'Home',
        NavTab.scripture => 'Scripture',
        NavTab.journal => 'Journal',
        NavTab.search => 'Search',
        NavTab.settings => 'Settings',
      };

  @override
  Widget build(BuildContext context) {
    // navPillBg is always dark (dark bgMenu or dark leather), so inactive is always white
    final iconColor = isActive ? accent : Colors.white.withValues(alpha: 0.38);
    final labelColor = isActive ? accent : Colors.white.withValues(alpha: 0.32);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with dot indicator below (dot is clipped outside stack)
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _icon(iconColor),
                if (isActive)
                  Positioned(
                    bottom: -5,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
