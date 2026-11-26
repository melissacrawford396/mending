import '../domain/body_area.dart';
import '../domain/movement_type.dart';
import '../domain/movement_visual.dart';
import '../domain/my_exercise.dart';

class MovementCatalog {
  const MovementCatalog({required this.movements, required this.visuals});

  final List<MovementType> movements;
  final List<MovementVisual> visuals;

  MovementType byName(String name) {
    final movement = find(name);
    if (movement == null) {
      throw ArgumentError('Unknown movement: $name');
    }
    return movement;
  }

  MovementType? find(String name) {
    for (final movement in movements) {
      if (movement.name == name) return movement;
    }
    return null;
  }

  int indexOf(String name) {
    for (var i = 0; i < movements.length; i++) {
      if (movements[i].name == name) return i;
    }
    return -1;
  }

  List<MovementType> forArea(BodyArea area) {
    return [
      for (final movement in movements)
        if (movement.area == area) movement,
    ];
  }

  MovementVisual visualFor(String name) {
    for (final visual in visuals) {
      if (visual.movementName == name) return visual;
    }
    return MovementVisual(movementName: name);
  }
}

/// First five movement types. Sets, reps, and cooldowns are decided.
const movementCatalog = MovementCatalog(
  movements: [
    MovementType(
      name: 'Arch roll',
      area: BodyArea.feet,
      defaultSets: 1,
      defaultReps: 10,
      defaultCooldown: 2,
      description:
          'Roll out the arch of your foot with a lacrosse ball. '
          'Use only the pressure of your foot. Do not stomp. '
          'Overdoing this will aggravate your foot. '
          'Reps mean slow passes along the arch.',
    ),
    MovementType(
      name: 'Toe flex',
      area: BodyArea.feet,
      defaultSets: 1,
      defaultReps: 10,
      defaultCooldown: 1,
      description:
          'Cross one leg over the other knee, then flex your toes back and forth. '
          'Be gentle. You can use your hand to assist the movement.',
    ),
    MovementType(
      name: 'Small shoulder circles',
      area: BodyArea.shoulders,
      defaultSets: 1,
      defaultReps: 10,
      defaultCooldown: 1,
      description:
          'Put your arms out and make small circles. Do it both directions. '
          'Reps mean circles in one direction. Then do the same number the other way.',
    ),
    MovementType(
      name: 'Large arm circles',
      area: BodyArea.shoulders,
      defaultSets: 1,
      defaultReps: 10,
      defaultCooldown: 1,
      description:
          'Make large arm circles. Do both directions. '
          'Reps mean circles in one direction. Then do the same number the other way.',
    ),
    MovementType(
      name: 'Ankle stretch',
      area: BodyArea.ankles,
      defaultSets: 2,
      defaultReps: 1,
      defaultCooldown: 1,
      description:
          'Step one foot in front of the other. Bend the front knee and keep the back foot flat on the ground. '
          "You should feel the stretch in the back foot's ankle, in the Achilles tendon. "
          'Switch which foot is back. '
          'Sets mean one held stretch per side.',
    ),
  ],
  visuals: [
    MovementVisual(
      movementName: 'Arch roll',
      representation: 'visuals/arch-roll.mp4',
      thumbnail: 'visuals/thumbnails/arch-roll.jpg',
    ),
    MovementVisual(
      movementName: 'Toe flex',
      representation: 'visuals/toe-flex.mp4',
      thumbnail: 'visuals/thumbnails/toe-flex.jpg',
    ),
    MovementVisual(
      movementName: 'Small shoulder circles',
      representation: 'visuals/small-shoulder-circles.mp4',
      thumbnail: 'visuals/thumbnails/small-shoulder-circles.jpg',
    ),
    MovementVisual(
      movementName: 'Large arm circles',
      representation: 'visuals/large-arm-circles.mp4',
      thumbnail: 'visuals/thumbnails/large-arm-circles.jpg',
    ),
    MovementVisual(
      movementName: 'Ankle stretch',
      representation: 'visuals/ankle-stretch.mp4',
      thumbnail: 'visuals/thumbnails/ankle-stretch.jpg',
    ),
  ],
);

/// The first working list. New catalog entries are not added here.
List<MyExercise> seedExercises(MovementCatalog catalog) {
  const names = [
    'Arch roll',
    'Toe flex',
    'Small shoulder circles',
    'Large arm circles',
    'Ankle stretch',
  ];
  return [
    for (final name in names)
      MyExercise.from(catalog.byName(name), starred: true),
  ];
}
