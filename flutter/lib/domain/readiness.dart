import 'completion.dart';
import 'effective.dart';

/// Local hour a new day starts. A completion before it counts as the day
/// before.
const dayStartHour = 4;

/// The 4 AM start of the day [time] belongs to, in local time.
DateTime dayStartOf(DateTime time) {
  final shifted = time.toLocal().subtract(const Duration(hours: dayStartHour));
  return DateTime(shifted.year, shifted.month, shifted.day, dayStartHour);
}

/// When the movement is ready again. Null when it has never been logged.
///
/// Every N days waits [Cooldown.gapHours] after the latest completion.
/// Two or three times a day also wait that gap, but once the day's limit is
/// reached they wait for the next 4 AM instead.
DateTime? readyAt(Iterable<DateTime> completedTimes, Cooldown cooldown) {
  DateTime? latest;
  for (final time in completedTimes) {
    if (latest == null || time.isAfter(latest)) latest = time;
  }
  if (latest == null) return null;
  final afterGap = latest.add(Duration(hours: cooldown.gapHours));
  if (cooldown.perDay <= 1) return afterGap;
  final day = dayStartOf(latest);
  final doneThatDay = completedTimes.where((t) => dayStartOf(t) == day).length;
  final reset = DateTime(
    day.year,
    day.month,
    day.day + cooldown.days,
    dayStartHour,
  );
  if (doneThatDay < cooldown.perDay) {
    return afterGap.isBefore(reset) ? afterGap : reset;
  }
  return reset;
}

bool isReady(
  DateTime now,
  Iterable<DateTime> completedTimes,
  Cooldown cooldown,
) {
  final at = readyAt(completedTimes, cooldown);
  if (at == null) return true;
  return !now.isBefore(at);
}

List<DateTime> completionTimes(
  Iterable<Completion> rows,
  String user,
  String movementId,
) {
  return [
    for (final row in rows)
      if (row.user == user && row.movementId == movementId) row.completedAt,
  ];
}

DateTime? latestCompletionAt(
  Iterable<Completion> rows,
  String user,
  String movementId,
) {
  DateTime? latest;
  for (final time in completionTimes(rows, user, movementId)) {
    if (latest == null || time.isAfter(latest)) latest = time;
  }
  return latest;
}

class ExerciseStatus {
  const ExerciseStatus({required this.ready, required this.label});

  final bool ready;
  final String label;
}

ExerciseStatus exerciseStatus({
  required DateTime now,
  required Iterable<DateTime> completedTimes,
  required Cooldown cooldown,
}) {
  final at = readyAt(completedTimes, cooldown);
  if (at == null || !now.isBefore(at)) {
    return const ExerciseStatus(ready: true, label: 'Ready');
  }
  return ExerciseStatus(
    ready: false,
    label: 'Ready in ${_remaining(at.difference(now))}',
  );
}

String _remaining(Duration remaining) {
  if (remaining.inHours >= 24) {
    // Round up to the next hour so a fresh 2-day cooldown reads "2 days".
    final hours = (remaining.inMinutes + 59) ~/ 60;
    final days = hours ~/ 24;
    final rest = hours % 24;
    if (rest == 0) return days == 1 ? '1 day' : '$days days';
    return '${days}d ${rest}h';
  }
  final minutes = remaining.inMinutes % 60;
  if (remaining.inHours >= 1) return '${remaining.inHours}h ${minutes}m';
  return minutes <= 1 ? '1m' : '${minutes}m';
}
