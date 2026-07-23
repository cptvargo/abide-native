import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/abide_theme.dart';

/// Plays a YouTube video inline via a WebView embed URL (same approach as the PWA).
/// Falls back to a thumbnail + "Watch on YouTube" button on Windows or on error.
class YoutubePlayerCard extends StatefulWidget {
  const YoutubePlayerCard({
    super.key,
    required this.videoId,
    this.autoPlay = false,
    this.roundedCorners = true,
  });
  final String videoId;
  final bool autoPlay;
  final bool roundedCorners;

  @override
  State<YoutubePlayerCard> createState() => _YoutubePlayerCardState();
}

class _YoutubePlayerCardState extends State<YoutubePlayerCard> {
  WebViewController? _ctrl;
  bool _hasError = false;

  bool get _supportsWebView =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_supportsWebView) {
      final autoplay = widget.autoPlay ? 1 : 0;
      final embedUrl =
          'https://www.youtube.com/embed/${widget.videoId}'
          '?autoplay=$autoplay&rel=0&playsinline=0&modestbranding=1';

      // Use a mobile browser UA so YouTube treats this the same as a browser
      // iframe (matches what the PWA does). Without this, YouTube may block
      // the embed with error 150/152 in native WebViews.
      final ua = Platform.isIOS
          ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
              'AppleWebKit/605.1.15 (KHTML, like Gecko) '
              'Version/17.0 Mobile/15E148 Safari/604.1'
          : 'Mozilla/5.0 (Linux; Android 10; K) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/124.0.0.0 Mobile Safari/537.36';

      _ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(ua)
        ..setNavigationDelegate(NavigationDelegate(
          onWebResourceError: (_) {
            if (mounted && !_hasError) setState(() => _hasError = true);
          },
        ))
        ..loadRequest(Uri.parse(embedUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    Widget content;
    if (!_supportsWebView || _hasError || _ctrl == null) {
      content = _ThumbnailFallback(videoId: widget.videoId, theme: theme);
    } else {
      content = WebViewWidget(controller: _ctrl!);
    }

    final player = AspectRatio(aspectRatio: 16 / 9, child: content);

    if (widget.roundedCorners) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: player,
      );
    }
    return player;
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.videoId, required this.theme});
  final String videoId;
  final AbideThemeData theme;

  Future<void> _openYouTube() async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', uri.toString()]);
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openYouTube,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => Container(
              color: theme.textAccent.withValues(alpha: 0.08),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 12,
            child: Text(
              'Watch on YouTube',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
