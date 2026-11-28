import '../data/catalog.dart';
import 'effective.dart';
import 'my_exercise.dart';

/// One line per movement: the sets and reps in use, in catalog order.
///
/// Paste this back to update the coded defaults. An override wins. A movement
/// you have not changed shows its current default.
String exerciseSettingsExport(
  MovementCatalog catalog,
  List<MyExercise> exercises,
) {
  final lines = <String>[];
  for (final movement in catalog.movements) {
    final row = _rowFor(exercises, movement.id);
    final sets = effectiveSets(movement, row);
    final reps = effectiveReps(movement, row);
    final setLabel = sets == 1 ? '1 set' : '$sets sets';
    final count = movement.timed
        ? restLabel(reps)
        : (reps == 1 ? '1 rep' : '$reps reps');
    lines.add('${movement.name} (${movement.id}): $setLabel, $count');
  }
  return lines.join('\n');
}

MyExercise? _rowFor(List<MyExercise> exercises, String id) {
  for (final exercise in exercises) {
    if (exercise.user == currentUser && exercise.movementId == id) {
      return exercise;
    }
  }
  return null;
}
