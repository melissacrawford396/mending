import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import 'figure_layout.dart';
import 'theme.dart';

/// The head's band in design units. The side slots sit level with it.
const _headLeft = 36.0;
const _headRight = 64.0;
const _headTop = 2.0;
const _headBottom = 30.0;
const _slotGap = 6.0;

/// Hover and selection live with the parent so a side panel can follow them.
///
/// Taps in the gaps between parts fall through to whatever is behind.
class BodyFigure extends StatelessWidget {
  const BodyFigure({
    super.key,
    required this.side,
    required this.hovered,
    required this.selected,
    required this.onHover,
    required this.onSelected,
    this.onDoubleSelected,
    this.dimmed = false,
    this.besideHeadLeft,
    this.besideHeadRight,
  });

  final FigureSide side;
  final BodyArea? hovered;
  final BodyArea? selected;
  final ValueChanged<BodyArea?> onHover;
  final ValueChanged<BodyArea> onSelected;

  /// A second tap on the same part, inside the double-tap window. The first
  /// tap has already gone to [onSelected].
  final ValueChanged<BodyArea>? onDoubleSelected;
  final bool dimmed;
  final Widget? besideHeadLeft;
  final Widget? besideHeadRight;

  @override
  Widget build(BuildContext context) {
    final colors = context.mending;
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
        final left = (maxW - width) / 2;
        final top = (maxH - height) / 2;
        final size = Size(width, height);
        final inset = figureStroke(size);
        final head = mapDesignRect(
          size,
          const Rect.fromLTRB(_headLeft, _headTop, _headRight, _headBottom),
          inset: inset,
        );
        final gap = _slotGap / figureWidth * width;
        return SizedBox(
          width: maxW,
          height: maxH,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
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
                        dimmed: dimmed,
                        colors: colors,
                      ),
                    ),
                    _Targets(
                      side: side,
                      size: size,
                      onHover: onHover,
                      onSelected: onSelected,
                      onDoubleSelected: onDoubleSelected,
                    ),
                  ],
                ),
              ),
              if (besideHeadLeft != null)
                Positioned(
                  left: 0,
                  width: left + head.left - gap,
                  top: top + head.top,
                  height: head.height,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: besideHeadLeft,
                    ),
                  ),
                ),
              if (besideHeadRight != null)
                Positioned(
                  left: left + head.right + gap,
                  right: 0,
                  top: top + head.top,
                  height: head.height,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: besideHeadRight,
                    ),
                  ),
                ),
            ],
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
    this.onDoubleSelected,
  });

  final FigureSide side;
  final Size size;
  final ValueChanged<BodyArea?> onHover;
  final ValueChanged<BodyArea> onSelected;
  final ValueChanged<BodyArea>? onDoubleSelected;

  @override
  State<_Targets> createState() => _TargetsState();
}

class _TargetsState extends State<_Targets> {
  var _touch = false;
  BodyArea? _lastArea;
  Timer? _window;

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  void _tapped(BodyArea area) {
    final onDouble = widget.onDoubleSelected;
    if (onDouble != null && _window != null && _lastArea == area) {
      _window!.cancel();
      _window = null;
      _lastArea = null;
      onDouble(area);
      return;
    }
    _window?.cancel();
    _lastArea = area;
    _window = Timer(kDoubleTapTimeout, () {
      _window = null;
      _lastArea = null;
    });
    widget.onSelected(area);
  }

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
                      _tapped(piece.area);
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
  FigurePainter({
    required this.side,
    required this.colors,
    this.hovered,
    this.selected,
    this.dimmed = false,
  });

  final FigureSide side;
  final MendingColors colors;
  final BodyArea? hovered;
  final BodyArea? selected;
  final bool dimmed;

  @override
  bool? hitTest(Offset position) => false;

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
      var strokeColor = colors.ink;
      if (isSelected) {
        fill = colors.blue;
        label = Colors.white;
      } else if (dimmed) {
        strokeColor = colors.ink.withValues(alpha: 0.35);
        if (isHovered) {
          fill = colors.blue.withValues(alpha: 0.25);
          label = colors.ink;
        }
      } else if (target) {
        fill = isHovered ? colors.blue : colors.figureFill;
        label = isHovered ? Colors.white : colors.ink;
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
        oldDelegate.selected != selected ||
        oldDelegate.dimmed != dimmed ||
        oldDelegate.colors != colors;
  }
}

/// Whole-body and Other, which are not drawn on the figure. Small pills that
/// sit beside the head.
class AreaControl extends StatefulWidget {
  const AreaControl({
    super.key,
    required this.label,
    required this.selected,
    required this.onHover,
    required this.onTap,
    this.dimmed = false,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final bool dimmed;

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
    final colors = context.mending;
    final hot = widget.selected || (!widget.dimmed && (hovered || pressed));
    final ink = widget.dimmed ? colors.ink.withValues(alpha: 0.35) : colors.ink;
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: hot ? colors.blue : colors.figureFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: hot ? colors.blue : ink, width: 1.5),
            ),
            child: ExcludeSemantics(
              child: Text(
                widget.label,
                maxLines: 1,
                style: TextStyle(
                  color: hot ? Colors.white : ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
