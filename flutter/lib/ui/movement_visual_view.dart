import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../domain/movement_visual.dart';
import 'theme.dart';

String assetFor(String repoPath) => 'assets/$repoPath';

/// The clip with play, pause, and a seek bar. Starts paused and loops once
/// playing. Shows the thumbnail until the clip loads, and the placeholder when
/// there is no clip or it fails to load.
class MovementVisualView extends StatefulWidget {
  const MovementVisualView({super.key, required this.visual});

  final MovementVisual visual;

  @override
  State<MovementVisualView> createState() => _MovementVisualViewState();
}

class _MovementVisualViewState extends State<MovementVisualView> {
  VideoPlayerController? _controller;
  var _ready = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MovementVisualView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visual.representation != widget.visual.representation) {
      _controller?.dispose();
      _controller = null;
      _ready = false;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final path = widget.visual.representation;
    if (path == null) return;
    final controller = VideoPlayerController.asset(assetFor(path));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted || _controller != controller) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted || _controller != controller) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final visual = widget.visual;
    final controller = _controller;
    final playable = _ready && controller != null;
    Widget picture;
    if (visual.representation == null ||
        (_failed && visual.thumbnail == null)) {
      picture = const _Placeholder();
    } else if (playable) {
      picture = _Clip(controller: controller, onToggle: _toggle);
    } else {
      picture = Image.asset(
        assetFor(visual.thumbnail!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _Placeholder(),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFE7ECF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mendingInk, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(aspectRatio: 1, child: picture),
                if (playable)
                  _Controls(controller: controller, onToggle: _toggle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Clip extends StatelessWidget {
  const _Clip({required this.controller, required this.onToggle});

  final VideoPlayerController controller;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.isPlaying
                ? const SizedBox.shrink()
                : const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 72,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black38)],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller, required this.onToggle});

  final VideoPlayerController controller;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: mendingInk, width: 2)),
      ),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 16, 2),
          child: Row(
            children: [
              IconButton(
                key: const Key('play-pause'),
                tooltip: value.isPlaying ? 'Pause' : 'Play',
                onPressed: onToggle,
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: mendingInk,
                ),
              ),
              Expanded(
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  colors: const VideoProgressColors(
                    playedColor: mendingBlue,
                    bufferedColor: Color(0xFFC9D3E6),
                    backgroundColor: Color(0xFFE7ECF5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_clock(value.position)} / ${_clock(value.duration)}',
                style: const TextStyle(
                  color: mendingInk,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _clock(Duration time) {
  final seconds = time.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.accessibility_new_rounded, size: 48, color: mendingInk),
        SizedBox(height: 8),
        Text(
          'Visual later',
          style: TextStyle(color: mendingInk, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// A small still of the movement for lists.
class MovementThumbnail extends StatelessWidget {
  const MovementThumbnail({super.key, required this.visual, this.size = 56});

  final MovementVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    final thumbnail = visual.thumbnail;
    const fallback = ColoredBox(
      color: Color(0xFFE7ECF5),
      child: Center(
        child: Icon(Icons.accessibility_new_rounded, color: mendingInk),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: thumbnail == null
            ? fallback
            : Image.asset(
                assetFor(thumbnail),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
