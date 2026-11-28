import 'package:flutter/material.dart';

import '../domain/effective.dart';
import '../domain/movement_type.dart';
import '../domain/my_exercise.dart';
import '../domain/readiness.dart';
import '../state/app_model.dart';
import '../state/mending_scope.dart';
import 'celebration_page.dart';
import 'count_pips.dart';
import 'movement_visual_view.dart';
import 'session_page.dart';
import 'theme.dart';

class MovementPage extends StatelessWidget {
  const MovementPage({super.key, required this.movement});

  final MovementType movement;

  int? _override(int value, int defaultValue) =>
      value == defaultValue ? null : value;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final exercise =
        model.findExercise(movement.id) ?? MyExercise.from(movement);
    final sets = effectiveSets(movement, exercise);
    final reps = effectiveReps(movement, exercise);
    final rest = effectiveRest(movement, exercise);
    final cooldown = effectiveCooldown(movement, exercise);
    final defaults = effectiveCooldown(movement, null);
    final status = exerciseStatus(
      now: model.now(),
      completedTimes: completionTimes(
        model.completions,
        currentUser,
        movement.id,
      ),
      cooldown: cooldown,
    );

    void update(MyExercise Function(MyExercise row) change) =>
        model.updateExercise(movement, change);

    void setCooldown(int step) {
      final next = Cooldown.atStep(step);
      final isDefault =
          next.perDay == defaults.perDay && next.days == defaults.days;
      update(
        (row) => row.copyWith(
          perDayOverride: isDefault ? null : next.perDay,
          cooldownOverride: isDefault ? null : next.days,
          gapHoursOverride: null,
        ),
      );
    }

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
          FilledButton.icon(
            key: const Key('start-exercise'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SessionPage(
                  movement: movement,
                  sets: sets,
                  reps: reps,
                  restSeconds: rest,
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start exercise'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            movement.area.label,
            style: const TextStyle(
              color: mendingBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _CountRow(
            label: 'Sets',
            value: CountPips(count: sets, shape: PipShape.circle),
            canRemove: sets > 1,
            canAdd: sets < maxSets,
            overridden: exercise.setsOverride != null,
            addKey: const Key('sets-add'),
            onChanged: (delta) => update(
              (row) => row.copyWith(
                setsOverride: _override(sets + delta, movement.defaultSets),
              ),
            ),
            onReset: () => update((row) => row.copyWith(setsOverride: null)),
          ),
          _CountRow(
            label: movement.timed ? 'Hold' : 'Reps',
            value: movement.timed
                ? _ValueText(restLabel(reps))
                : CountPips(count: reps, shape: PipShape.triangle),
            canRemove: movement.timed ? reps > minHoldSeconds : reps > 1,
            canAdd: movement.timed ? reps < maxHoldSeconds : reps < maxReps,
            overridden: exercise.repsOverride != null,
            addKey: const Key('reps-add'),
            onChanged: (delta) => update(
              (row) => row.copyWith(
                repsOverride: _override(
                  movement.timed
                      ? (reps + delta * holdStepSeconds).clamp(
                          minHoldSeconds,
                          maxHoldSeconds,
                        )
                      : reps + delta,
                  movement.defaultReps,
                ),
              ),
            ),
            onReset: () => update((row) => row.copyWith(repsOverride: null)),
          ),
          _CountRow(
            label: 'Rest',
            value: _ValueText(restLabel(rest)),
            canRemove: rest > 0,
            canAdd: rest < maxRestSeconds,
            overridden: exercise.restOverride != null,
            addKey: const Key('rest-add'),
            onChanged: (delta) => update(
              (row) => row.copyWith(
                restOverride: _override(
                  (rest + delta * 5).clamp(0, maxRestSeconds),
                  movement.defaultRestSeconds,
                ),
              ),
            ),
            onReset: () => update((row) => row.copyWith(restOverride: null)),
          ),
          _CountRow(
            label: 'Cooldown',
            value: _ValueText(cooldown.frequency),
            canRemove: cooldown.step > 0,
            canAdd: cooldown.step < Cooldown.lastStep,
            overridden:
                exercise.cooldownOverride != null ||
                exercise.perDayOverride != null,
            addKey: const Key('cooldown-add'),
            removeKey: const Key('cooldown-remove'),
            onChanged: (delta) => setCooldown(cooldown.step + delta),
            onReset: () => update(
              (row) => row.copyWith(
                cooldownOverride: null,
                perDayOverride: null,
                gapHoursOverride: null,
              ),
            ),
          ),
          _CountRow(
            label: 'Gap',
            value: _ValueText('${cooldown.gapHours} h apart'),
            canRemove: cooldown.gapHours > 1,
            canAdd:
                cooldown.gapHours <
                maxGapHoursFor(cooldown.days, cooldown.perDay),
            overridden: exercise.gapHoursOverride != null,
            addKey: const Key('gap-add'),
            onChanged: (delta) => update(
              (row) => row.copyWith(
                gapHoursOverride: _override(
                  cooldown.gapHours + delta,
                  Cooldown(
                    days: cooldown.days,
                    perDay: cooldown.perDay,
                  ).gapHours,
                ),
              ),
            ),
            onReset: () =>
                update((row) => row.copyWith(gapHoursOverride: null)),
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
          Text(
            movement.description,
            style: const TextStyle(
              color: mendingInk,
              height: 1.4,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => _markDone(
              context,
              model,
              sets: sets,
              reps: reps,
              seconds: movement.timed,
            ),
            child: const Text('Mark done'),
          ),
        ],
      ),
    );
  }

  Future<void> _markDone(
    BuildContext context,
    AppModel model, {
    required int sets,
    required int reps,
    required bool seconds,
  }) async {
    final result = await showModalBottomSheet<_DoneInput>(
      context: context,
      showDragHandle: true,
      builder: (context) => _MarkDoneSheet(
        movementName: movement.name,
        sets: sets,
        reps: reps,
        seconds: seconds,
      ),
    );
    if (result == null || !context.mounted) return;
    await model.complete(
      movementId: movement.id,
      sets: result.sets,
      reps: result.reps,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      celebrationRoute(
        movementId: movement.id,
        movementName: movement.name,
        setReps: List<int>.filled(result.sets, result.reps),
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: mendingInk, fontSize: 16),
    );
  }
}

/// Label, a picture of the value, and a compact -/+ pair on the right.
class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.label,
    required this.value,
    required this.canRemove,
    required this.canAdd,
    required this.overridden,
    required this.onChanged,
    required this.onReset,
    required this.addKey,
    this.removeKey,
  });

  final String label;
  final Widget value;
  final bool canRemove;
  final bool canAdd;
  final bool overridden;
  final ValueChanged<int> onChanged;
  final VoidCallback onReset;
  final Key addKey;
  final Key? removeKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 108,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: mendingInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: value),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: removeKey,
                visualDensity: VisualDensity.compact,
                onPressed: canRemove ? () => onChanged(-1) : null,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                key: addKey,
                visualDensity: VisualDensity.compact,
                onPressed: canAdd ? () => onChanged(1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (overridden)
            TextButton(onPressed: onReset, child: const Text('Use default')),
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
    required this.seconds,
  });

  final String movementName;
  final int sets;
  final int reps;
  final bool seconds;

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
            max: maxSets,
            onChanged: (value) => setState(() => sets = value),
          ),
          _SheetCount(
            label: widget.seconds ? 'Hold' : 'Reps',
            value: reps,
            min: widget.seconds ? minHoldSeconds : 1,
            max: widget.seconds ? maxHoldSeconds : maxReps,
            step: widget.seconds ? holdStepSeconds : 1,
            seconds: widget.seconds,
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
    required this.max,
    required this.onChanged,
    this.min = 1,
    this.step = 1,
    this.seconds = false,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool seconds;
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
          onPressed: value > min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove),
        ),
        Text(
          seconds ? restLabel(value) : '$value',
          style: const TextStyle(color: mendingInk, fontSize: 16),
        ),
        IconButton(
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
