import 'effective.dart';
import 'my_exercise.dart';

/// One append-only fact: you finished an exercise.
class Completion {
  Completion({
    required this.user,
    required this.movementId,
    required this.completedAt,
    required int sets,
    required int reps,
    List<int>? setReps,
  }) : reps = reps,
       setReps = List.unmodifiable(setReps ?? List<int>.filled(sets, reps)),
       sets = (setReps ?? List<int>.filled(sets, reps)).length;

  final String user;
  final String movementId;
  final DateTime completedAt;

  /// How many sets were finished. Matches [setReps.length].
  final int sets;

  /// Kept for older rows. [setReps] is the count for each set.
  final int reps;

  /// Reps finished in each set, in order.
  final List<int> setReps;

  Map<String, dynamic> toJson() => {
    'user': user,
    'movementId': movementId,
    'completedAt': completedAt.toUtc().toIso8601String(),
    'sets': sets,
    'reps': reps,
    'setReps': setReps,
  };

  factory Completion.fromJson(Map<String, dynamic> json) {
    final sets = json['sets'] as int? ?? 0;
    final reps = json['reps'] as int? ?? 0;
    final raw = json['setReps'];
    final parsed = <int>[
      if (raw is List)
        for (final item in raw)
          if (item is int) item,
    ];
    return Completion(
      user: json['user'] as String? ?? currentUser,
      movementId: json['movementId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      sets: sets,
      reps: reps,
      setReps: parsed.isEmpty ? null : parsed,
    );
  }
}

/// "2 sets · 10 reps", or "2 sets · 10, 8 reps" when the sets differ.
/// A timed movement reads "2 sets · 30 s", or "2 sets · 25 s, 30 s".
String setsRepsLabel(List<int> setReps, {bool seconds = false}) {
  final setLabel = setReps.length == 1 ? '1 set' : '${setReps.length} sets';
  if (setReps.isEmpty) return setLabel;
  final same = setReps.every((count) => count == setReps.first);
  final String repLabel;
  if (seconds) {
    repLabel = same
        ? restLabel(setReps.first)
        : setReps.map(restLabel).join(', ');
  } else {
    repLabel = same
        ? (setReps.first == 1 ? '1 rep' : '${setReps.first} reps')
        : '${setReps.join(', ')} reps';
  }
  return '$setLabel · $repLabel';
}
