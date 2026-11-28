import '../domain/body_area.dart';
import '../domain/movement_type.dart';
import '../domain/movement_visual.dart';
import '../domain/my_exercise.dart';

/// Newest catalog file layout this build can read.
const catalogSchemaVersion = 1;

class MovementCatalog {
  const MovementCatalog({required this.movements, required this.visuals});

  factory MovementCatalog.fromJson({
    required Map<String, dynamic> movements,
    required Map<String, dynamic> visuals,
  }) {
    _checkVersion(movements);
    _checkVersion(visuals);
    return MovementCatalog(
      movements: [
        for (final row in movements['movements'] as List? ?? const [])
          MovementType.fromJson(row as Map<String, dynamic>),
      ],
      visuals: [
        for (final row in visuals['visuals'] as List? ?? const [])
          MovementVisual.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  final List<MovementType> movements;
  final List<MovementVisual> visuals;

  MovementType byId(String id) {
    final movement = find(id);
    if (movement == null) {
      throw ArgumentError('Unknown movement: $id');
    }
    return movement;
  }

  MovementType? find(String id) {
    for (final movement in movements) {
      if (movement.id == id) return movement;
    }
    return null;
  }

  int indexOf(String id) {
    for (var i = 0; i < movements.length; i++) {
      if (movements[i].id == id) return i;
    }
    return -1;
  }

  List<MovementType> forArea(BodyArea area) {
    return [
      for (final movement in movements)
        if (movement.area == area) movement,
    ];
  }

  MovementVisual visualFor(String id) {
    for (final visual in visuals) {
      if (visual.movementId == id) return visual;
    }
    return MovementVisual(movementId: id);
  }
}

void _checkVersion(Map<String, dynamic> json) {
  final version = json['schemaVersion'] as int? ?? 1;
  if (version > catalogSchemaVersion) {
    throw FormatException(
      'Catalog schema $version is newer than $catalogSchemaVersion',
    );
  }
}

/// The first working list. New catalog entries are not added here.
const starterMovementIds = [
  'arch-roll',
  'toe-flex',
  'small-shoulder-circles',
  'large-arm-circles',
  'ankle-stretch',
];

List<MyExercise> seedExercises(MovementCatalog catalog) {
  return [
    for (final id in starterMovementIds)
      if (catalog.find(id) case final movement?)
        MyExercise.from(movement, starred: true),
  ];
}
