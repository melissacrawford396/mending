import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/effective.dart';
import '../domain/movement_type.dart';
import '../domain/my_exercise.dart';
import '../domain/readiness.dart';
import '../state/mending_scope.dart';
import 'body_area_icon.dart';
import 'movement_page.dart';
import 'theme.dart';

class WorkingPage extends StatefulWidget {
  const WorkingPage({super.key});

  @override
  State<WorkingPage> createState() => _WorkingPageState();
}

enum _Arrival { grey, notice, leaving, arriving }

class _WorkingPageState extends State<WorkingPage> {
  Timer? _ticker;

  /// The movement just finished in a session. It shows as done in Ready
  /// first, then moves to the bottom of Waiting.
  String? _arrivingId;
  var _notice = false;
  var _moved = false;
  final _arrivalTimers = <Timer>[];
  final _arrivingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = MendingScope.of(context).justCompletedId;
    if (id != null && id != _arrivingId) _startArrival(id);
  }

  void _startArrival(String id) {
    for (final timer in _arrivalTimers) {
      timer.cancel();
    }
    _arrivalTimers
      ..clear()
      ..add(
        Timer(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() => _notice = true);
        }),
      )
      ..add(
        Timer(const Duration(milliseconds: 2800), () {
          if (!mounted) return;
          setState(() => _moved = true);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _revealArriving(const Duration(milliseconds: 1100)),
          );
        }),
      )
      ..add(
        Timer(const Duration(milliseconds: 4200), () {
          if (!mounted) return;
          setState(() => _arrivingId = null);
          MendingScope.of(context).clearJustCompleted();
        }),
      );
    _arrivingId = id;
    _notice = false;
    _moved = false;
  }

  /// Scrolls so the row growing into Waiting is on screen. It runs again once
  /// the row has reached full height.
  void _revealArriving(Duration duration) {
    final target = _arrivingKey.currentContext;
    if (!mounted || target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: duration,
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final timer in _arrivalTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final ready = <_WorkRow>[];
    final waiting = <_WorkRow>[];
    for (final exercise in model.exercises) {
      if (!exercise.starred || exercise.user != currentUser) continue;
      final movement = model.catalog.find(exercise.movementId);
      if (movement == null) continue;
      final times = completionTimes(
        model.completions,
        currentUser,
        movement.id,
      );
      final completedAt = latestCompletionAt(
        model.completions,
        currentUser,
        movement.id,
      );
      final status = exerciseStatus(
        now: model.now(),
        completedTimes: times,
        cooldown: effectiveCooldown(movement, exercise),
      );
      final row = _WorkRow(
        movement: movement,
        exercise: exercise,
        status: status,
        completedAt: completedAt,
      );
      if (status.ready) {
        ready.add(row);
      } else {
        waiting.add(row);
      }
    }
    waiting.sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
    final arrivingIndex = waiting.indexWhere(
      (row) => row.movement.id == _arrivingId,
    );
    if (arrivingIndex >= 0) {
      final row = waiting[arrivingIndex];
      if (_moved) {
        ready.add(row.withArrival(_Arrival.leaving));
        waiting[arrivingIndex] = row.withArrival(_Arrival.arriving);
      } else {
        waiting.removeAt(arrivingIndex);
        ready.add(row.withArrival(_notice ? _Arrival.notice : _Arrival.grey));
      }
    }
    ready.sort(
      (a, b) => model.catalog
          .indexOf(a.movement.id)
          .compareTo(model.catalog.indexOf(b.movement.id)),
    );

    if (ready.isEmpty && waiting.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nothing starred yet. Choose a body area and star a movement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mendingInk, fontSize: 16),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (ready.isNotEmpty) ...[
          const _SectionTitle('Ready'),
          for (final row in ready) _AnimatedWorkTile(row: row),
        ],
        if (waiting.isNotEmpty) ...[
          const _SectionTitle('Waiting'),
          for (final row in waiting)
            _AnimatedWorkTile(
              key: row.arrival == _Arrival.arriving ? _arrivingKey : null,
              row: row,
            ),
        ],
      ],
    );
  }
}

class _WorkRow {
  const _WorkRow({
    required this.movement,
    required this.exercise,
    required this.status,
    required this.completedAt,
    this.arrival,
  });

  final MovementType movement;
  final MyExercise exercise;
  final ExerciseStatus status;
  final DateTime? completedAt;
  final _Arrival? arrival;

  _WorkRow withArrival(_Arrival arrival) => _WorkRow(
    movement: movement,
    exercise: exercise,
    status: status,
    completedAt: completedAt,
    arrival: arrival,
  );
}

/// Collapses out of Ready, or grows into Waiting with a fading highlight.
class _AnimatedWorkTile extends StatelessWidget {
  const _AnimatedWorkTile({super.key, required this.row});

  final _WorkRow row;

  @override
  Widget build(BuildContext context) {
    final id = row.movement.id;
    switch (row.arrival) {
      case null:
        return _WorkTile(key: ValueKey(id), row: row);
      case _Arrival.grey:
      case _Arrival.notice:
        return _FadedHold(
          key: ValueKey(id),
          message: row.arrival == _Arrival.notice,
          child: _WorkTile(row: row, done: true),
        );
      case _Arrival.leaving:
        return TweenAnimationBuilder<double>(
          key: ValueKey('leaving-$id'),
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInCubic,
          builder: (context, t, child) => ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: t,
              child: Opacity(opacity: t, child: child),
            ),
          ),
          child: _WorkTile(row: row, highlight: 1, done: true),
        );
      case _Arrival.arriving:
        return TweenAnimationBuilder<double>(
          key: ValueKey('arriving-$id'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: t,
              child: Opacity(
                opacity: t,
                child: _WorkTile(row: row, highlight: 1 - t),
              ),
            ),
          ),
        );
    }
  }
}

/// Greys the finished row, then hovers "Move to waiting" over that spot.
class _FadedHold extends StatelessWidget {
  const _FadedHold({super.key, required this.message, required this.child});

  final bool message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.45,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.color),
            child: child,
          ),
        ),
        if (message)
          Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Move to waiting',
                style: TextStyle(
                  color: mendingInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: mendingInk,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _WorkTile extends StatelessWidget {
  const _WorkTile({
    super.key,
    required this.row,
    this.highlight = 0,
    this.done = false,
  });

  final _WorkRow row;

  /// 0 is plain white, 1 is a full blue wash.
  final double highlight;

  /// Shows "Done" in place of the countdown.
  final bool done;

  @override
  Widget build(BuildContext context) {
    final sets = effectiveSets(row.movement, row.exercise);
    final reps = effectiveReps(row.movement, row.exercise);
    final cooldown = effectiveCooldown(row.movement, row.exercise);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Color.lerp(
          Colors.white,
          const Color(0xFFDCE7FD),
          highlight.clamp(0.0, 1.0),
        ),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MovementPage(movement: row.movement),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                BodyAreaIcon(area: row.movement.area, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.movement.name,
                        style: const TextStyle(
                          color: mendingInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${row.movement.area.label} · ${prescription(sets, reps, cooldown, seconds: row.movement.timed)}',
                        style: TextStyle(
                          color: mendingInk.withValues(alpha: 0.72),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (done)
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: mendingBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: mendingBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          row.status.label,
                          style: TextStyle(
                            color: row.status.ready ? mendingBlue : mendingInk,
                            fontWeight: FontWeight.w800,
                          ),
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
