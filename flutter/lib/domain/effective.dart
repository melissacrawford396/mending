import 'movement_type.dart';
import 'my_exercise.dart';

int effectiveSets(MovementType type, MyExercise? exercise) =>
    exercise?.setsOverride ?? type.defaultSets;

int effectiveReps(MovementType type, MyExercise? exercise) =>
    exercise?.repsOverride ?? type.defaultReps;

int effectiveCooldown(MovementType type, MyExercise? exercise) =>
    exercise?.cooldownOverride ?? type.defaultCooldown;

String prescription(int sets, int reps, int cooldownDays) {
  final setLabel = sets == 1 ? '1 set' : '$sets sets';
  final repLabel = reps == 1 ? '1 rep' : '$reps reps';
  final cooldownLabel = cooldownDays == 1
      ? 'every day'
      : 'every $cooldownDays days';
  return '$setLabel · $repLabel · $cooldownLabel';
}
