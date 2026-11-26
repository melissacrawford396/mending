import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import 'figure_layout.dart';
import 'theme.dart';

/// Hover and selection live with the parent so a side panel can follow them.
class BodyFigure extends StatelessWidget {
  const BodyFigure({
    super.key,
    required this.side,
    required this.hovered,
    required this.selected,
    required this.onHover,
    required this.onSelected,
  });

  final FigureSide side;
  final BodyArea? hovered;
  final BodyArea? selected;
  final ValueChanged<BodyArea?> onHover;
  final ValueChanged<BodyArea> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        const aspect = figureWidth / figureHeight;
        var width = maxW;
        var height = width / aspect;
        if (height > maxH) {
          height = maxH;
          width = height * aspect;
        }
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: FigurePainter(
                    side: side,
                    hovered: hovered,
                    selected: selected,
                  ),
                ),
                _Targets(
                  side: side,
                  size: Size(width, height),
                  onHover: onHover,
                  onSelected: onSelected,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Targets extends StatefulWidget {
  const _Targets({
    required this.side,
    required this.size,
    required this.onHover,
    required this.onSelected,
  });

  final FigureSide side;
  final Size size;
  final ValueChanged<BodyArea?> onHover;
  final ValueChanged<BodyArea> onSelected;

  @override
  State<_Targets> createState() => _TargetsState();
}

class _TargetsState extends State<_Targets> {
  var _touch = false;

  @override
  Widget build(BuildContext context) {
    final targets = widget.side == FigureSide.front
        ? frontPieces
        : backFillPieces;
    final inset = figureStroke(widget.size);
    return Stack(
      children: [
        for (final piece in targets)
          for (final design in piece.rects)
            Positioned.fromRect(
              rect: mapDesignRect(widget.size, design, inset: inset),
              child: Semantics(
                button: true,
                label: piece.area.label,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => widget.onHover(piece.area),
                  onExit: (_) => widget.onHover(null),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      _touch = details.kind != PointerDeviceKind.mouse;
                      widget.onHover(piece.area);
                    },
                    onTapCancel: () {
                      if (_touch) widget.onHover(null);
                    },
                    onTapUp: (_) {
                      widget.onSelected(piece.area);
                      if (_touch) widget.onHover(null);
                    },
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class FigurePainter extends CustomPainter {
  FigurePainter({required this.side, this.hovered, this.selected});

  final FigureSide side;
  final BodyArea? hovered;
  final BodyArea? selected;

  bool get minimized => selected != null;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = figureStroke(size);
    final pieces = side == FigureSide.front
        ? frontPieces
        : [...backOutlinePieces, ...backFillPieces];
    for (final piece in pieces) {
      final target = side == FigureSide.front || backFillPieces.contains(piece);
      final isSelected = target && piece.area == selected;
      final isHovered = target && piece.area == hovered;

      Color? fill;
      Color? label;
      var strokeColor = mendingInk;
      if (isSelected) {
        fill = mendingBlue;
        label = Colors.white;
      } else if (minimized) {
        strokeColor = mendingInk.withValues(alpha: 0.35);
        if (isHovered) {
          fill = mendingBlue.withValues(alpha: 0.25);
          label = mendingInk;
        }
      } else if (target) {
        fill = isHovered ? mendingBlue : Colors.white;
        label = isHovered ? Colors.white : mendingInk;
      }

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = inset
        ..color = strokeColor;
      for (final design in piece.rects) {
        final mapped = mapDesignRect(size, design, inset: inset);
        final radius = piece.circle
            ? Radius.circular(mapped.shortestSide / 2)
            : Radius.circular(piece.radius / figureWidth * size.width);
        final rrect = RRect.fromRectAndRadius(mapped, radius);
        if (fill != null) canvas.drawRRect(rrect, Paint()..color = fill);
        canvas.drawRRect(rrect, stroke);
        if (label != null) {
          _paintLabel(canvas, mapped, piece.area.label, label);
        }
      }
    }
  }

  void _paintLabel(Canvas canvas, Rect rect, String text, Color color) {
    var fontSize = rect.height * 0.34;
    if (fontSize > 15) fontSize = 15;
    if (fontSize < 8) fontSize = 8;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    )..layout();
    if (painter.width > rect.width - 4 && painter.width > 0) {
      final fitted = fontSize * ((rect.width - 4) / painter.width);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fitted < 7 ? 7 : fitted,
          fontWeight: FontWeight.w700,
        ),
      );
      painter.layout();
    }
    final offset = Offset(
      rect.center.dx - painter.width / 2,
      rect.center.dy - painter.height / 2,
    );
    canvas.save();
    canvas.clipRect(rect.deflate(1));
    painter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(FigurePainter oldDelegate) {
    return oldDelegate.side != side ||
        oldDelegate.hovered != hovered ||
        oldDelegate.selected != selected;
  }
}

/// Whole-body and Other, which are not drawn on the figure.
class AreaControl extends StatefulWidget {
  const AreaControl({
    super.key,
    required this.label,
    required this.selected,
    required this.onHover,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  State<AreaControl> createState() => _AreaControlState();
}

class _AreaControlState extends State<AreaControl> {
  var hovered = false;
  var pressed = false;
  var touch = false;

  void _setHover(bool value) {
    setState(() => hovered = value);
    widget.onHover(value);
  }

  @override
  Widget build(BuildContext context) {
    final hot = widget.selected || hovered || pressed;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHover(true),
        onExit: (_) {
          pressed = false;
          _setHover(false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            touch = details.kind != PointerDeviceKind.mouse;
            setState(() => pressed = true);
            if (touch) widget.onHover(true);
          },
          onTapCancel: () {
            setState(() => pressed = false);
            if (touch) widget.onHover(false);
          },
          onTapUp: (_) {
            setState(() => pressed = false);
            widget.onTap();
            if (touch) widget.onHover(false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hot ? mendingBlue : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: mendingInk, width: 2),
            ),
            child: ExcludeSemantics(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: hot ? Colors.white : mendingInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
