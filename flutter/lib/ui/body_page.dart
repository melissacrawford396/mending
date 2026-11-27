import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import 'area_movements.dart';
import 'body_figure.dart';
import 'figure_layout.dart';

const _wideBreakpoint = 720.0;
const _shrink = Duration(milliseconds: 260);

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  FigureSide side = FigureSide.front;
  BodyArea? hovered;
  BodyArea? selected;

  void _hover(BodyArea? area) {
    if (hovered == area) return;
    setState(() => hovered = area);
  }

  void _select(BodyArea area) {
    setState(() => selected = selected == area ? null : area);
  }

  void _close() => setState(() => selected = null);

  void _setSide(FigureSide value) {
    setState(() {
      side = value;
      hovered = null;
      if (selected != null && !_onFigure(selected!, value)) selected = null;
    });
  }

  bool _onFigure(BodyArea area, FigureSide side) {
    if (area == BodyArea.wholeBody || area == BodyArea.other) return true;
    final pieces = side == FigureSide.front ? frontPieces : backFillPieces;
    return pieces.any((piece) => piece.area == area);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        return wide ? _wide() : _narrow(constraints.maxHeight);
      },
    );
  }

  Widget _wide() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _figureColumn()),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: _panel()),
        ],
      ),
    );
  }

  Widget _narrow(double height) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Expanded(child: _figureColumn()),
          AnimatedSize(
            duration: _shrink,
            curve: Curves.easeOutCubic,
            child: selected == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(height: height * 0.45, child: _panel()),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _panel() {
    return AreaMovementsPanel(
      area: selected ?? hovered,
      active: selected != null,
      onClose: _close,
    );
  }

  Widget _figureColumn() {
    return Column(
      children: [
        SegmentedButton<FigureSide>(
          segments: const [
            ButtonSegment(value: FigureSide.front, label: Text('Front')),
            ButtonSegment(value: FigureSide.back, label: Text('Back')),
          ],
          selected: {side},
          onSelectionChanged: (value) => _setSide(value.first),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedFractionallySizedBox(
            duration: _shrink,
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            widthFactor: selected == null ? 1 : 0.6,
            heightFactor: selected == null ? 1 : 0.6,
            child: BodyFigure(
              side: side,
              hovered: hovered,
              selected: selected,
              onHover: _hover,
              onSelected: _select,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _control(BodyArea.wholeBody)),
            const SizedBox(width: 12),
            Expanded(child: _control(BodyArea.other)),
          ],
        ),
      ],
    );
  }

  Widget _control(BodyArea area) {
    return AreaControl(
      label: area.label,
      selected: selected == area,
      onHover: (on) => _hover(on ? area : null),
      onTap: () => _select(area),
    );
  }
}
