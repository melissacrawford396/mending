import 'movement_type.dart';
import 'my_exercise.dart';

const maxSets = 10;
const maxReps = 50;
const maxRestSeconds = 300;

/// Shortest and longest hold, and the step on a timed movement.
const minHoldSeconds = 5;
const maxHoldSeconds = 300;
const holdStepSeconds = 5;

/// Longest gap between repeats on the same day.
const maxSameDayGapHours = 12;

/// Longest gap the stepper allows. Same-day repeats stop at
/// [maxSameDayGapHours]. Every N days can run 12 hours past its default.
int maxGapHoursFor(int days, int perDay) =>
    perDay > 1 ? maxSameDayGapHours : (days - 1) * 24 + 18 + maxSameDayGapHours;

/// Most frequent step on the Cooldown scale.
const maxPerDay = 3;

/// Least frequent step on the Cooldown scale.
const maxCooldownDays = 7;

/// How often a movement can repeat. With [perDay] above 1, [days] is 1.
class Cooldown {
  /// Without [gapHours], twice a day waits 8 hours and three times a day waits
  /// 4. Every N days waits (N - 1) × 24 hours plus 18, counted from the last
  /// completion.
  const Cooldown({this.days = 1, this.perDay = 1, int? gapHours})
    : gapHours =
          gapHours ??
          (perDay > 2
              ? 4
              : perDay > 1
              ? 8
              : (days - 1) * 24 + 18);

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

/// Most sets the stepper allows. A circuit stops at the end of its walk.
int setCap(MovementType type) =>
    type.steps.isEmpty ? maxSets : type.walkSets.clamp(1, maxSets);

int effectiveSets(MovementType type, MyExercise? exercise) =>
    (exercise?.setsOverride ?? type.defaultSets).clamp(1, setCap(type));

int effectiveReps(MovementType type, MyExercise? exercise) {
  final value = exercise?.repsOverride ?? type.defaultReps;
  if (type.timed) return value.clamp(minHoldSeconds, maxHoldSeconds);
  return value.clamp(1, maxReps);
}

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
    gapHours: exercise?.gapHoursOverride?.clamp(
      1,
      maxGapHoursFor(days, perDay),
    ),
  );
}

String prescription(
  int sets,
  int reps,
  Cooldown cooldown, {
  bool seconds = false,
}) {
  final setLabel = sets == 1 ? '1 set' : '$sets sets';
  final repLabel = seconds
      ? restLabel(reps)
      : (reps == 1 ? '1 rep' : '$reps reps');
  return '$setLabel · $repLabel · ${cooldown.label}';
}

/// "30 s", "1 min", or "1 min 30 s".
String restLabel(int seconds) {
  if (seconds < 60) return '$seconds s';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return rest == 0 ? '$minutes min' : '$minutes min $rest s';
}
