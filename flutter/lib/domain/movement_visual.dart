/// How a movement is drawn. Paths are relative to the repo, like
/// `visuals/arch-roll.mp4`. Null until that file exists.
class MovementVisual {
  const MovementVisual({
    required this.movementId,
    this.representation,
    this.thumbnail,
  });

  factory MovementVisual.fromJson(Map<String, dynamic> json) {
    return MovementVisual(
      movementId: json['movementId'] as String,
      representation: json['representation'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );
  }

  final String movementId;

  /// The looping clip.
  final String? representation;

  /// A still frame from the clip.
  final String? thumbnail;
}
