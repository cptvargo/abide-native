import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../theme/abide_theme.dart';

/// Embedded YouTube player on mobile; thumbnail fallback on Windows.
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

  bool get _supportsEmbed =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_supportsEmbed) {
      _ctrl = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: widget.autoPlay,
        params: YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          playsInline: false,
          showVideoAnnotations: false,
          enableCaption: false,
          pointerEvents: PointerEvents.auto,
          color: 'white',
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AbideThemeData>()!;

    Widget player;
    if (_supportsEmbed && _ctrl != null) {
      player = YoutubePlayer(controller: _ctrl!);
    } else {
      player = _ThumbnailFallback(
          videoId: widget.videoId, theme: theme);
    }

    if (widget.roundedCorners) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(aspectRatio: 16 / 9, child: player),
      );
    }
    return AspectRatio(aspectRatio: 16 / 9, child: player);
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.videoId, required this.theme});
  final String videoId;
  final AbideThemeData theme;

  Future<void> _openBrowser() async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openBrowser,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _a, _b) => Container(
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
