import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../theme/abide_theme.dart';

/// Embedded YouTube player using the IFrame API with a declared origin so
/// YouTube authorizes the embed. Falls back to "Watch on YouTube" on Windows
/// or on error.
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
  YoutubePlayerController? _ctrl;
  StreamSubscription<YoutubePlayerValue>? _sub;
  bool _hasError = false;

  bool get _supportsEmbed =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_supportsEmbed) {
      _ctrl = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: widget.autoPlay,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          playsInline: false,
          showVideoAnnotations: false,
          enableCaption: false,
          pointerEvents: PointerEvents.auto,
          color: 'white',
          // Sets origin + widget_referrer in the IFrame API call so YouTube
          // authorizes the embed (equivalent to the Referer header fix).
          origin: 'https://jvstudios.app',
        ),
      );
      _sub = _ctrl!.listen((value) {
        if (value.hasError && !_hasError && mounted) {
          setState(() => _hasError = true);
          _sub?.cancel();
          _ctrl?.close();
          _ctrl = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ctrl?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    Widget content;
    if (!_supportsEmbed || _hasError || _ctrl == null) {
      content = _ThumbnailFallback(videoId: widget.videoId, theme: theme);
    } else {
      content = YoutubePlayer(controller: _ctrl!);
    }

    final player = AspectRatio(aspectRatio: 16 / 9, child: content);
    if (widget.roundedCorners) {
      return ClipRRect(borderRadius: BorderRadius.circular(14), child: player);
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
