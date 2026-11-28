import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/completion.dart';
import '../state/mending_scope.dart';
import 'theme.dart';

/// A short "you did it" after a session. It stays until Back to list.
class CelebrationPage extends StatefulWidget {
  const CelebrationPage({
    super.key,
    required this.movementId,
    required this.movementName,
    required this.setReps,
  });

  final String movementId;
  final String movementName;
  final List<int> setReps;

  @override
  State<CelebrationPage> createState() => _CelebrationPageState();
}

class _CelebrationPageState extends State<CelebrationPage>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();
  var _left = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _back() {
    if (_left || !mounted) return;
    _left = true;
    final model = MendingScope.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    model.showArrival(widget.movementId);
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );
    final timed =
        MendingScope.of(context).catalog.find(widget.movementId)?.timed ??
        false;
    final summary = setsRepsLabel(widget.setReps, seconds: timed);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => CustomPaint(
                          size: const Size.square(220),
                          painter: _BurstPainter(_controller.value),
                        ),
                      ),
                      ScaleTransition(
                        scale: pop,
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 120,
                          color: mendingBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: [
                      Text(
                        '${widget.movementName} done',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: mendingInk,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        style: TextStyle(
                          color: mendingInk.withValues(alpha: 0.72),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _back,
                        child: const Text('Back to list'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dots that fly out from the center and fade.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final travel = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    const count = 12;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count;
      final distance = 60 + 45 * travel;
      final color = (i.isEven ? mendingBlue : const Color(0xFFFFB020))
          .withValues(alpha: fade);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        6 * (1 - 0.5 * travel),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// Fade into the celebration. Back to list returns to the Working list.
Route<void> celebrationRoute({
  required String movementId,
  required String movementName,
  required List<int> setReps,
}) {
  return PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => CelebrationPage(
      movementId: movementId,
      movementName: movementName,
      setReps: setReps,
    ),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
