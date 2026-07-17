import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 1;
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  late final AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  // Classic palette — always used here regardless of user's theme
  static const _bg = Color(0xFF1C1C1A);
  static const _text = Color(0xFFEEECE6);
  static const _accent = Color(0xFFCBB27C);
  static const _muted = Color(0xFFB8B6AE);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _buildAnims();
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _buildAnims() {
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  Future<void> _goTo(int step) async {
    await _animCtrl.reverse();
    setState(() => _step = step);
    _buildAnims();
    _animCtrl.forward();
    if (step == 2) {
      Future.delayed(const Duration(milliseconds: 300),
          () => _nameFocus.requestFocus());
    }
  }

  Future<void> _submitName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('abide_name', name);
    _goTo(3);
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('abide_onboarded', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _step == 1
                      ? _buildWelcome()
                      : _step == 2
                          ? _buildName()
                          : _buildStewardship(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Welcome ────────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/ABIDE.png',
          width: 180,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 40),
        const Text(
          'Welcome to ABIDE.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: _text,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'A quiet place to remain in Christ\nthrough His Word.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: _muted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 48),
        _Button(label: 'Begin', onTap: () => _goTo(2)),
      ],
    );
  }

  // ── Step 2: Name ───────────────────────────────────────────────────────────

  Widget _buildName() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'What shall we call you?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Crimson Pro',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: _text,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameCtrl,
          focusNode: _nameFocus,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            fontSize: 18,
            color: _text,
          ),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: 'First name',
            hintStyle: TextStyle(color: _accent.withValues(alpha: 0.45)),
            filled: true,
            fillColor: _accent.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _submitName(),
        ),
        const SizedBox(height: 28),
        ValueListenableBuilder(
          valueListenable: _nameCtrl,
          builder: (_, val, __) => _Button(
            label: 'Continue',
            onTap: val.text.trim().isNotEmpty ? _submitName : null,
          ),
        ),
      ],
    );
  }

  // ── Step 3: Stewardship ────────────────────────────────────────────────────

  Widget _buildStewardship() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'A Note on Stewardship',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Crimson Pro',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: _text,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _para(
          'Greetings, my name is Jesus Vargas, owner of ABIDE. '
          'This app is built with a commitment to integrity and accountability.',
        ),
        _para(
          'ABIDE includes two translations of Scripture. The King James Version '
          '(KJV) stands as the historic foundation. The ASR (ABIDE Source Reading) '
          'is rooted in the Berean Standard Bible — a translation that reads with '
          'clarity and warmth — with careful additions from the Textus Receptus '
          'where I felt meaning present in the original text was underrepresented.',
        ),
        _para(
          'The Seek feature draws from Strong\'s Concordance and uses AI to '
          'help surface word meanings rooted in the original languages. '
          'Chapter Reflections are AI-assisted prompts designed to engage '
          'thoughtful meditation on what you have read.',
        ),
        _para(
          'AI does not replace the Holy Spirit. We go to God for revelation '
          'through His Word — the Spirit is the teacher, not the tool. '
          'Reflections are an invitation to engage, not declarations of '
          'revelation. There may be writings within this app that were '
          'assisted by AI, but none of them are the inspiration of the '
          'Holy Spirit. That belongs to Scripture alone.',
        ),
        _para(
          'My prayer is that this app would bless you and help you remain '
          'in Christ.',
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            '"Abide in Me, and I in you."  — John 15:4',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: _accent,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Center(child: _Button(label: 'Enter Scripture', onTap: _complete)),
      ],
    );
  }

  Widget _para(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: _muted,
            height: 1.75,
          ),
        ),
      );
}

// ── Shared button ─────────────────────────────────────────────────────────────

class _Button extends StatefulWidget {
  const _Button({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  bool _pressed = false;

  static const _accent = Color(0xFFCBB27C);
  static const _bg = Color(0xFF1C1C1A);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? _accent : _accent.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: enabled ? _bg : _bg.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
