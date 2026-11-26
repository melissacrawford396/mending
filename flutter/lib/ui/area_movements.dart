import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import '../domain/effective.dart';
import '../domain/movement_type.dart';
import '../domain/my_exercise.dart';
import '../domain/readiness.dart';
import '../state/app_model.dart';
import '../state/mending_scope.dart';
import 'movement_page.dart';
import 'theme.dart';

/// Movements for [area], starred first, then catalog order.
List<MovementType> sortedForArea(AppModel model, BodyArea area) {
  final movements = model.catalog.forArea(area);
  final starred = [
    for (final movement in movements)
      if (model.findExercise(movement.name)?.starred ?? false) movement,
  ];
  return [
    ...starred,
    for (final movement in movements)
      if (!starred.contains(movement)) movement,
  ];
}

/// The side panel on the Body tab.
///
/// With [area] null it shows a hint. With [active] false the list is a
/// greyed preview that does not take taps.
class AreaMovementsPanel extends StatelessWidget {
  const AreaMovementsPanel({
    super.key,
    required this.area,
    required this.active,
    this.onClose,
  });

  final BodyArea? area;
  final bool active;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final area = this.area;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: active ? mendingBlue : mendingInk.withValues(alpha: 0.18),
          width: 2,
        ),
      ),
      child: area == null
          ? const _Hint()
          : _AreaList(area: area, active: active, onClose: onClose),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Point at a body part to see its movements.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mendingInk.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _AreaList extends StatelessWidget {
  const _AreaList({required this.area, required this.active, this.onClose});

  final BodyArea area;
  final bool active;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final movements = sortedForArea(model, area);
    final list = movements.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No movements for ${area.label} yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: mendingInk, fontSize: 16),
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: movements.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _MovementTile(movement: movements[index], active: active),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  area.label,
                  style: TextStyle(
                    color: active ? mendingBlue : mendingInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (active && onClose != null)
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        if (!active)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Click to choose',
              style: TextStyle(color: mendingInk.withValues(alpha: 0.55)),
            ),
          ),
        Expanded(
          child: active
              ? list
              : IgnorePointer(child: Opacity(opacity: 0.45, child: list)),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement, required this.active});

  final MovementType movement;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final exercise = model.findExercise(movement.name);
    final starred = exercise?.starred ?? false;
    final sets = effectiveSets(movement, exercise);
    final reps = effectiveReps(movement, exercise);
    final cooldown = effectiveCooldown(movement, exercise);
    final status = starred
        ? exerciseStatus(
            now: model.now(),
            completedAt: latestCompletionAt(
              model.completions,
              currentUser,
              movement.name,
            ),
            cooldownDays: cooldown,
          ).label
        : null;
    final starIcon = Icon(
      starred ? Icons.star_rounded : Icons.star_border_rounded,
      color: starred ? mendingBlue : mendingInk,
    );
    return ListTile(
      title: Text(
        movement.name,
        style: const TextStyle(color: mendingInk, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        status == null
            ? prescription(sets, reps, cooldown)
            : '${prescription(sets, reps, cooldown)}\n$status',
      ),
      isThreeLine: status != null,
      trailing: active
          ? IconButton(
              tooltip: starred ? 'Unstar' : 'Star',
              onPressed: () => model.setStarred(movement, !starred),
              icon: starIcon,
            )
          : Padding(padding: const EdgeInsets.all(8), child: starIcon),
      onTap: active
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MovementPage(movement: movement),
              ),
            )
          : null,
    );
  }
}
