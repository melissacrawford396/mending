import 'package:flutter/painting.dart';

import '../domain/body_area.dart';

const figureWidth = 100.0;
const figureHeight = 186.0;

enum FigureSide { front, back }

class FigurePiece {
  const FigurePiece({
    required this.area,
    required this.rects,
    this.circle = false,
    this.radius = 6,
  });

  final BodyArea area;
  final List<Rect> rects;
  final bool circle;
  final double radius;
}

const frontPieces = <FigurePiece>[
  FigurePiece(
    area: BodyArea.shoulders,
    rects: [Rect.fromLTWH(10, 36, 80, 16)],
    radius: 8,
  ),
  FigurePiece(area: BodyArea.chest, rects: [Rect.fromLTWH(28, 52, 44, 20)]),
  FigurePiece(
    area: BodyArea.arms,
    rects: [Rect.fromLTWH(10, 52, 18, 24), Rect.fromLTWH(72, 52, 18, 24)],
  ),
  FigurePiece(area: BodyArea.core, rects: [Rect.fromLTWH(28, 72, 44, 18)]),
  FigurePiece(
    area: BodyArea.wrists,
    rects: [Rect.fromLTWH(10, 76, 18, 12), Rect.fromLTWH(72, 76, 18, 12)],
  ),
  FigurePiece(area: BodyArea.hips, rects: [Rect.fromLTWH(28, 90, 44, 18)]),
  FigurePiece(
    area: BodyArea.hands,
    rects: [Rect.fromLTWH(4, 88, 24, 20), Rect.fromLTWH(72, 88, 24, 20)],
    radius: 12,
  ),
  FigurePiece(
    area: BodyArea.thighs,
    rects: [Rect.fromLTWH(30, 108, 16, 28), Rect.fromLTWH(54, 108, 16, 28)],
  ),
  FigurePiece(
    area: BodyArea.knees,
    rects: [Rect.fromLTWH(28, 136, 20, 14), Rect.fromLTWH(52, 136, 20, 14)],
    radius: 8,
  ),
  FigurePiece(
    area: BodyArea.calves,
    rects: [Rect.fromLTWH(32, 150, 14, 16), Rect.fromLTWH(54, 150, 14, 16)],
  ),
  FigurePiece(
    area: BodyArea.ankles,
    rects: [Rect.fromLTWH(30, 166, 18, 8), Rect.fromLTWH(52, 166, 18, 8)],
  ),
  FigurePiece(
    area: BodyArea.feet,
    rects: [Rect.fromLTWH(22, 174, 28, 12), Rect.fromLTWH(50, 174, 28, 12)],
    radius: 8,
  ),
  FigurePiece(
    area: BodyArea.neck,
    rects: [Rect.fromLTWH(43, 27, 14, 12)],
    radius: 4,
  ),
  FigurePiece(
    area: BodyArea.head,
    rects: [Rect.fromLTWH(36, 2, 28, 28)],
    circle: true,
  ),
];

const backFillPieces = <FigurePiece>[
  FigurePiece(area: BodyArea.upperBack, rects: [Rect.fromLTWH(28, 52, 44, 22)]),
  FigurePiece(area: BodyArea.lowerBack, rects: [Rect.fromLTWH(28, 74, 44, 16)]),
];

final backOutlinePieces = [
  for (final piece in frontPieces)
    if (piece.area != BodyArea.chest && piece.area != BodyArea.core) piece,
];

double figureStroke(Size size) => size.width / figureWidth * 1.8;

Rect mapDesignRect(Size size, Rect design, {required double inset}) {
  final innerW = size.width - inset * 2;
  final innerH = size.height - inset * 2;
  return Rect.fromLTWH(
    inset + design.left / figureWidth * innerW,
    inset + design.top / figureHeight * innerH,
    design.width / figureWidth * innerW,
    design.height / figureHeight * innerH,
  );
}
