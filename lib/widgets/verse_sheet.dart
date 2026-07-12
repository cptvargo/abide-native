import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/abide_theme.dart';

// ── Verse Reference Parser ─────────────────────────────────────────────────────

class _VerseRef {
  const _VerseRef({
    required this.bookSlug,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  });

  final String bookSlug;
  final int chapter;
  final int startVerse;
  final int endVerse;

  static _VerseRef? parse(String ref) {
    final m = RegExp(r'^([\w\s]+?)\s+(\d+):(\d+)(?:-(\d+))?$')
        .firstMatch(ref.trim());
    if (m == null) return null;
    final start = int.parse(m.group(3)!);
    return _VerseRef(
      bookSlug: m.group(1)!.toLowerCase().replaceAll(RegExp(r'\s+'), ''),
      chapter: int.parse(m.group(2)!),
      startVerse: start,
      endVerse: m.group(4) != null ? int.parse(m.group(4)!) : start,
    );
  }
}

// ── Book Slug → Asset Path ─────────────────────────────────────────────────────

String _assetSlug(String bookSlug, String translation) {
  // Normalize common aliases
  final slug = bookSlug == 'psalm' ? 'psalms'
      : bookSlug == 'songofsongs' ? 'songofsolomon'
      : bookSlug;
  // KJV names it differently
  if (translation == 'kjv' && slug == 'songofsolomon') return "solomon'ssong";
  return slug;
}

// ── Translation Preference ─────────────────────────────────────────────────────

Future<String> getActiveTranslation() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('translation') ?? 'asr';
}

Future<void> setActiveTranslation(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('translation', key.toLowerCase());
}

// ── Verse Text Loader ─────────────────────────────────────────────────────────

Future<String?> _loadVerseText(String reference, String translation) async {
  final ref = _VerseRef.parse(reference);
  if (ref == null) return null;
  final tl = translation.toLowerCase();

  try {
    final slug = _assetSlug(ref.bookSlug, tl);
    final path = 'assets/$tl/$slug/${ref.chapter}.json';
    final raw = await rootBundle.loadString(path);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final verses = data['verses'] as Map<String, dynamic>?;
    if (verses == null) return null;

    final texts = <String>[];
    for (var v = ref.startVerse; v <= ref.endVerse; v++) {
      final vData = verses['$v'];
      if (vData == null) continue;
      String text;
      if (vData is String) {
        text = vData;
      } else if (vData is Map) {
        if (vData['segments'] != null) {
          text = (vData['segments'] as List)
              .map((s) => (s as Map)['text'] as String? ?? '')
              .join(' ');
        } else {
          text = vData['text'] as String? ?? '';
        }
      } else {
        continue;
      }
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) texts.add(trimmed);
    }
    return texts.isEmpty ? null : texts.join(' ');
  } catch (_) {
    return null;
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

void showVerseSheet(BuildContext context, String reference) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _VerseSheetContent(reference: reference),
  );
}

// ── Sheet Widget ──────────────────────────────────────────────────────────────

class _VerseSheetContent extends StatefulWidget {
  const _VerseSheetContent({required this.reference});
  final String reference;

  @override
  State<_VerseSheetContent> createState() => _VerseSheetContentState();
}

class _VerseSheetContentState extends State<_VerseSheetContent> {
  String? _text;
  String _translationLabel = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final translation = await getActiveTranslation();
    final text = await _loadVerseText(widget.reference, translation);
    if (!mounted) return;
    setState(() {
      _translationLabel = translation.toUpperCase();
      _text = text;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.bgMenu,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 24),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.textAccent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28, 0, 28, bottom + 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference — uppercase accent
                  Text(
                    widget.reference.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: theme.textAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_loading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: theme.textAccent.withValues(alpha: 0.6),
                      ),
                    )
                  else ...[
                    // Translation badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.textAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: theme.textAccent.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _translationLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textAccent.withValues(alpha: 0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verse text
                    if (_text != null)
                      Text(
                        '"$_text"',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          height: 1.85,
                          fontStyle: FontStyle.italic,
                          color: theme.textPrimary.withValues(alpha: 0.88),
                        ),
                      )
                    else
                      Text(
                        'Open your Bible to ${widget.reference}.',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: theme.textPrimary.withValues(alpha: 0.4),
                          height: 1.6,
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
