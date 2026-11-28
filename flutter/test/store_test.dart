import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/store.dart';
import 'package:mending/domain/body_area.dart';
import 'package:mending/domain/effective.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/domain/readiness.dart';
import 'package:mending/domain/review_row.dart';
import 'package:mending/domain/sensation.dart';
import 'package:mending/state/app_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppModel> load({MendingStore? store, DateTime Function()? now}) async {
    final model = AppModel(
      store: store ?? MemoryMendingStore(),
      catalog: testCatalog,
      now: now,
    );
    await model.load();
    return model;
  }

  test('first launch stars the five movements and keeps later rows', () async {
    final store = MemoryMendingStore();
    final first = DateTime(2026, 11, 20, 8);
    final second = DateTime(2026, 11, 21, 8);
    var clock = first;
    final model = await load(store: store, now: () => clock);
    expect(model.exercises.map((row) => row.movementId), [
      'arch-roll',
      'toe-flex',
      'small-shoulder-circles',
      'large-arm-circles',
      'ankle-stretch',
    ]);
    expect(
      model.exercises.every((row) => row.starred && row.setsOverride == null),
      isTrue,
    );

    await model.complete(movementId: 'arch-roll', sets: 1, reps: 10);
    clock = second;
    await model.complete(movementId: 'arch-roll', sets: 4, reps: 8);
    expect(model.completions.map((row) => row.sets), [1, 4]);

    final again = await load(store: store, now: () => second);
    expect(again.completions, hasLength(2));
    expect(again.completions.map((row) => row.id), [
      model.completions[0].id,
      model.completions[1].id,
    ]);
    expect(again.completions.every((row) => row.id.isNotEmpty), isTrue);
    expect(
      latestCompletionAt(again.completions, currentUser, 'arch-roll'),
      second,
    );
    expect(
      exerciseStatus(
        now: DateTime(2026, 11, 22, 8),
        completedTimes: completionTimes(
          again.completions,
          currentUser,
          'arch-roll',
        ),
        cooldown: const Cooldown(days: 2),
      ).ready,
      isFalse,
    );
  });

  test('prefs reload the seed, the log, and a skip', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 11, 25, 8);
    final model = await load(store: PrefsMendingStore(), now: () => now);
    await model.complete(movementId: 'toe-flex', sets: 1, reps: 10);
    await model.skipReview('2026-11-24');

    final again = await load(store: PrefsMendingStore(), now: () => now);
    expect(again.exercises, hasLength(5));
    expect(again.completions.single.movementId, 'toe-flex');
    expect(again.completions.single.reps, 10);
    expect(again.reviews, isEmpty);
    expect(again.skippedReviewSession, '2026-11-24');
    expect(again.pendingReview(), isNull);
  });

  test('version 1 data keyed by name loads by id', () async {
    SharedPreferences.setMockInitialValues({
      'mending.v1': jsonEncode({
        'initialized': true,
        'exercises': [
          {
            'user': 'me',
            'movementName': 'Toe flex',
            'setsOverride': 3,
            'repsOverride': null,
            'cooldownOverride': null,
            'starred': true,
          },
        ],
        'completions': [
          {
            'user': 'me',
            'exerciseName': 'Toe flex',
            'completedAt': '2026-11-24T15:00:00.000Z',
            'sets': 3,
            'reps': 10,
          },
        ],
        'reviews': [
          {
            'user': 'me',
            'exerciseName': 'Toe flex',
            'area': 'feet',
            'reviewedAt': '2026-11-25T14:00:00.000Z',
            'exercisedAt': '2026-11-24T15:00:00.000Z',
            'sensation': 'fine',
          },
        ],
        'skippedReviewSession': null,
      }),
    });
    final model = await load(store: PrefsMendingStore());
    expect(model.findExercise('toe-flex')!.setsOverride, 3);
    expect(model.findExercise('toe-flex')!.restOverride, isNull);
    expect(model.completions.single.movementId, 'toe-flex');
    expect(model.completions.single.setReps, [10, 10, 10]);
    expect(model.reviews.single.movementId, 'toe-flex');

    await model.complete(movementId: 'arch-roll', sets: 1, reps: 10);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('mending.v1')!) as Map;
    expect(saved['schemaVersion'], storeSchemaVersion);
    expect((saved['completions'] as List).last['setReps'], [10]);
    expect((saved['exercises'] as List).single['movementId'], 'toe-flex');
  });

  test('missing fields use defaults and an unreadable row is skipped', () {
    final data = StoreData.fromJson({
      'schemaVersion': storeSchemaVersion,
      'initialized': true,
      'exercises': [
        {'movementId': 'toe-flex', 'mood': 'new field from a later build'},
      ],
      'completions': [
        {'movementId': 'toe-flex', 'completedAt': 'not a date'},
        {
          'movementId': 'arch-roll',
          'completedAt': '2026-11-24T15:00:00.000Z',
          'sets': 1,
          'reps': 10,
        },
      ],
    });
    final exercise = data.exercises.single;
    expect(exercise.user, currentUser);
    expect(exercise.starred, isFalse);
    expect(exercise.setsOverride, isNull);
    expect(exercise.perDayOverride, isNull);
    expect(exercise.gapHoursOverride, isNull);
    expect(exercise.restOverride, isNull);
    expect(data.completions.single.movementId, 'arch-roll');
    expect(data.completions.single.setReps, [10]);
    expect(data.completions.single.id, isEmpty);
    expect(data.reviews, isEmpty);
    expect(data.deleted, isEmpty);
  });

  test(
    'editing a completion keeps its id and moves a matching review',
    () async {
      final store = MemoryMendingStore();
      final done = DateTime(2026, 11, 24, 9);
      final model = await load(store: store, now: () => done);
      await model.complete(
        movementId: 'toe-flex',
        sets: 2,
        reps: 10,
        setReps: const [10, 8],
      );
      final original = model.completions.single;
      await model.addReviews([
        ReviewRow(
          user: currentUser,
          movementId: 'toe-flex',
          area: BodyArea.feet,
          reviewedAt: DateTime(2026, 11, 25, 8),
          exercisedAt: original.completedAt,
          sensation: Sensation.fine,
        ),
      ]);
      final editedAt = DateTime(2026, 11, 20, 15, 30);
      await model.updateCompletion(
        original.copyWith(
          completedAt: editedAt,
          reps: 8,
          setReps: const [8, 8],
        ),
      );
      expect(model.completions.single.id, original.id);
      expect(model.completions.single.sets, 2);
      expect(model.completions.single.setReps, [8, 8]);
      expect(model.completions.single.reps, 8);
      expect(
        model.reviews.single.exercisedAt.isAtSameMomentAs(editedAt),
        isTrue,
      );

      final again = await load(store: store, now: () => editedAt);
      expect(again.completions.single.id, original.id);
      expect(again.completions.single.setReps, [8, 8]);
      expect(
        again.reviews.single.exercisedAt.isAtSameMomentAs(editedAt),
        isTrue,
      );
    },
  );

  test('a saved row without an id keeps the id it is given', () async {
    SharedPreferences.setMockInitialValues({
      'mending.v1': jsonEncode({
        'schemaVersion': storeSchemaVersion,
        'initialized': true,
        'exercises': const [],
        'completions': [
          {
            'user': 'me',
            'movementId': 'toe-flex',
            'completedAt': '2026-11-24T15:00:00.000Z',
            'sets': 1,
            'reps': 10,
          },
        ],
        'reviews': const [],
      }),
    });
    final model = await load(store: PrefsMendingStore());
    final id = model.completions.single.id;
    expect(id, isNotEmpty);

    final again = await load(store: PrefsMendingStore());
    expect(again.completions.single.id, id);
  });

  test('delete restores for 7 days and then drops the row', () async {
    final store = MemoryMendingStore();
    final clock = DateTime(2026, 11, 25, 8);
    final model = await load(store: store, now: () => clock);
    await model.complete(movementId: 'arch-roll', sets: 1, reps: 10);
    final id = model.completions.single.id;

    await model.deleteCompletion(id);
    expect(model.completions, isEmpty);
    expect(model.deleted.single.completion.id, id);
    expect(
      completionTimes(model.completions, currentUser, 'arch-roll'),
      isEmpty,
    );

    await model.restoreCompletion(id);
    expect(model.completions.single.id, id);
    expect(model.deleted, isEmpty);

    await model.deleteCompletion(id);
    final kept = await load(
      store: store,
      now: () => clock.add(const Duration(days: 7)),
    );
    expect(kept.deleted.single.completion.id, id);
    expect(kept.completions, isEmpty);

    final gone = await load(
      store: store,
      now: () => clock.add(const Duration(days: 8)),
    );
    expect(gone.deleted, isEmpty);
    expect(gone.completions, isEmpty);
  });
}
