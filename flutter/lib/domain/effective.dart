import 'movement_type.dart';
import 'my_exercise.dart';

const maxSets = 10;
const maxReps = 50;
const maxRestSeconds = 300;
const maxGapHours = 12;

/// Most frequent step on the Cooldown scale.
const maxPerDay = 3;

/// Least frequent step on the Cooldown scale.
const maxCooldownDays = 7;

/// How often a movement can repeat. With [perDay] above 1, [days] is 1.
class Cooldown {
  /// Without [gapHours], the gap splits about 16 waking hours: 8 hours for
  /// twice a day, 4 for three times.
  const Cooldown({this.days = 1, this.perDay = 1, int? gapHours})
    : gapHours = gapHours ?? (perDay > 2 ? 4 : 8);

  /// Step [step] on the Cooldown scale. 0 is [maxPerDay] times a day and
  /// [lastStep] is every [maxCooldownDays] days.
  factory Cooldown.atStep(int step) {
    final s = step.clamp(0, lastStep);
    if (s < maxPerDay - 1) return Cooldown(perDay: maxPerDay - s);
    return Cooldown(days: s - (maxPerDay - 1) + 1);
  }

  static const lastStep = maxPerDay - 1 + maxCooldownDays - 1;

  final int days;
  final int perDay;
  final int gapHours;

  int get step => perDay > 1 ? maxPerDay - perDay : maxPerDay - 2 + days;

  /// "3x a day", "every day", or "every 2 days".
  String get frequency {
    if (perDay > 1) return '${perDay}x a day';
    return days == 1 ? 'every day' : 'every $days days';
  }

  String get label => perDay > 1 ? '$frequency, $gapHours h apart' : frequency;

  @override
  bool operator ==(Object other) =>
      other is Cooldown &&
      other.days == days &&
      other.perDay == perDay &&
      other.gapHours == gapHours;

  @override
  int get hashCode => Object.hash(days, perDay, gapHours);
}

int effectiveSets(MovementType type, MyExercise? exercise) =>
    (exercise?.setsOverride ?? type.defaultSets).clamp(1, maxSets);

int effectiveReps(MovementType type, MyExercise? exercise) =>
    (exercise?.repsOverride ?? type.defaultReps).clamp(1, maxReps);

int effectiveRest(MovementType type, MyExercise? exercise) =>
    (exercise?.restOverride ?? type.defaultRestSeconds).clamp(
      0,
      maxRestSeconds,
    );

Cooldown effectiveCooldown(MovementType type, MyExercise? exercise) {
  final perDay = (exercise?.perDayOverride ?? type.defaultPerDay).clamp(
    1,
    maxPerDay,
  );
  final days = (exercise?.cooldownOverride ?? type.defaultCooldown).clamp(
    1,
    maxCooldownDays,
  );
  return Cooldown(
    days: perDay > 1 ? 1 : days,
    perDay: perDay,
    gapHours: exercise?.gapHoursOverride?.clamp(1, maxGapHours),
  );
}

String prescription(int sets, int reps, Cooldown cooldown) {
  final setLabel = sets == 1 ? '1 set' : '$sets sets';
  final repLabel = reps == 1 ? '1 rep' : '$reps reps';
  return '$setLabel · $repLabel · ${cooldown.label}';
}

/// "30 s", "1 min", or "1 min 30 s".
String restLabel(int seconds) {
  if (seconds < 60) return '$seconds s';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return rest == 0 ? '$minutes min' : '$minutes min $rest s';
}
