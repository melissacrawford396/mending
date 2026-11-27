import 'body_area.dart';

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
    required this.description,
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
      description: json['description'] as String? ?? '',
    );
  }

  /// Stable key, like `toe-flex`. Saved rows point at this, so never change it.
  final String id;
  final String name;
  final BodyArea area;
  final int defaultSets;
  final int defaultReps;

  /// Days until the 4 AM reset. 1 means every day.
  final int defaultCooldown;

  /// Times allowed within one day. Above 1, [defaultCooldown] is treated as 1.
  final int defaultPerDay;

  /// Rest between sets.
  final int defaultRestSeconds;
  final String description;
}
