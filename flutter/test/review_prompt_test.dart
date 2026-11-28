import 'package:flutter_test/flutter_test.dart';
import 'package:mending/domain/body_area.dart';
import 'package:mending/domain/completion.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/domain/review_prompt.dart';
import 'package:mending/domain/review_row.dart';
import 'package:mending/domain/sensation.dart';

void main() {
  final now = DateTime(2026, 11, 25, 8);
  Completion row(String id, DateTime at) {
    return Completion(
      user: currentUser,
      movementId: id,
      completedAt: at,
      sets: 1,
      reps: 10,
    );
  }

  PendingReview? ask(
    List<Completion> completions, {
    List<ReviewRow>? reviews,
    String? skipped,
  }) {
    return pendingReview(
      now: now,
      user: currentUser,
      completions: completions,
      reviews: reviews ?? const [],
      skippedSessionKey: skipped,
    );
  }

  test('nothing to ask when there is no log or the session is today', () {
    expect(ask(const []), isNull);
    expect(ask([row('toe-flex', DateTime(2026, 11, 25, 7))]), isNull);
  });

  test('asks about the previous day and skips an older day', () {
    final pending = ask([
      row('arch-roll', DateTime(2026, 11, 23, 9)),
      row('toe-flex', DateTime(2026, 11, 24, 9)),
      row('ankle-stretch', DateTime(2026, 11, 24, 9, 30)),
    ]);
    expect(pending!.sessionKey, '2026-11-24');
    expect(pending.items.map((item) => item.movementId), [
      'ankle-stretch',
      'toe-flex',
    ]);
  });

  test('a skipped session and a saved answer are not asked again', () {
    final toe = row('toe-flex', DateTime(2026, 11, 24, 9));
    final arch = row('arch-roll', DateTime(2026, 11, 24, 9));
    expect(ask([toe], skipped: '2026-11-24'), isNull);
    final pending = ask(
      [toe, arch],
      reviews: [
        ReviewRow(
          user: currentUser,
          movementId: 'toe-flex',
          area: BodyArea.feet,
          reviewedAt: now,
          exercisedAt: toe.completedAt,
          sensation: Sensation.fine,
        ),
      ],
    );
    expect(pending!.items.single.movementId, 'arch-roll');
  });
}
