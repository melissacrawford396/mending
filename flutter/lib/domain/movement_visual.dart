/// How a movement is drawn. Paths are relative to the repo, like
/// `visuals/arch-roll.mp4`. Null until that file exists.
class MovementVisual {
  const MovementVisual({
    required this.movementName,
    this.representation,
    this.thumbnail,
  });

  final String movementName;

  /// The looping clip.
  final String? representation;

  /// A still frame from the clip.
  final String? thumbnail;
}
