import 'body_area.dart';

/// One move inside a circuit. [name] is the set title. [cue] is the how-to.
class MovementStep {
  const MovementStep({required this.name, required this.cue});

  factory MovementStep.fromJson(Map<String, dynamic> json) {
    return MovementStep(
      name: json['name'] as String,
      cue: json['cue'] as String? ?? '',
    );
  }

  final String name;
  final String cue;
}

/// Shared setup for a movement. Identity is [id]; [name] is display text.
class MovementType {
  const MovementType({
    required this.id,
    required this.name,
    required this.area,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultCooldown,
    this.defaultPerDay = 1,
    this.defaultRestSeconds = 30,
    this.timed = false,
    required this.description,
    this.steps = const [],
    this.bothSides = false,
  });

  factory MovementType.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return MovementType(
      id: id,
      name: json['name'] as String? ?? id,
      area: BodyArea.parse(json['area'] as String),
      defaultSets: json['defaultSets'] as int? ?? 1,
      defaultReps: json['defaultReps'] as int? ?? 1,
      defaultCooldown: json['defaultCooldown'] as int? ?? 1,
      defaultPerDay: json['defaultPerDay'] as int? ?? 1,
      defaultRestSeconds: json['defaultRestSeconds'] as int? ?? 30,
      timed: json['timed'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      steps: [
        for (final row in json['steps'] as List? ?? const [])
          MovementStep.fromJson(row as Map<String, dynamic>),
      ],
      bothSides: json['bothSides'] as bool? ?? false,
    );
  }

  /// Stable key, like `toe-flex`. Saved rows point at this, so never change it.
  final String id;
  final String name;
  final BodyArea area;
  final int defaultSets;
  final int defaultReps;

  /// Days between repeats. 1 means every day, which waits 18 hours.
  final int defaultCooldown;

  /// Times allowed within one day. Above 1, [defaultCooldown] is treated as 1.
  final int defaultPerDay;

  /// Rest between sets.
  final int defaultRestSeconds;

  /// The count is a hold in seconds, not a number of reps.
  final bool timed;
  final String description;

  /// Named moves, in order. Empty means every set is this movement.
  final List<MovementStep> steps;

  /// Walk [steps] on the left, then the same list on the right.
  final bool bothSides;

  /// Sets in one full walk. 0 when this movement has no steps.
  int get walkSets => steps.isEmpty ? 0 : steps.length * (bothSides ? 2 : 1);

  /// The move for a 1-based set. Null when this movement has no steps, or
  /// [set] is past the walk.
  MovementStep? stepForSet(int set) {
    if (steps.isEmpty || set < 1 || set > walkSets) return null;
    return steps[(set - 1) % steps.length];
  }

  /// "Left side" or "Right side" on a both-sides walk. Null otherwise.
  String? sideForSet(int set) {
    if (!bothSides || stepForSet(set) == null) return null;
    return set <= steps.length ? 'Left side' : 'Right side';
  }
}
