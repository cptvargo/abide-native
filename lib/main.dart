import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/abide_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/scripture_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AbideApp());
}

class AbideApp extends StatefulWidget {
  const AbideApp({super.key});

  @override
  State<AbideApp> createState() => _AbideAppState();
}

class _AbideAppState extends State<AbideApp> {
  String _themeKey = 'classic';
  double _textScale = 1.0;
  bool _chapterlessMode = false;
  bool? _isOnboarded; // null = loading

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeKey = prefs.getString('themeKey') ?? 'classic';
      _textScale = prefs.getDouble('textScale') ?? 1.0;
      _chapterlessMode = prefs.getBool('chapterlessMode') ?? false;
      _isOnboarded = prefs.getBool('abide_onboarded') ?? false;
    });
  }

  Future<void> _setTheme(String key) async {
    setState(() => _themeKey = key);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeKey', key);
  }

  Future<void> _setTextScale(double v) async {
    setState(() => _textScale = v);
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('textScale', v);
  }

  Future<void> _setChapterlessMode(bool v) async {
    setState(() => _chapterlessMode = v);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('chapterlessMode', v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AbideThemes.fromKey(_themeKey);

    return MaterialApp(
      title: 'ABIDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: theme.brightness,
        scaffoldBackgroundColor: theme.bgApp,
        extensions: [theme],
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: _isOnboarded == null
          ? const Scaffold(backgroundColor: Color(0xFF1C1C1A))
          : !_isOnboarded!
              ? OnboardingScreen(
                  onComplete: () => setState(() => _isOnboarded = true))
              : AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.isLight
            ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: AbideShell(
          themeKey: _themeKey,
          onThemeChanged: _setTheme,
          textScale: _textScale,
          onTextScaleChanged: _setTextScale,
          chapterlessMode: _chapterlessMode,
          onChapterlessModeChanged: _setChapterlessMode,
        ),
      ),
    );
  }
}


class AbideShell extends StatefulWidget {
  const AbideShell({
    super.key,
    required this.themeKey,
    required this.onThemeChanged,
    required this.textScale,
    required this.onTextScaleChanged,
    required this.chapterlessMode,
    required this.onChapterlessModeChanged,
  });

  final String themeKey;
  final ValueChanged<String> onThemeChanged;
  final double textScale;
  final ValueChanged<double> onTextScaleChanged;
  final bool chapterlessMode;
  final ValueChanged<bool> onChapterlessModeChanged;

  @override
  State<AbideShell> createState() => _AbideShellState();
}

class _AbideShellState extends State<AbideShell> {
  NavTab _tab = NavTab.home;
  final _navVisible = ValueNotifier<bool>(true);
  int _settingsResetKey = 0;

  @override
  void dispose() {
    _navVisible.dispose();
    super.dispose();
  }

  void _onTap(NavTab t) {
    // Scripture hides the nav; restore it when leaving — unless we're going to
    // journal, which manages its own nav visibility.
    if (_tab == NavTab.scripture && t != NavTab.scripture && t != NavTab.journal) {
      _navVisible.value = true;
    }
    setState(() {
      if (t == NavTab.settings && _tab != NavTab.settings) _settingsResetKey++;
      _tab = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    return Scaffold(
      backgroundColor: theme.bgApp,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab.index,
            children: [
              const HomeScreen(),
              ScriptureScreen(
                showNav: false,
                navVisible: _navVisible,
                textScale: widget.textScale,
                chapterlessMode: widget.chapterlessMode,
              ),
              JournalScreen(
                navVisible: _navVisible,
                isActive: _tab == NavTab.journal,
                onSwitchToScripture: () => _onTap(NavTab.scripture),
              ),
              const SearchScreen(),
              SettingsScreen(
                resetKey: _settingsResetKey,
                themeKey: widget.themeKey,
                onThemeChanged: widget.onThemeChanged,
                textScale: widget.textScale,
                onTextScaleChanged: widget.onTextScaleChanged,
                chapterlessMode: widget.chapterlessMode,
                onChapterlessModeChanged: widget.onChapterlessModeChanged,
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _navVisible,
              builder: (ctx, visible, _) => AbideBottomNav(
                current: _tab,
                visible: visible,
                onTap: _onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

