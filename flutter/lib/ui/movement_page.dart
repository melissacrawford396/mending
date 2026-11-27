import 'package:flutter/material.dart';

import '../domain/effective.dart';
import '../domain/movement_type.dart';
import '../domain/my_exercise.dart';
import '../domain/readiness.dart';
import '../state/mending_scope.dart';
import 'theme.dart';
import 'movement_visual_view.dart';

class MovementPage extends StatelessWidget {
  const MovementPage({super.key, required this.movement});

  final MovementType movement;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final exercise =
        model.findExercise(movement.id) ?? MyExercise.from(movement);
    final sets = effectiveSets(movement, exercise);
    final reps = effectiveReps(movement, exercise);
    final cooldown = effectiveCooldown(movement, exercise);
    final completedAt = latestCompletionAt(
      model.completions,
      currentUser,
      movement.id,
    );
    final status = exerciseStatus(
      now: model.now(),
      completedAt: completedAt,
      cooldownDays: cooldown,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(movement.name),
        actions: [
          IconButton(
            tooltip: exercise.starred ? 'Unstar' : 'Star',
            onPressed: () => model.setStarred(movement, !exercise.starred),
            icon: Icon(
              exercise.starred ? Icons.star_rounded : Icons.star_border_rounded,
              color: exercise.starred ? mendingBlue : mendingInk,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          MovementVisualView(visual: model.catalog.visualFor(movement.id)),
          const SizedBox(height: 16),
          Text(
            movement.area.label,
            style: const TextStyle(
              color: mendingBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movement.description,
            style: const TextStyle(
              color: mendingInk,
              height: 1.4,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _CountEditor(
            label: 'Sets',
            value: sets,
            defaultValue: movement.defaultSets,
            overridden: exercise.setsOverride != null,
            addKey: const Key('sets-add'),
            onChanged: (value) {
              model.setOverrides(
                movement,
                sets: value == movement.defaultSets ? null : value,
                reps: exercise.repsOverride,
                cooldown: exercise.cooldownOverride,
              );
            },
          ),
          _CountEditor(
            label: 'Reps',
            value: reps,
            defaultValue: movement.defaultReps,
            overridden: exercise.repsOverride != null,
            addKey: const Key('reps-add'),
            onChanged: (value) {
              model.setOverrides(
                movement,
                sets: exercise.setsOverride,
                reps: value == movement.defaultReps ? null : value,
                cooldown: exercise.cooldownOverride,
              );
            },
          ),
          _CountEditor(
            label: 'Cooldown',
            value: cooldown,
            defaultValue: movement.defaultCooldown,
            unit: 'day',
            overridden: exercise.cooldownOverride != null,
            addKey: const Key('cooldown-add'),
            onChanged: (value) {
              model.setOverrides(
                movement,
                sets: exercise.setsOverride,
                reps: exercise.repsOverride,
                cooldown: value == movement.defaultCooldown ? null : value,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            status.label,
            style: TextStyle(
              color: status.ready ? mendingBlue : mendingInk,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (!status.ready) ...[
            const SizedBox(height: 4),
            Text(
              'Doing this now restarts the countdown.',
              style: TextStyle(color: mendingInk.withValues(alpha: 0.72)),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _markDone(context, sets: sets, reps: reps),
            child: const Text('Mark done'),
          ),
        ],
      ),
    );
  }

  Future<void> _markDone(
    BuildContext context, {
    required int sets,
    required int reps,
  }) async {
    final result = await showModalBottomSheet<_DoneInput>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _MarkDoneSheet(movementName: movement.name, sets: sets, reps: reps),
    );
    if (result == null || !context.mounted) return;
    await MendingScope.of(context).complete(
      movementId: movement.id,
      sets: result.sets,
      reps: result.reps,
    );
  }
}

class _CountEditor extends StatelessWidget {
  const _CountEditor({
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.overridden,
    required this.onChanged,
    required this.addKey,
    this.unit,
  });

  final String label;
  final int value;
  final int defaultValue;
  final bool overridden;
  final ValueChanged<int> onChanged;
  final Key addKey;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final valueText = unit == null
        ? '$value'
        : value == 1
        ? '1 $unit'
        : '$value ${unit}s';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: mendingInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  valueText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: mendingInk, fontSize: 16),
                ),
              ),
              IconButton(
                key: addKey,
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (overridden)
            TextButton(
              onPressed: () => onChanged(defaultValue),
              child: const Text('Use default'),
            ),
        ],
      ),
    );
  }
}

class _DoneInput {
  const _DoneInput({required this.sets, required this.reps});

  final int sets;
  final int reps;
}

class _MarkDoneSheet extends StatefulWidget {
  const _MarkDoneSheet({
    required this.movementName,
    required this.sets,
    required this.reps,
  });

  final String movementName;
  final int sets;
  final int reps;

  @override
  State<_MarkDoneSheet> createState() => _MarkDoneSheetState();
}

class _MarkDoneSheetState extends State<_MarkDoneSheet> {
  late int sets = widget.sets;
  late int reps = widget.reps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mark ${widget.movementName} done',
            style: const TextStyle(
              color: mendingInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _SheetCount(
            label: 'Sets',
            value: sets,
            onChanged: (value) => setState(() => sets = value),
          ),
          _SheetCount(
            label: 'Reps',
            value: reps,
            onChanged: (value) => setState(() => reps = value),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_DoneInput(sets: sets, reps: reps)),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCount extends StatelessWidget {
  const _SheetCount({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: mendingInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$value', style: const TextStyle(color: mendingInk, fontSize: 16)),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
