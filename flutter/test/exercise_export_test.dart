import 'package:flutter_test/flutter_test.dart';
import 'package:mending/domain/exercise_export.dart';
import 'package:mending/domain/my_exercise.dart';

import 'test_catalog.dart';

void main() {
  test('the export lists each exercise at the sets and reps in use', () {
    final text = exerciseSettingsExport(testCatalog, [
      MyExercise(
        user: currentUser,
        movementId: 'arch-roll',
        setsOverride: 3,
        repsOverride: 12,
        starred: true,
      ),
    ]);
    expect(text, contains('Arch roll (arch-roll): 3 sets, 12 reps'));
    expect(text, contains('Ankle stretch (ankle-stretch): 2 sets, 30 s'));
    expect(text, contains('High plank (high-plank): 2 sets, 20 s'));
    expect(text, contains('Hip circuit (hip-circuit): 8 sets, 10 reps'));
    expect(text.indexOf('Arch roll'), lessThan(text.indexOf('High plank')));
  });
}
