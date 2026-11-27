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

  /// Set after a guided session, once its celebration closes, so the Working
  /// list can show the movement moving to Waiting. Cleared by
  /// [clearJustCompleted].
  String? justCompletedId;

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

  MyExercise? findExercise(String movementId) {
    for (final exercise in exercises) {
      if (exercise.user == currentUser && exercise.movementId == movementId) {
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
    await updateExercise(movement, (row) => row.copyWith(starred: starred));
  }

  Future<void> updateExercise(
    MovementType movement,
    MyExercise Function(MyExercise current) change,
  ) async {
    final current = findExercise(movement.id) ?? MyExercise.from(movement);
    await _saveExercise(change(current));
  }

  Future<void> complete({
    required String movementId,
    required int sets,
    required int reps,
  }) async {
    final row = Completion(
      user: currentUser,
      movementId: movementId,
      completedAt: now(),
      sets: sets,
      reps: reps,
    );
    await store.appendCompletion(row);
    completions = [...completions, row];
    notifyListeners();
  }

  void showArrival(String movementId) {
    justCompletedId = movementId;
    notifyListeners();
  }

  void clearJustCompleted() {
    if (justCompletedId == null) return;
    justCompletedId = null;
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
          row.user == exercise.user && row.movementId == exercise.movementId,
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
