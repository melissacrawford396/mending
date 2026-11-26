import 'completion.dart';
import 'review_row.dart';

class PendingReview {
  const PendingReview({required this.sessionKey, required this.items});

  /// Local calendar day of the session, `yyyy-MM-dd`.
  final String sessionKey;
  final List<Completion> items;
}

String sessionKeyFor(DateTime time) {
  final local = time.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

bool sameLocalDay(DateTime a, DateTime b) {
  final left = a.toLocal();
  final right = b.toLocal();
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

/// Exercises from the last day you trained, when that day is before [now].
PendingReview? pendingReview({
  required DateTime now,
  required String user,
  required List<Completion> completions,
  required List<ReviewRow> reviews,
  required String? skippedSessionKey,
}) {
  final mine = [
    for (final row in completions)
      if (row.user == user) row,
  ];
  if (mine.isEmpty) return null;
  mine.sort((a, b) => a.completedAt.compareTo(b.completedAt));
  final latest = mine.last;
  if (sameLocalDay(latest.completedAt, now)) return null;
  final key = sessionKeyFor(latest.completedAt);
  if (skippedSessionKey == key) return null;

  final latestByName = <String, Completion>{};
  for (final row in mine) {
    if (!sameLocalDay(row.completedAt, latest.completedAt)) continue;
    final existing = latestByName[row.exerciseName];
    if (existing == null || row.completedAt.isAfter(existing.completedAt)) {
      latestByName[row.exerciseName] = row;
    }
  }

  final items = [
    for (final row in latestByName.values)
      if (!_isReviewed(row, reviews, user)) row,
  ]..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
  if (items.isEmpty) return null;
  return PendingReview(sessionKey: key, items: items);
}

bool _isReviewed(Completion row, List<ReviewRow> reviews, String user) {
  for (final review in reviews) {
    if (review.user != user || review.exerciseName != row.exerciseName) {
      continue;
    }
    if (review.exercisedAt.isAtSameMomentAs(row.completedAt)) return true;
  }
  return false;
}
