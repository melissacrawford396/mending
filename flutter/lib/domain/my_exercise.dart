import 'movement_type.dart';

const currentUser = 'me';

/// A person's row for one movement. Empty overrides keep the type defaults.
class MyExercise {
  const MyExercise({
    required this.user,
    required this.movementId,
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
      movementId: movement.id,
      starred: starred,
    );
  }

  final String user;
  final String movementId;
  final int? setsOverride;
  final int? repsOverride;
  final int? cooldownOverride;
  final bool starred;

  MyExercise copyWith({bool? starred}) {
    return MyExercise(
      user: user,
      movementId: movementId,
      setsOverride: setsOverride,
      repsOverride: repsOverride,
      cooldownOverride: cooldownOverride,
      starred: starred ?? this.starred,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'movementId': movementId,
    'setsOverride': setsOverride,
    'repsOverride': repsOverride,
    'cooldownOverride': cooldownOverride,
    'starred': starred,
  };

  factory MyExercise.fromJson(Map<String, dynamic> json) {
    return MyExercise(
      user: json['user'] as String? ?? currentUser,
      movementId: json['movementId'] as String,
      setsOverride: json['setsOverride'] as int?,
      repsOverride: json['repsOverride'] as int?,
      cooldownOverride: json['cooldownOverride'] as int?,
      starred: json['starred'] as bool? ?? false,
    );
  }
}
