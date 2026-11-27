import 'body_area.dart';
import 'sensation.dart';

/// One append-only answer about an earlier completion.
class ReviewRow {
  const ReviewRow({
    required this.user,
    required this.exerciseName,
    required this.area,
    required this.reviewedAt,
    required this.exercisedAt,
    required this.sensation,
  });

  final String user;
  final String exerciseName;
  final BodyArea area;
  final DateTime reviewedAt;
  final DateTime exercisedAt;
  final Sensation sensation;

  Map<String, dynamic> toJson() => {
    'user': user,
    'exerciseName': exerciseName,
    'area': area.name,
    'reviewedAt': reviewedAt.toUtc().toIso8601String(),
    'exercisedAt': exercisedAt.toUtc().toIso8601String(),
    'sensation': sensation.name,
  };

  factory ReviewRow.fromJson(Map<String, dynamic> json) {
    return ReviewRow(
      user: json['user'] as String,
      exerciseName: json['exerciseName'] as String,
      area: BodyArea.parse(json['area'] as String),
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      exercisedAt: DateTime.parse(json['exercisedAt'] as String),
      sensation: Sensation.parse(json['sensation'] as String),
    );
  }
}
