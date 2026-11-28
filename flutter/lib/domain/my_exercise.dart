import 'movement_type.dart';

const currentUser = 'me';

const _keep = Object();

/// A person's row for one movement. Empty overrides keep the type defaults.
class MyExercise {
  const MyExercise({
    required this.user,
    required this.movementId,
    this.setsOverride,
    this.repsOverride,
    this.cooldownOverride,
    this.perDayOverride,
    this.gapHoursOverride,
    this.restOverride,
    required this.starred,
  });

  factory MyExercise.from(
    MovementType movement, {
    String user = currentUser,
    bool starred = false,
  }) {
    return MyExercise(user: user, movementId: movement.id, starred: starred);
  }

  final String user;
  final String movementId;
  final int? setsOverride;
  final int? repsOverride;
  final int? cooldownOverride;
  final int? perDayOverride;
  final int? gapHoursOverride;

  /// Seconds.
  final int? restOverride;
  final bool starred;

  /// Overrides left out keep their value. Pass null to clear one.
  MyExercise copyWith({
    bool? starred,
    Object? setsOverride = _keep,
    Object? repsOverride = _keep,
    Object? cooldownOverride = _keep,
    Object? perDayOverride = _keep,
    Object? gapHoursOverride = _keep,
    Object? restOverride = _keep,
  }) {
    int? pick(Object? next, int? current) =>
        identical(next, _keep) ? current : next as int?;
    return MyExercise(
      user: user,
      movementId: movementId,
      setsOverride: pick(setsOverride, this.setsOverride),
      repsOverride: pick(repsOverride, this.repsOverride),
      cooldownOverride: pick(cooldownOverride, this.cooldownOverride),
      perDayOverride: pick(perDayOverride, this.perDayOverride),
      gapHoursOverride: pick(gapHoursOverride, this.gapHoursOverride),
      restOverride: pick(restOverride, this.restOverride),
      starred: starred ?? this.starred,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'movementId': movementId,
    'setsOverride': setsOverride,
    'repsOverride': repsOverride,
    'cooldownOverride': cooldownOverride,
    'perDayOverride': perDayOverride,
    'gapHoursOverride': gapHoursOverride,
    'restOverride': restOverride,
    'starred': starred,
  };

  factory MyExercise.fromJson(Map<String, dynamic> json) {
    return MyExercise(
      user: json['user'] as String? ?? currentUser,
      movementId: json['movementId'] as String,
      setsOverride: json['setsOverride'] as int?,
      repsOverride: json['repsOverride'] as int?,
      cooldownOverride: json['cooldownOverride'] as int?,
      perDayOverride: json['perDayOverride'] as int?,
      gapHoursOverride: json['gapHoursOverride'] as int?,
      restOverride: json['restOverride'] as int?,
      starred: json['starred'] as bool? ?? false,
    );
  }
}
