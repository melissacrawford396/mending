import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/domain/effective.dart';
import 'package:mending/domain/movement_type.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/domain/readiness.dart';
import 'package:mending/ui/movement_visual_view.dart';

import 'test_catalog.dart';

void main() {
  final arch = testCatalog.byId('arch-roll');

  // Monday, November 23, 2026.
  DateTime mon(int hour, [int minute = 0]) =>
      DateTime(2026, 11, 23, hour, minute);
  DateTime tue(int hour) => DateTime(2026, 11, 24, hour);
  DateTime wed(int hour) => DateTime(2026, 11, 25, hour);

  test('empty override follows the current default', () {
    final exercise = MyExercise.from(arch);
    expect(effectiveSets(arch, exercise), 1);
    expect(effectiveReps(arch, exercise), 10);
    expect(effectiveCooldown(arch, exercise), const Cooldown(days: 2));
    expect(effectiveRest(arch, exercise), 30);

    final changed = MovementType(
      id: arch.id,
      name: arch.name,
      area: arch.area,
      defaultSets: 4,
      defaultReps: 8,
      defaultCooldown: 3,
      defaultRestSeconds: 45,
      description: arch.description,
    );
    expect(effectiveSets(changed, exercise), 4);
    expect(effectiveReps(changed, exercise), 8);
    expect(effectiveCooldown(changed, exercise).days, 3);
    expect(effectiveRest(changed, exercise), 45);
  });

  test('an override stays when the default changes', () {
    final exercise = MyExercise(
      user: currentUser,
      movementId: arch.id,
      setsOverride: 3,
      repsOverride: 6,
      cooldownOverride: 5,
      restOverride: 10,
      starred: true,
    );
    final changed = MovementType(
      id: arch.id,
      name: arch.name,
      area: arch.area,
      defaultSets: 4,
      defaultReps: 8,
      defaultCooldown: 3,
      description: arch.description,
    );
    expect(effectiveSets(changed, exercise), 3);
    expect(effectiveReps(changed, exercise), 6);
    expect(effectiveCooldown(changed, exercise).days, 5);
    expect(effectiveRest(changed, exercise), 10);
  });

  test('values past the caps are clamped', () {
    final exercise = MyExercise(
      user: currentUser,
      movementId: arch.id,
      setsOverride: 99,
      repsOverride: 99,
      cooldownOverride: 30,
      starred: true,
    );
    expect(effectiveSets(arch, exercise), maxSets);
    expect(effectiveReps(arch, exercise), maxReps);
    expect(effectiveCooldown(arch, exercise).days, maxCooldownDays);
    expect(
      effectiveCooldown(
        arch,
        exercise.copyWith(perDayOverride: 2, gapHoursOverride: 5),
      ),
      const Cooldown(perDay: 2, gapHours: 5),
    );
  });

  test('the gap defaults to 8 hours at 2x a day and 4 hours at 3x', () {
    expect(const Cooldown(perDay: 2).gapHours, 8);
    expect(const Cooldown(perDay: 3).gapHours, 4);
    expect(Cooldown.atStep(0).label, '3x a day, 4 h apart');
    expect(Cooldown.atStep(1).label, '2x a day, 8 h apart');

    final thrice = MyExercise(
      user: currentUser,
      movementId: arch.id,
      perDayOverride: 3,
      starred: true,
    );
    expect(effectiveCooldown(arch, thrice).gapHours, 4);
    expect(
      effectiveCooldown(arch, thrice.copyWith(gapHoursOverride: 6)).gapHours,
      6,
    );
  });

  test('3x a day, 4 h apart, locks after the third', () {
    const thrice = Cooldown(perDay: 3);
    expect(readyAt([mon(7)], thrice), mon(11));
    expect(readyAt([mon(7), mon(11)], thrice), mon(15));
    expect(readyAt([mon(7), mon(11), mon(15)], thrice), tue(4));
  });

  test('the Cooldown scale runs from 3x a day to every 7 days', () {
    final labels = [
      for (var step = 0; step <= Cooldown.lastStep; step++)
        Cooldown.atStep(step).frequency,
    ];
    expect(labels, [
      '3x a day',
      '2x a day',
      'every day',
      'every 2 days',
      'every 3 days',
      'every 4 days',
      'every 5 days',
      'every 6 days',
      'every 7 days',
    ]);
    for (var step = 0; step <= Cooldown.lastStep; step++) {
      expect(Cooldown.atStep(step).step, step);
    }
  });

  test('a day starts at 4 AM', () {
    expect(dayStartOf(mon(21)), mon(4));
    expect(dayStartOf(tue(1)), mon(4));
    expect(dayStartOf(tue(4)), tue(4));
  });

  test('no log row means ready', () {
    final status = exerciseStatus(
      now: wed(8),
      completedTimes: const [],
      cooldown: const Cooldown(days: 2),
    );
    expect(status.ready, isTrue);
    expect(status.label, 'Ready');
  });

  test('once a day resets at the next 4 AM', () {
    const daily = Cooldown();
    expect(readyAt([mon(21)], daily), tue(4));
    expect(readyAt([tue(1)], daily), tue(4));
    expect(
      exerciseStatus(
        now: mon(22),
        completedTimes: [mon(21)],
        cooldown: daily,
      ).label,
      'Ready in 6h 0m',
    );
    expect(isReady(tue(4), [mon(21)], daily), isTrue);
  });

  test('every 2 days skips the next day', () {
    const everyOther = Cooldown(days: 2);
    expect(readyAt([mon(8)], everyOther), wed(4));
    expect(isReady(tue(12), [mon(8)], everyOther), isFalse);
    expect(isReady(wed(4), [mon(8)], everyOther), isTrue);
  });

  test('2 a day waits for the gap, then locks until 4 AM', () {
    const twice = Cooldown(perDay: 2, gapHours: 8);
    expect(readyAt([mon(7)], twice), mon(15));
    expect(isReady(mon(14), [mon(7)], twice), isFalse);
    expect(isReady(mon(15), [mon(7)], twice), isTrue);
    expect(readyAt([mon(7), mon(15)], twice), tue(4));
    expect(readyAt([mon(23)], twice), tue(4));
  });

  test('every movement has a bundled clip and thumbnail', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(
      testCatalog.visuals.map((visual) => visual.movementId),
      testCatalog.movements.map((movement) => movement.id),
    );
    for (final visual in testCatalog.visuals) {
      for (final path in [visual.representation, visual.thumbnail]) {
        expect(path, isNotNull, reason: visual.movementId);
        final bytes = await rootBundle.load(assetFor(path!));
        expect(bytes.lengthInBytes, greaterThan(0), reason: path);
      }
    }
  });
}
