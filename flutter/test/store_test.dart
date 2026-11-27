import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/catalog.dart';
import 'package:mending/data/store.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/domain/readiness.dart';
import 'package:mending/state/app_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppModel> load({MendingStore? store, DateTime Function()? now}) async {
    final model = AppModel(
      store: store ?? MemoryMendingStore(),
      catalog: movementCatalog,
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
    expect(model.exercises.map((row) => row.movementName), [
      'Arch roll',
      'Toe flex',
      'Small shoulder circles',
      'Large arm circles',
      'Ankle stretch',
    ]);
    expect(
      model.exercises.every((row) => row.starred && row.setsOverride == null),
      isTrue,
    );

    await model.complete(exerciseName: 'Arch roll', sets: 1, reps: 10);
    clock = second;
    await model.complete(exerciseName: 'Arch roll', sets: 4, reps: 8);
    expect(model.completions.map((row) => row.sets), [1, 4]);

    final again = await load(store: store, now: () => second);
    expect(again.completions, hasLength(2));
    expect(
      latestCompletionAt(again.completions, currentUser, 'Arch roll'),
      second,
    );
    expect(
      exerciseStatus(
        now: DateTime(2026, 11, 22, 8),
        completedAt: latestCompletionAt(
          again.completions,
          currentUser,
          'Arch roll',
        ),
        cooldownDays: 2,
      ).ready,
      isFalse,
    );
  });

  test('prefs reload the seed, the log, and a skip', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 11, 25, 8);
    final model = await load(store: PrefsMendingStore(), now: () => now);
    await model.complete(exerciseName: 'Toe flex', sets: 1, reps: 10);
    await model.skipReview('2026-11-24');

    final again = await load(store: PrefsMendingStore(), now: () => now);
    expect(again.exercises, hasLength(5));
    expect(again.completions.single.exerciseName, 'Toe flex');
    expect(again.completions.single.reps, 10);
    expect(again.reviews, isEmpty);
    expect(again.skippedReviewSession, '2026-11-24');
    expect(again.pendingReview(), isNull);
  });
}
