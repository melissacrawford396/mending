import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/effective.dart';
import '../domain/movement_type.dart';
import '../domain/my_exercise.dart';
import '../domain/readiness.dart';
import '../state/mending_scope.dart';
import 'movement_page.dart';
import 'theme.dart';

class WorkingPage extends StatefulWidget {
  const WorkingPage({super.key});

  @override
  State<WorkingPage> createState() => _WorkingPageState();
}

class _WorkingPageState extends State<WorkingPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final ready = <_WorkRow>[];
    final waiting = <_WorkRow>[];
    for (final exercise in model.exercises) {
      if (!exercise.starred || exercise.user != currentUser) continue;
      final movement = model.catalog.find(exercise.movementName);
      if (movement == null) continue;
      final completedAt = latestCompletionAt(
        model.completions,
        currentUser,
        movement.name,
      );
      final cooldown = effectiveCooldown(movement, exercise);
      final status = exerciseStatus(
        now: model.now(),
        completedAt: completedAt,
        cooldownDays: cooldown,
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
    ready.sort(
      (a, b) => model.catalog
          .indexOf(a.movement.name)
          .compareTo(model.catalog.indexOf(b.movement.name)),
    );
    waiting.sort((a, b) {
      final aAt = readyAt(
        a.completedAt,
        effectiveCooldown(a.movement, a.exercise),
      )!;
      final bAt = readyAt(
        b.completedAt,
        effectiveCooldown(b.movement, b.exercise),
      )!;
      return aAt.compareTo(bAt);
    });

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
          for (final row in ready) _WorkTile(row: row),
        ],
        if (waiting.isNotEmpty) ...[
          const _SectionTitle('Waiting'),
          for (final row in waiting) _WorkTile(row: row),
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
  });

  final MovementType movement;
  final MyExercise exercise;
  final ExerciseStatus status;
  final DateTime? completedAt;
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
  const _WorkTile({required this.row});

  final _WorkRow row;

  @override
  Widget build(BuildContext context) {
    final sets = effectiveSets(row.movement, row.exercise);
    final reps = effectiveReps(row.movement, row.exercise);
    final cooldown = effectiveCooldown(row.movement, row.exercise);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
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
                  '${row.movement.area.label} · ${prescription(sets, reps, cooldown)}',
                  style: TextStyle(
                    color: mendingInk.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
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
        ),
      ),
    );
  }
}
