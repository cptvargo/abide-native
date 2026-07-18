import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show Rect;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/abide_theme.dart';

class VerseShareSheet extends StatefulWidget {
  const VerseShareSheet({
    super.key,
    required this.verseTexts,
    required this.ref,
    required this.translation,
    required this.theme,
  });

  final List<String> verseTexts;
  final String ref;
  final String translation;
  final AbideThemeData theme;

  @override
  State<VerseShareSheet> createState() => _VerseShareSheetState();
}

class _VerseShareSheetState extends State<VerseShareSheet> {
  final _cardKey = GlobalKey();
  bool _saving = false;

  Future<void> _shareImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    // Capture render box before any await so we don't use BuildContext after async gaps
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image');

      final bytes = byteData.buffer.asUint8List();
      final name = 'abide_verse_${DateTime.now().millisecondsSinceEpoch}.png';

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}${Platform.pathSeparator}$name');
        await file.writeAsBytes(bytes);
        if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', '', file.path]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [file.path]);
        } else {
          await Process.run('xdg-open', [file.path]);
        }
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'A verse from ABIDE',
          sharePositionOrigin: shareOrigin,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyText() async {
    final text =
        '"${widget.verseTexts.join(' ')}" — ${widget.ref} (${widget.translation.toUpperCase()})';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verse copied'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: t.bgMenu,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: t.subtleOutline, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: t.mutedIcon,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Card preview (scaled to fit screen, captured at full res)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              key: _cardKey,
              child: _ShareCard(
                verseTexts: widget.verseTexts,
                ref: widget.ref,
                translation: widget.translation,
                theme: t,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: _saving ? 'Sharing…' : 'Share Image',
                  icon: Icons.share_rounded,
                  primary: true,
                  theme: t,
                  onTap: _saving ? null : _shareImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  label: 'Copy Text',
                  icon: Icons.copy_rounded,
                  primary: false,
                  theme: t,
                  onTap: _copyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Share card widget (captured as PNG) ──────────────────────────────────────
// Layout mirrors the PWA's ShareAsImage.jsx exactly:
// logo → vertical rule ↓ → verse text → vertical rule ↑ → reference

// Per-theme dark palette (always dark even when app is in parchment/light mode)
const _shareColors = <String, _SharePalette>{
  '0xFFCBB27C': _SharePalette(bg: Color(0xFF1C1A14), accent: Color(0xFFCBB27C), text: Color(0xFFE8DCC8), sub: Color(0xFF9B8E6E)), // Classic
  '0xFF7ED0D8': _SharePalette(bg: Color(0xFF071E22), accent: Color(0xFF4AABB8), text: Color(0xFFD4E8EB), sub: Color(0xFF6A9FA8)), // Still Waters
  '0xFFF97316': _SharePalette(bg: Color(0xFF1A0A06), accent: Color(0xFFF97316), text: Color(0xFFFED7AA), sub: Color(0xFFB85A1A)), // Stone & Fire
  '0xFF8A9E5C': _SharePalette(bg: Color(0xFF1E1C14), accent: Color(0xFFB0A070), text: Color(0xFFE8E3D6), sub: Color(0xFF7E7850)), // Olive & Parchment
  '0xFF9B6B3C': _SharePalette(bg: Color(0xFF1C1A14), accent: Color(0xFF9B8055), text: Color(0xFFE8DCC8), sub: Color(0xFF7A6A48)), // Parchment
};

class _SharePalette {
  const _SharePalette({required this.bg, required this.accent, required this.text, required this.sub});
  final Color bg, accent, text, sub;
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.verseTexts,
    required this.ref,
    required this.translation,
    required this.theme,
  });

  final List<String> verseTexts;
  final String ref;
  final String translation;
  final AbideThemeData theme;

  @override
  Widget build(BuildContext context) {
    final key = '0x${theme.textAccent.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
    final p = _shareColors[key] ?? const _SharePalette(
      bg: Color(0xFF1C1A14), accent: Color(0xFFCBB27C),
      text: Color(0xFFE8DCC8), sub: Color(0xFF9B8E6E),
    );
    final verseText = '”${verseTexts.join(' ')}”';

    return Container(
      width: 600,
      color: p.bg,
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ABIDE logo
          Image.asset(
            'assets/images/ABIDE.png',
            width: 140,
            color: p.accent.withValues(alpha: 0.85),
            colorBlendMode: BlendMode.modulate,
          ),
          const SizedBox(height: 40),

          // Vertical rule — gradient down (accent → transparent)
          _VRule(topColor: Colors.transparent, bottomColor: p.accent),
          const SizedBox(height: 32),

          // Verse text — italic, centered
          Text(
            verseText,
            textAlign: TextAlign.center,
            style: theme.bodyFont(22).copyWith(
              color: p.text,
              height: 1.75,
              letterSpacing: 0.01,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          // Vertical rule — gradient up (accent → transparent)
          _VRule(topColor: p.accent, bottomColor: Colors.transparent),
          const SizedBox(height: 28),

          // Reference
          Text(
            ref,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.14,
              color: p.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _VRule extends StatelessWidget {
  const _VRule({required this.topColor, required this.bottomColor});
  final Color topColor, bottomColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.primary,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final AbideThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary
              ? theme.textAccent.withValues(alpha: onTap == null ? 0.08 : 0.14)
              : theme.subtleFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary
                ? theme.textAccent.withValues(alpha: 0.30)
                : theme.subtleOutline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16,
                color: primary ? theme.textAccent : theme.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primary ? theme.textAccent : theme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
