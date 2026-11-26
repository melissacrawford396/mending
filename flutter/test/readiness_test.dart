import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/catalog.dart';
import 'package:mending/domain/completion.dart';
import 'package:mending/domain/effective.dart';
import 'package:mending/domain/movement_type.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/domain/readiness.dart';
import 'package:mending/ui/movement_visual_view.dart';

void main() {
  final arch = movementCatalog.byName('Arch roll');

  test('empty override follows the current default', () {
    final exercise = MyExercise.from(arch);
    expect(effectiveSets(arch, exercise), 1);
    expect(effectiveReps(arch, exercise), 10);
    expect(effectiveCooldown(arch, exercise), 2);

    final changed = MovementType(
      name: arch.name,
      area: arch.area,
      defaultSets: 4,
      defaultReps: 8,
      defaultCooldown: 3,
      description: arch.description,
    );
    expect(effectiveSets(changed, exercise), 4);
    expect(effectiveReps(changed, exercise), 8);
    expect(effectiveCooldown(changed, exercise), 3);
  });

  test('an override stays when the default changes', () {
    final exercise = MyExercise(
      user: currentUser,
      movementName: arch.name,
      setsOverride: 3,
      repsOverride: 6,
      cooldownOverride: 5,
      starred: true,
    );
    final changed = MovementType(
      name: arch.name,
      area: arch.area,
      defaultSets: 4,
      defaultReps: 8,
      defaultCooldown: 3,
      description: arch.description,
    );
    expect(effectiveSets(changed, exercise), 3);
    expect(effectiveReps(changed, exercise), 6);
    expect(effectiveCooldown(changed, exercise), 5);
  });

  test('no log row means ready', () {
    final status = exerciseStatus(
      now: DateTime(2026, 11, 25, 8),
      completedAt: null,
      cooldownDays: 2,
    );
    expect(status.ready, isTrue);
    expect(status.label, 'Ready');
  });

  test('cooldown is N times 24 hours and an early repeat restarts it', () {
    final rows = [
      Completion(
        user: currentUser,
        exerciseName: 'Toe flex',
        completedAt: DateTime(2026, 11, 20, 8),
        sets: 1,
        reps: 10,
      ),
      Completion(
        user: currentUser,
        exerciseName: 'Toe flex',
        completedAt: DateTime(2026, 11, 21, 8),
        sets: 1,
        reps: 10,
      ),
    ];
    final latest = latestCompletionAt(rows, currentUser, 'Toe flex');
    expect(latest, DateTime(2026, 11, 21, 8));
    expect(
      exerciseStatus(
        now: DateTime(2026, 11, 22, 7),
        completedAt: latest,
        cooldownDays: 1,
      ).label,
      'Ready in 1h 0m',
    );
    expect(
      exerciseStatus(
        now: DateTime(2026, 11, 22, 8),
        completedAt: latest,
        cooldownDays: 1,
      ).ready,
      isTrue,
    );
    expect(
      exerciseStatus(
        now: DateTime(2026, 11, 21, 8),
        completedAt: latest,
        cooldownDays: 2,
      ).label,
      'Ready in 2 days',
    );
    expect(
      exerciseStatus(
        now: latest!.add(const Duration(seconds: 20)),
        completedAt: latest,
        cooldownDays: 2,
      ).label,
      'Ready in 2 days',
    );
  });

  test('every movement has a bundled clip and thumbnail', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(
      movementCatalog.visuals.map((visual) => visual.movementName),
      movementCatalog.movements.map((movement) => movement.name),
    );
    for (final visual in movementCatalog.visuals) {
      for (final path in [visual.representation, visual.thumbnail]) {
        expect(path, isNotNull, reason: visual.movementName);
        final bytes = await rootBundle.load(assetFor(path!));
        expect(bytes.lengthInBytes, greaterThan(0), reason: path);
      }
    }
  });
}
