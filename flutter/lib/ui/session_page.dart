import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../domain/effective.dart';
import '../domain/movement_type.dart';
import '../state/mending_scope.dart';
import 'celebration_page.dart';
import 'movement_visual_view.dart';
import 'theme.dart';

/// Walks through the sets. Each set records its own rep count. Rest waits
/// until you continue. Leaving can save the sets already done, or log nothing.
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

class _SessionPageState extends State<SessionPage>
    with SingleTickerProviderStateMixin {
  var _set = 1;
  late int _reps;
  DateTime? _setStartedAt;
  final _doneReps = <int>[];
  DateTime? _restStartedAt;
  DateTime? _restEndsAt;
  var _restBudgetSeconds = 0;
  Ticker? _ticker;
  var _finishing = false;

  bool get _resting => _restEndsAt != null;

  @override
  void initState() {
    super.initState();
    _reps = widget.reps;
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  DateTime _now() => MendingScope.of(context).now();

  Future<void> _done() async {
    if (_finishing) return;
    if (_reps <= 0) {
      await _finish(List.of(_doneReps));
      return;
    }
    final recorded = [..._doneReps, _reps];
    if (_set < widget.sets) {
      setState(() => _doneReps.add(_reps));
      if (widget.restSeconds == 0) {
        setState(() {
          _set++;
          _reps = widget.reps;
        });
        return;
      }
      _startRest();
      return;
    }
    await _finish(recorded);
  }

  void _startRest() {
    final now = _now();
    setState(() {
      _restStartedAt = now;
      _restBudgetSeconds = widget.restSeconds;
      _restEndsAt = now.add(Duration(seconds: widget.restSeconds));
    });
    if (_ticker?.isActive != true) _ticker?.start();
  }

  void _addRest() {
    setState(() {
      _restEndsAt = _restEndsAt?.add(const Duration(seconds: 30));
      _restBudgetSeconds += 30;
    });
  }

  void _nextSet() {
    setState(() {
      _restStartedAt = null;
      _restEndsAt = null;
      _setStartedAt = null;
      _set++;
      _reps = widget.reps;
    });
  }

  int get _countStep => widget.movement.timed ? holdStepSeconds : 1;

  int get _countMax => widget.movement.timed ? maxHoldSeconds : maxReps;

  Duration _setElapsed() {
    _setStartedAt ??= _now();
    final elapsed = _now().difference(_setStartedAt!);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  Duration _remaining() {
    final end = _restEndsAt;
    if (end == null) return Duration.zero;
    final remaining = end.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration _elapsed() {
    final start = _restStartedAt;
    if (start == null) return Duration.zero;
    final elapsed = _now().difference(start);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Sets to keep if the session ends now. The set on screen counts when its
  /// stepper is above 0. A set already sent to rest is already recorded.
  List<int> _setsToSave() {
    if (_resting || _reps <= 0) return List.of(_doneReps);
    return [..._doneReps, _reps];
  }

  Future<void> _finish(List<int> setReps) async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.stop();
    if (setReps.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final model = MendingScope.of(context);
    await model.complete(
      movementId: widget.movement.id,
      sets: setReps.length,
      reps: setReps.first,
      setReps: setReps,
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      celebrationRoute(
        movementId: widget.movement.id,
        movementName: widget.movement.name,
        setReps: setReps,
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final saving = _setsToSave();
    final choice = await showDialog<_Leave>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End exercise?'),
        content: Text(
          saving.isEmpty
              ? 'Nothing is logged if you stop now.'
              : 'Save and finish keeps the sets you did. End logs nothing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Leave.stay),
            child: const Text('Keep going'),
          ),
          if (saving.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(_Leave.save),
              child: const Text('Save and finish'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Leave.end),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == _Leave.stay) return;
    if (choice == _Leave.end) {
      _ticker?.stop();
      Navigator.of(context).pop();
      return;
    }
    await _finish(saving);
  }

  @override
  Widget build(BuildContext context) {
    final resting = _resting;
    final restDone = resting && _remaining() == Duration.zero;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.movement.name)),
        body: resting ? _restView() : _setView(context),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: resting
                ? OutlinedButton(
                    onPressed: _nextSet,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(restDone ? 'Next set' : 'Skip rest'),
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
          _clock(_setElapsed().inSeconds),
          key: const Key('set-elapsed'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: mendingInk,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.movement.timed
              ? 'Hold ${restLabel(widget.reps)}'
              : (widget.reps == 1 ? 'Do 1 rep' : 'Do ${widget.reps} reps'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: mendingInk,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const Key('session-reps-remove'),
              onPressed: _reps > 0
                  ? () => setState(
                      () => _reps = (_reps - _countStep).clamp(0, _countMax),
                    )
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Text(
              widget.movement.timed ? restLabel(_reps) : '$_reps',
              style: const TextStyle(
                color: mendingInk,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              key: const Key('session-reps-add'),
              onPressed: _reps < _countMax
                  ? () => setState(
                      () => _reps = (_reps + _countStep).clamp(0, _countMax),
                    )
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _restView() {
    final remaining = _remaining();
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final progress = _restBudgetSeconds == 0
        ? 0.0
        : remaining.inMilliseconds / (_restBudgetSeconds * 1000);
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
                    _clock(seconds),
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
          const SizedBox(height: 16),
          Text(
            _clock(_elapsed().inSeconds),
            key: const Key('rest-elapsed'),
            style: TextStyle(
              color: mendingInk.withValues(alpha: 0.4),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextButton(
            key: const Key('add-rest'),
            onPressed: _addRest,
            child: const Text('Add 30s'),
          ),
          const SizedBox(height: 8),
          Text(
            'Next: set ${_set + 1} of ${widget.sets}',
            style: const TextStyle(color: mendingInk, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

String _clock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final rest = safe % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

enum _Leave { stay, save, end }
