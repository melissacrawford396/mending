import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/movement_type.dart';
import '../state/mending_scope.dart';
import 'celebration_page.dart';
import 'count_pips.dart';
import 'movement_visual_view.dart';
import 'theme.dart';

/// Walks through the sets: do the reps, rest, repeat. Logs one completion
/// after the last set. Leaving early logs nothing.
class SessionPage extends StatefulWidget {
  const SessionPage({
    super.key,
    required this.movement,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final MovementType movement;
  final int sets;
  final int reps;
  final int restSeconds;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  var _set = 1;
  DateTime? _restEndsAt;
  Timer? _ticker;
  var _finishing = false;

  bool get _resting => _restEndsAt != null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime _now() => MendingScope.of(context).now();

  Future<void> _done() async {
    if (_set < widget.sets) {
      if (widget.restSeconds == 0) {
        setState(() => _set++);
        return;
      }
      setState(
        () => _restEndsAt = _now().add(Duration(seconds: widget.restSeconds)),
      );
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        if (_remaining() <= Duration.zero) {
          _nextSet();
        } else {
          setState(() {});
        }
      });
      return;
    }
    if (_finishing) return;
    _finishing = true;
    final model = MendingScope.of(context);
    await model.complete(
      movementId: widget.movement.id,
      sets: widget.sets,
      reps: widget.reps,
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => CelebrationPage(
          movementId: widget.movement.id,
          movementName: widget.movement.name,
          sets: widget.sets,
          reps: widget.reps,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _nextSet() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _restEndsAt = null;
      _set++;
    });
  }

  Duration _remaining() {
    final end = _restEndsAt;
    if (end == null) return Duration.zero;
    return end.difference(_now());
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End exercise?'),
        content: const Text('Nothing is logged if you stop now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.movement.name)),
        body: _resting ? _restView() : _setView(context),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _resting
                ? OutlinedButton(
                    onPressed: _nextSet,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Skip rest'),
                  )
                : FilledButton(
                    key: const Key('set-done'),
                    onPressed: _done,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Done'),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _setView(BuildContext context) {
    final model = MendingScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Text(
          'Set $_set of ${widget.sets}',
          style: const TextStyle(
            color: mendingInk,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        MovementVisualView(visual: model.catalog.visualFor(widget.movement.id)),
        const SizedBox(height: 16),
        Text(
          widget.reps == 1 ? 'Do 1 rep' : 'Do ${widget.reps} reps',
          style: const TextStyle(
            color: mendingInk,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        CountPips(count: widget.reps, shape: PipShape.triangle, maxSize: 22),
      ],
    );
  }

  Widget _restView() {
    final remaining = _remaining();
    final seconds = (remaining.inMilliseconds / 1000).ceil().clamp(
      0,
      widget.restSeconds,
    );
    final progress = widget.restSeconds == 0
        ? 0.0
        : remaining.inMilliseconds / (widget.restSeconds * 1000);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Rest',
            style: TextStyle(
              color: mendingInk,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox.square(
            dimension: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 10,
                  color: mendingBlue,
                  backgroundColor: mendingBlue.withValues(alpha: 0.15),
                ),
                Center(
                  child: Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: mendingInk,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Next: set ${_set + 1} of ${widget.sets}',
            style: const TextStyle(color: mendingInk, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
