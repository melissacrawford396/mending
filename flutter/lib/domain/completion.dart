/// One append-only fact: you finished an exercise.
class Completion {
  const Completion({
    required this.user,
    required this.exerciseName,
    required this.completedAt,
    required this.sets,
    required this.reps,
  });

  final String user;
  final String exerciseName;
  final DateTime completedAt;
  final int sets;
  final int reps;

  Map<String, dynamic> toJson() => {
    'user': user,
    'exerciseName': exerciseName,
    'completedAt': completedAt.toUtc().toIso8601String(),
    'sets': sets,
    'reps': reps,
  };

  factory Completion.fromJson(Map<String, dynamic> json) {
    return Completion(
      user: json['user'] as String,
      exerciseName: json['exerciseName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      sets: json['sets'] as int,
      reps: json['reps'] as int,
    );
  }
}
