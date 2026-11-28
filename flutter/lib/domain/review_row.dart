import 'body_area.dart';
import 'my_exercise.dart';
import 'sensation.dart';

/// One append-only answer about an earlier completion.
class ReviewRow {
  const ReviewRow({
    required this.user,
    required this.movementId,
    required this.area,
    required this.reviewedAt,
    required this.exercisedAt,
    required this.sensation,
  });

  final String user;
  final String movementId;
  final BodyArea area;
  final DateTime reviewedAt;
  final DateTime exercisedAt;
  final Sensation sensation;

  ReviewRow copyWith({DateTime? exercisedAt}) {
    return ReviewRow(
      user: user,
      movementId: movementId,
      area: area,
      reviewedAt: reviewedAt,
      exercisedAt: exercisedAt ?? this.exercisedAt,
      sensation: sensation,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'movementId': movementId,
    'area': area.name,
    'reviewedAt': reviewedAt.toUtc().toIso8601String(),
    'exercisedAt': exercisedAt.toUtc().toIso8601String(),
    'sensation': sensation.name,
  };

  factory ReviewRow.fromJson(Map<String, dynamic> json) {
    return ReviewRow(
      user: json['user'] as String? ?? currentUser,
      movementId: json['movementId'] as String,
      area: BodyArea.parse(json['area'] as String),
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      exercisedAt: DateTime.parse(json['exercisedAt'] as String),
      sensation: Sensation.parse(json['sensation'] as String),
    );
  }
}
