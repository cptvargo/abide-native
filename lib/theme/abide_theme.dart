import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AbideThemeData extends ThemeExtension<AbideThemeData> {
  const AbideThemeData({
    required this.bgApp,
    required this.bgMenu,
    required this.surface,
    required this.textPrimary,
    required this.textAccent,
    required this.textMuted,
    required this.christAccent,
    required this.navColor,
    required this.bodyFont,
    required this.brightness,
    required this.verseFontSize,
    required this.verseLineHeight,
    required this.verseTracking,
    required this.navRadius,
    required this.verseNumOpacity,
    required this.chapterlessFont,
    required this.chapterlessFontSize,
    required this.chapterlessLineHeight,
    required this.chapterlessTracking,
    required this.chapterlessPadding,
  });

  final Color bgApp;
  final Color bgMenu;
  final Color surface;
  final Color textPrimary;
  final Color textAccent;
  final Color textMuted;
  final Color christAccent;
  final Color navColor;
  final TextStyle Function(double fontSize) bodyFont;
  final Brightness brightness;

  // ── Per-theme reading personality ─────────────────────────────────────────
  final double verseFontSize;        // base font size for verse text
  final double verseLineHeight;      // line height — controls breathing room
  final double verseTracking;        // letter spacing — controls rhythm
  final double navRadius;            // bottom nav container corner radius
  final double verseNumOpacity;      // verse number contrast — higher on light themes

  // ── Chapterless mode identity — prose book format ─────────────────────────
  final TextStyle Function(double fontSize) chapterlessFont;
  final double chapterlessFontSize;
  final double chapterlessLineHeight;
  final double chapterlessTracking;
  final double chapterlessPadding;   // horizontal padding — wider than verse mode

  bool get isLight => brightness == Brightness.light;

  // 3 highlight colors per theme — accent-matched palettes
  List<({Color color, String id})> get highlightColors {
    if (textAccent == const Color(0xFF7ED0D8)) {
      return const [
        (id: 'teal',  color: Color(0xFF7ED0D8)),
        (id: 'aqua',  color: Color(0xFF4BB8C8)),
        (id: 'sage',  color: Color(0xFF6BAA82)),
      ];
    }
    if (textAccent == const Color(0xFFF97316)) {
      return const [
        (id: 'amber',   color: Color(0xFFE67E22)),
        (id: 'crimson', color: Color(0xFFB83232)),
        (id: 'gold',    color: Color(0xFFD4A843)),
      ];
    }
    if (textAccent == const Color(0xFF8A9E5C)) {
      return const [
        (id: 'olive',  color: Color(0xFF8A9E5C)),
        (id: 'gold',   color: Color(0xFFC8B45A)),
        (id: 'forest', color: Color(0xFF5A8A50)),
      ];
    }
    if (textAccent == const Color(0xFF9B6B3C)) {
      return const [
        (id: 'warm-gold', color: Color(0xFFB8863A)),
        (id: 'rose',      color: Color(0xFFC06060)),
        (id: 'sage',      color: Color(0xFF6B8F5C)),
      ];
    }
    // Classic (default)
    return const [
      (id: 'gold', color: Color(0xFFD4A843)),
      (id: 'rose', color: Color(0xFFD97B8B)),
      (id: 'teal', color: Color(0xFF4FB5BE)),
    ];
  }

  // ── Adaptive helpers — correct on both light and dark backgrounds ─────────
  Color get subtleFill => isLight
      ? Colors.black.withValues(alpha: 0.05)
      : Colors.white.withValues(alpha: 0.05);

  Color get subtleOutline => isLight
      ? Colors.black.withValues(alpha: 0.09)
      : Colors.white.withValues(alpha: 0.08);

  Color get mutedIcon => isLight
      ? textPrimary.withValues(alpha: 0.38)
      : Colors.white.withValues(alpha: 0.40);

  Color get hairline => isLight
      ? Colors.black.withValues(alpha: 0.07)
      : Colors.white.withValues(alpha: 0.06);

  Color get navPillBg => isLight ? const Color(0xFF2A1C0C) : bgMenu;

  TextStyle verseStyle({double? fontSize}) =>
      bodyFont(fontSize ?? verseFontSize).copyWith(
        color: textPrimary,
        height: verseLineHeight,
        letterSpacing: verseTracking,
      );

  TextStyle christStyle({double? fontSize}) =>
      bodyFont(fontSize ?? verseFontSize).copyWith(
        color: christAccent,
        height: verseLineHeight,
        letterSpacing: verseTracking,
      );

  TextStyle chapterlessStyle({double? fontSize}) =>
      chapterlessFont(fontSize ?? chapterlessFontSize).copyWith(
        color: textPrimary,
        height: chapterlessLineHeight,
        letterSpacing: chapterlessTracking,
      );

  @override
  AbideThemeData copyWith({
    Color? bgApp,
    Color? bgMenu,
    Color? surface,
    Color? textPrimary,
    Color? textAccent,
    Color? textMuted,
    Color? christAccent,
    Color? navColor,
    TextStyle Function(double)? bodyFont,
    Brightness? brightness,
    double? verseFontSize,
    double? verseLineHeight,
    double? verseTracking,
    double? navRadius,
    double? verseNumOpacity,
    TextStyle Function(double)? chapterlessFont,
    double? chapterlessFontSize,
    double? chapterlessLineHeight,
    double? chapterlessTracking,
    double? chapterlessPadding,
  }) =>
      AbideThemeData(
        bgApp: bgApp ?? this.bgApp,
        bgMenu: bgMenu ?? this.bgMenu,
        surface: surface ?? this.surface,
        textPrimary: textPrimary ?? this.textPrimary,
        textAccent: textAccent ?? this.textAccent,
        textMuted: textMuted ?? this.textMuted,
        christAccent: christAccent ?? this.christAccent,
        navColor: navColor ?? this.navColor,
        bodyFont: bodyFont ?? this.bodyFont,
        brightness: brightness ?? this.brightness,
        verseFontSize: verseFontSize ?? this.verseFontSize,
        verseLineHeight: verseLineHeight ?? this.verseLineHeight,
        verseTracking: verseTracking ?? this.verseTracking,
        navRadius: navRadius ?? this.navRadius,
        verseNumOpacity: verseNumOpacity ?? this.verseNumOpacity,
        chapterlessFont: chapterlessFont ?? this.chapterlessFont,
        chapterlessFontSize: chapterlessFontSize ?? this.chapterlessFontSize,
        chapterlessLineHeight: chapterlessLineHeight ?? this.chapterlessLineHeight,
        chapterlessTracking: chapterlessTracking ?? this.chapterlessTracking,
        chapterlessPadding: chapterlessPadding ?? this.chapterlessPadding,
      );

  @override
  AbideThemeData lerp(AbideThemeData? other, double t) {
    if (other == null) return this;
    return AbideThemeData(
      bgApp: Color.lerp(bgApp, other.bgApp, t)!,
      bgMenu: Color.lerp(bgMenu, other.bgMenu, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      christAccent: Color.lerp(christAccent, other.christAccent, t)!,
      navColor: Color.lerp(navColor, other.navColor, t)!,
      bodyFont: t < 0.5 ? bodyFont : other.bodyFont,
      brightness: t < 0.5 ? brightness : other.brightness,
      verseFontSize: verseFontSize + (other.verseFontSize - verseFontSize) * t,
      verseLineHeight: verseLineHeight + (other.verseLineHeight - verseLineHeight) * t,
      verseTracking: verseTracking + (other.verseTracking - verseTracking) * t,
      navRadius: navRadius + (other.navRadius - navRadius) * t,
      verseNumOpacity: verseNumOpacity + (other.verseNumOpacity - verseNumOpacity) * t,
      chapterlessFont: t < 0.5 ? chapterlessFont : other.chapterlessFont,
      chapterlessFontSize: chapterlessFontSize + (other.chapterlessFontSize - chapterlessFontSize) * t,
      chapterlessLineHeight: chapterlessLineHeight + (other.chapterlessLineHeight - chapterlessLineHeight) * t,
      chapterlessTracking: chapterlessTracking + (other.chapterlessTracking - chapterlessTracking) * t,
      chapterlessPadding: chapterlessPadding + (other.chapterlessPadding - chapterlessPadding) * t,
    );
  }
}

abstract final class AbideThemes {
  // ── Classic ───────────────────────────────────────────────────────────────
  // Candlelit study. Cormorant Garamond italic w500 — large and personal,
  // like reading from a handwritten family Bible by firelight. Tight negative
  // tracking pulls letters together for an intimate, treasured feel.
  static final classic = AbideThemeData(
    bgApp: const Color(0xFF0A0805),
    bgMenu: const Color(0xFF1C1A16),
    surface: const Color(0xFF13100B),
    textPrimary: const Color(0xDEFFFFFF),
    textAccent: const Color(0xFFCBB27C),
    textMuted: const Color(0x70FFFFFF),
    christAccent: const Color(0xFFE8C97A),
    navColor: const Color(0xFFCBB27C),
    bodyFont: (sz) => GoogleFonts.lora(
      fontSize: sz,
      fontWeight: FontWeight.w400,
    ),
    brightness: Brightness.dark,
    verseFontSize: 20,
    verseLineHeight: 2.10,
    verseTracking: 0.10,
    navRadius: 999,
    verseNumOpacity: 0.65,
    chapterlessFont: (sz) => GoogleFonts.lora(fontSize: sz, fontWeight: FontWeight.w400),
    chapterlessFontSize: 20,
    chapterlessLineHeight: 2.10,
    chapterlessTracking: 0.08,
    chapterlessPadding: 40,
  );

  // ── Still Waters ──────────────────────────────────────────────────────────
  // Dawn silence. Lora w300 — light, open, unhurried. The smallest text and
  // tallest line height of any theme: each verse arrives like a breath, hangs
  // in the air, then passes. The space between lines IS the message.
  static final stillWaters = AbideThemeData(
    bgApp: const Color(0xFF0A1E24),
    bgMenu: const Color(0xFF0D2830),
    surface: const Color(0xFF071820),
    textPrimary: const Color(0xFFD8EEF2),
    textAccent: const Color(0xFF7ED0D8),
    textMuted: const Color(0x70D8EEF2),
    christAccent: const Color(0xFFB0DDE4),
    navColor: const Color(0xFF7ED0D8),
    bodyFont: (sz) => GoogleFonts.lora(
      fontSize: sz,
      fontWeight: FontWeight.w300,
    ),
    brightness: Brightness.dark,
    verseFontSize: 18,
    verseLineHeight: 2.40,
    verseTracking: 0.28,
    navRadius: 999,
    verseNumOpacity: 0.65,
    chapterlessFont: (sz) => GoogleFonts.lora(fontSize: sz, fontWeight: FontWeight.w300),
    chapterlessFontSize: 19,
    chapterlessLineHeight: 2.20,
    chapterlessTracking: 0.12,
    chapterlessPadding: 40,
  );

  // ── Stone & Fire ──────────────────────────────────────────────────────────
  // Prophetic intensity. Near-black with scorched orange. Playfair Display
  // Bold — thick strokes, razor hairlines, high drama. Tight leading and
  // larger size make every verse feel like proclamation. Angular nav like
  // chiseled stone.
  static final stoneFire = AbideThemeData(
    bgApp: const Color(0xFF0F0F0F),
    bgMenu: const Color(0xFF1A140E),
    surface: const Color(0xFF0A0A0A),
    textPrimary: const Color(0xFFEDE8E0),
    textAccent: const Color(0xFFF97316),
    textMuted: const Color(0x70EDE8E0),
    christAccent: const Color(0xFFFF6B35),
    navColor: const Color(0xFFF97316),
    bodyFont: (sz) => GoogleFonts.crimsonText(
      fontSize: sz,
      fontWeight: FontWeight.w600,
    ),
    brightness: Brightness.dark,
    verseFontSize: 21,
    verseLineHeight: 1.90,
    verseTracking: 0.05,
    navRadius: 20,
    verseNumOpacity: 0.85,
    chapterlessFont: (sz) => GoogleFonts.lora(fontSize: sz, fontWeight: FontWeight.w700),
    chapterlessFontSize: 20,
    chapterlessLineHeight: 2.00,
    chapterlessTracking: 0.05,
    chapterlessPadding: 40,
  );

  // ── Olive & Parchment ─────────────────────────────────────────────────────
  // Ancient scroll. Deep forest dark with sage-olive light. Spectral Bold
  // Italic — heavy strokes in an old-style face, commanding and weighty.
  // Wide tracking respects the slow, deliberate pace of a scholar's reading.
  static final oliveAndParchment = AbideThemeData(
    bgApp: const Color(0xFF0C0F08),
    bgMenu: const Color(0xFF141A0D),
    surface: const Color(0xFF0A0D06),
    textPrimary: const Color(0xFFDDE8CC),
    textAccent: const Color(0xFF8A9E5C),
    textMuted: const Color(0x70DDE8CC),
    christAccent: const Color(0xFFB0CC80),
    navColor: const Color(0xFF8A9E5C),
    bodyFont: (sz) => GoogleFonts.spectral(
      fontSize: sz,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    ),
    brightness: Brightness.dark,
    verseFontSize: 20,
    verseLineHeight: 1.85,
    verseTracking: 0.20,
    navRadius: 999,
    verseNumOpacity: 0.82,
    chapterlessFont: (sz) => GoogleFonts.lora(fontSize: sz, fontWeight: FontWeight.w600),
    chapterlessFontSize: 20,
    chapterlessLineHeight: 2.10,
    chapterlessTracking: 0.10,
    chapterlessPadding: 40,
  );

  // ── Parchment ─────────────────────────────────────────────────────────────
  // Book of Hours. Warm cream with dark ink. Crimson Text w600 — the slightly
  // heavier weight gives it that printed-book authority on a light background.
  static final parchment = AbideThemeData(
    bgApp: const Color(0xFFF5EFE0),
    bgMenu: const Color(0xFFEDE4D0),
    surface: const Color(0xFFFAF5EA),
    textPrimary: const Color(0xFF1A1108),
    textAccent: const Color(0xFF9B6B3C),
    textMuted: const Color(0x803C2A1A),
    christAccent: const Color(0xFF7A2318),
    navColor: const Color(0xFFC8983A),
    bodyFont: (sz) => GoogleFonts.crimsonText(
      fontSize: sz,
      fontWeight: FontWeight.w600,
    ),
    brightness: Brightness.light,
    verseFontSize: 22,
    verseLineHeight: 1.80,
    verseTracking: 0.05,
    navRadius: 999,
    verseNumOpacity: 0.95,
    chapterlessFont: (sz) => GoogleFonts.lora(fontSize: sz, fontWeight: FontWeight.w400),
    chapterlessFontSize: 21,
    chapterlessLineHeight: 2.00,
    chapterlessTracking: 0.05,
    chapterlessPadding: 44,
  );

  static AbideThemeData fromKey(String key) => switch (key) {
        'still-waters' => stillWaters,
        'stone-fire' => stoneFire,
        'olive-parchment' => oliveAndParchment,
        'parchment' => parchment,
        _ => classic,
      };
}
