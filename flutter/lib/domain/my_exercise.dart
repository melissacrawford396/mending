import 'movement_type.dart';

const currentUser = 'me';

/// A person's row for one movement. Empty overrides keep the type defaults.
class MyExercise {
  const MyExercise({
    required this.user,
    required this.movementName,
    this.setsOverride,
    this.repsOverride,
    this.cooldownOverride,
    required this.starred,
  });

  factory MyExercise.from(
    MovementType movement, {
    String user = currentUser,
    bool starred = false,
  }) {
    return MyExercise(
      user: user,
      movementName: movement.name,
      starred: starred,
    );
  }

  final String user;
  final String movementName;
  final int? setsOverride;
  final int? repsOverride;
  final int? cooldownOverride;
  final bool starred;

  MyExercise copyWith({bool? starred}) {
    return MyExercise(
      user: user,
      movementName: movementName,
      setsOverride: setsOverride,
      repsOverride: repsOverride,
      cooldownOverride: cooldownOverride,
      starred: starred ?? this.starred,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'movementName': movementName,
    'setsOverride': setsOverride,
    'repsOverride': repsOverride,
    'cooldownOverride': cooldownOverride,
    'starred': starred,
  };

  factory MyExercise.fromJson(Map<String, dynamic> json) {
    return MyExercise(
      user: json['user'] as String,
      movementName: json['movementName'] as String,
      setsOverride: json['setsOverride'] as int?,
      repsOverride: json['repsOverride'] as int?,
      cooldownOverride: json['cooldownOverride'] as int?,
      starred: json['starred'] as bool,
    );
  }
}
