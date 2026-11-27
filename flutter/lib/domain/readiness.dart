import 'completion.dart';

/// When the movement is ready again. Null when it has never been logged.
DateTime? readyAt(DateTime? completedAt, int cooldownDays) {
  if (completedAt == null) return null;
  return completedAt.add(Duration(days: cooldownDays));
}

bool isReady(DateTime now, DateTime? completedAt, int cooldownDays) {
  final at = readyAt(completedAt, cooldownDays);
  if (at == null) return true;
  return !now.isBefore(at);
}

DateTime? latestCompletionAt(
  Iterable<Completion> rows,
  String user,
  String movementId,
) {
  DateTime? latest;
  for (final row in rows) {
    if (row.user != user || row.movementId != movementId) continue;
    if (latest == null || row.completedAt.isAfter(latest)) {
      latest = row.completedAt;
    }
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
  required DateTime? completedAt,
  required int cooldownDays,
}) {
  if (isReady(now, completedAt, cooldownDays)) {
    return const ExerciseStatus(ready: true, label: 'Ready');
  }
  final remaining = readyAt(completedAt, cooldownDays)!.difference(now);
  return ExerciseStatus(
    ready: false,
    label: 'Ready in ${_remaining(remaining)}',
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
