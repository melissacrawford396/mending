import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/ui/movement_visual_view.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_catalog.dart';

class FakeVideoPlatform extends VideoPlayerPlatform {
  var playing = false;
  Duration position = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final events = StreamController<VideoEvent>()
      ..add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 8),
          size: const Size(720, 720),
        ),
      );
    return events.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> play(int playerId) async => playing = true;

  @override
  Future<void> pause(int playerId) async => playing = false;

  @override
  Future<void> seekTo(int playerId, Duration to) async => position = to;

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose(int playerId) async {}
}

void main() {
  testWidgets('the clip starts paused and plays from the controls', (
    tester,
  ) async {
    final platform = FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovementVisualView(visual: testCatalog.visualFor('arch-roll')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(platform.playing, isFalse);
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('0:00 / 0:08'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump();
    expect(platform.playing, isTrue);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump();
    expect(platform.playing, isFalse);
    expect(find.byTooltip('Play'), findsOneWidget);
  });
}
