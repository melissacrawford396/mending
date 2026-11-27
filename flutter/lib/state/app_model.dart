import 'package:flutter/foundation.dart';

import '../data/catalog.dart';
import '../data/store.dart';
import '../domain/completion.dart';
import '../domain/movement_type.dart';
import '../domain/my_exercise.dart';
import '../domain/review_prompt.dart' as prompt;
import '../domain/review_row.dart';

class AppModel extends ChangeNotifier {
  AppModel({
    required this.store,
    required this.catalog,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final MendingStore store;
  final MovementCatalog catalog;
  DateTime Function() now;

  List<MyExercise> exercises = [];
  List<Completion> completions = [];
  List<ReviewRow> reviews = [];
  String? skippedReviewSession;

  Future<void> load() async {
    final data = await store.load();
    if (!data.initialized) {
      exercises = seedExercises(catalog);
      await store.saveExercises(exercises);
    } else {
      exercises = data.exercises;
    }
    completions = List.of(data.completions);
    reviews = List.of(data.reviews);
    skippedReviewSession = data.skippedReviewSession;
    notifyListeners();
  }

  MyExercise? findExercise(String movementName) {
    for (final exercise in exercises) {
      if (exercise.user == currentUser &&
          exercise.movementName == movementName) {
        return exercise;
      }
    }
    return null;
  }

  prompt.PendingReview? pendingReview() {
    return prompt.pendingReview(
      now: now(),
      user: currentUser,
      completions: completions,
      reviews: reviews,
      skippedSessionKey: skippedReviewSession,
    );
  }

  Future<void> setStarred(MovementType movement, bool starred) async {
    final current = findExercise(movement.name) ?? MyExercise.from(movement);
    await _saveExercise(current.copyWith(starred: starred));
  }

  Future<void> setOverrides(
    MovementType movement, {
    required int? sets,
    required int? reps,
    required int? cooldown,
  }) async {
    final current = findExercise(movement.name) ?? MyExercise.from(movement);
    await _saveExercise(
      MyExercise(
        user: current.user,
        movementName: current.movementName,
        setsOverride: sets,
        repsOverride: reps,
        cooldownOverride: cooldown,
        starred: current.starred,
      ),
    );
  }

  Future<void> complete({
    required String exerciseName,
    required int sets,
    required int reps,
  }) async {
    final row = Completion(
      user: currentUser,
      exerciseName: exerciseName,
      completedAt: now(),
      sets: sets,
      reps: reps,
    );
    await store.appendCompletion(row);
    completions = [...completions, row];
    notifyListeners();
  }

  Future<void> addReviews(List<ReviewRow> rows) async {
    if (rows.isEmpty) return;
    await store.appendReviews(rows);
    reviews = [...reviews, ...rows];
    notifyListeners();
  }

  Future<void> skipReview(String sessionKey) async {
    await store.setSkippedReviewSession(sessionKey);
    skippedReviewSession = sessionKey;
    notifyListeners();
  }

  Future<void> _saveExercise(MyExercise exercise) async {
    final next = [...exercises];
    final index = next.indexWhere(
      (row) =>
          row.user == exercise.user &&
          row.movementName == exercise.movementName,
    );
    if (index < 0) {
      next.add(exercise);
    } else {
      next[index] = exercise;
    }
    exercises = next;
    await store.saveExercises(exercises);
    notifyListeners();
  }
}
