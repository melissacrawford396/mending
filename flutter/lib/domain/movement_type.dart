import 'body_area.dart';

/// Shared setup for a movement. Identity is [name].
class MovementType {
  const MovementType({
    required this.name,
    required this.area,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultCooldown,
    required this.description,
  });

  final String name;
  final BodyArea area;
  final int defaultSets;
  final int defaultReps;

  /// Days between repeats. 1 means every day.
  final int defaultCooldown;
  final String description;
}
