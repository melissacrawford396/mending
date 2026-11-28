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
  List<DeletedCompletion> deleted = [];
  List<ReviewRow> reviews = [];
  String? skippedReviewSession;
  var use24Hour = true;
  var darkMode = false;
  var signedIn = true;

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
    final completions = _withIds(data.completions);
    final deleted = keptDeleted([
      for (final row in data.deleted)
        DeletedCompletion(
          completion: _withId(row.completion),
          deletedAt: row.deletedAt,
        ),
    ], now());
    final reviews = List.of(data.reviews);
    skippedReviewSession = data.skippedReviewSession;
    use24Hour = data.use24Hour;
    darkMode = data.darkMode;
    signedIn = data.signedIn;
    final missingId =
        data.completions.any((row) => row.id.isEmpty) ||
        data.deleted.any((row) => row.completion.id.isEmpty);
    final purged = deleted.length != data.deleted.length;
    this.completions = completions;
    this.deleted = deleted;
    this.reviews = reviews;
    if (missingId || purged) {
      await store.saveLog(
        completions: completions,
        deleted: deleted,
        reviews: reviews,
      );
    }
    notifyListeners();
  }

  /// Different local days that have a completion.
  int daysLogged() {
    final days = <String>{
      for (final row in completions)
        if (row.user == currentUser) prompt.sessionKeyFor(row.completedAt),
    };
    return days.length;
  }

  Future<void> setUse24Hour(bool value) => _saveSettings(use24Hour: value);

  Future<void> setDarkMode(bool value) => _saveSettings(darkMode: value);

  Future<void> signOut() => _saveSettings(signedIn: false);

  Future<void> signIn() => _saveSettings(signedIn: true);

  Future<void> _saveSettings({
    bool? use24Hour,
    bool? darkMode,
    bool? signedIn,
  }) async {
    this.use24Hour = use24Hour ?? this.use24Hour;
    this.darkMode = darkMode ?? this.darkMode;
    this.signedIn = signedIn ?? this.signedIn;
    await store.saveSettings(
      use24Hour: this.use24Hour,
      darkMode: this.darkMode,
      signedIn: this.signedIn,
    );
    notifyListeners();
  }

  Completion _withId(Completion row) {
    return row.id.isEmpty ? row.copyWith(id: newCompletionId()) : row;
  }

  List<Completion> _withIds(List<Completion> rows) {
    return [for (final row in rows) _withId(row)];
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
    List<int>? setReps,
  }) async {
    final row = Completion(
      id: newCompletionId(),
      user: currentUser,
      movementId: movementId,
      completedAt: now(),
      sets: sets,
      reps: reps,
      setReps: setReps,
    );
    await store.appendCompletion(row);
    completions = [...completions, row];
    notifyListeners();
  }

  Future<void> updateCompletion(Completion next) async {
    Completion? previous;
    for (final row in completions) {
      if (row.id == next.id) previous = row;
    }
    final prior = previous;
    if (prior == null) return;
    await _writeLog(
      completions: [
        for (final row in completions)
          if (row.id == next.id) next else row,
      ],
      reviews: [
        for (final review in reviews)
          if (review.user == prior.user &&
              review.movementId == prior.movementId &&
              review.exercisedAt.isAtSameMomentAs(prior.completedAt))
            review.copyWith(exercisedAt: next.completedAt)
          else
            review,
      ],
    );
  }

  Future<void> deleteCompletion(String id) async {
    Completion? target;
    for (final row in completions) {
      if (row.id == id) target = row;
    }
    final row = target;
    if (row == null) return;
    await _writeLog(
      completions: [
        for (final item in completions)
          if (item.id != id) item,
      ],
      deleted: [
        ...deleted,
        DeletedCompletion(completion: row, deletedAt: now()),
      ],
    );
  }

  Future<void> restoreCompletion(String id) async {
    DeletedCompletion? target;
    for (final row in deleted) {
      if (row.completion.id == id) target = row;
    }
    final row = target;
    if (row == null) return;
    await _writeLog(
      completions: [...completions, row.completion],
      deleted: [
        for (final item in deleted)
          if (item.completion.id != id) item,
      ],
    );
  }

  /// Drops sessions that have been in Recently deleted for more than 7 days.
  Future<void> purgeDeleted() async {
    final kept = keptDeleted(deleted, now());
    if (kept.length == deleted.length) return;
    await _writeLog(deleted: kept);
  }

  Future<void> _writeLog({
    List<Completion>? completions,
    List<DeletedCompletion>? deleted,
    List<ReviewRow>? reviews,
  }) async {
    final nextCompletions = completions ?? this.completions;
    final nextDeleted = deleted ?? this.deleted;
    final nextReviews = reviews ?? this.reviews;
    await store.saveLog(
      completions: nextCompletions,
      deleted: nextDeleted,
      reviews: nextReviews,
    );
    this.completions = nextCompletions;
    this.deleted = nextDeleted;
    this.reviews = nextReviews;
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
