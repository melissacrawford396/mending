import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import 'area_movements.dart';
import 'body_figure.dart';
import 'figure_layout.dart';

const _wideBreakpoint = 720.0;
const _shrink = Duration(milliseconds: 260);
const _pad = 16.0;
const _topPad = 8.0;
const _gap = 12.0;

/// Room for Front/Back above the figure on a phone.
const _sidesHeight = 48.0;

/// How much of the first movement row shows under the sheet's header in peek.
const _peekRow = 0.7;

/// The figure's size, and Front/Back's, once the phone sheet is full.
const _smallFigure = 0.4;
const _smallSides = 0.8;

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  FigureSide side = FigureSide.front;
  BodyArea? hovered;
  BodyArea? selected;

  final _sheet = DraggableScrollableController();

  /// The phone sheet's live size, as a fraction of the page height.
  final _extent = ValueNotifier<double>(0);
  var _peekSize = 0.0;
  var _fullSize = 1.0;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_sheetMoved);
  }

  @override
  void dispose() {
    _sheet.dispose();
    _extent.dispose();
    super.dispose();
  }

  void _sheetMoved() {
    if (_sheet.isAttached) _extent.value = _sheet.size;
  }

  void _hover(BodyArea? area) {
    if (hovered == area) return;
    setState(() => hovered = area);
  }

  void _select(BodyArea area) {
    setState(() {
      if (selected == area) {
        selected = null;
        return;
      }
      if (selected == null) _extent.value = _peekSize;
      selected = area;
    });
  }

  void _openFull(BodyArea area) {
    setState(() {
      if (selected == null) _extent.value = _peekSize;
      selected = area;
    });
    _moveSheet(_fullSize);
  }

  /// The sheet may not be built yet when it is first opened, so wait a frame.
  void _moveSheet(double size) {
    if (_sheet.isAttached) {
      _sheet.animateTo(size, duration: _shrink, curve: Curves.easeOutCubic);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheet.isAttached) return;
      _sheet.animateTo(size, duration: _shrink, curve: Curves.easeOutCubic);
    });
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
        return wide ? _wide() : _narrow(constraints.biggest);
      },
    );
  }

  Widget _wide() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pad, _topPad, _pad, _pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _sides(),
                const SizedBox(height: _gap),
                Expanded(
                  child: AnimatedFractionallySizedBox(
                    duration: _shrink,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    widthFactor: selected == null ? 1 : 0.6,
                    heightFactor: selected == null ? 1 : 0.6,
                    child: _figure(dimmed: selected != null),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _pad),
          Expanded(
            flex: 4,
            child: AreaMovementsPanel(
              area: selected ?? hovered,
              active: selected != null,
              onClose: _close,
            ),
          ),
        ],
      ),
    );
  }

  /// Closed, peek, and full. The bottom strip stays empty when closed, so the
  /// figure does not move when the peek opens.
  Widget _narrow(Size page) {
    final strip = sheetHeaderHeight + _peekRow * movementRowHeight;
    final area = Rect.fromLTRB(
      _pad,
      _topPad,
      page.width - _pad,
      page.height - strip - _gap,
    );
    final sides = Rect.fromLTWH(area.left, area.top, area.width, _sidesHeight);
    final big = Rect.fromLTRB(
      area.left,
      sides.bottom + _gap,
      area.right,
      area.bottom,
    );
    final small = Rect.fromLTWH(
      area.left,
      area.top,
      big.width * _smallFigure,
      big.height * _smallFigure,
    );
    _peekSize = (strip / page.height).clamp(0.0, 1.0);
    _fullSize = ((page.height - small.bottom - _gap) / page.height).clamp(
      _peekSize,
      1.0,
    );

    return ValueListenableBuilder<double>(
      valueListenable: _extent,
      builder: (context, extent, _) {
        final open = selected == null || _fullSize <= _peekSize
            ? 0.0
            : ((extent - _peekSize) / (_fullSize - _peekSize)).clamp(0.0, 1.0);
        final full = open > 0.01;
        final sidesAlign = Alignment.lerp(
          Alignment.topCenter,
          Alignment.topRight,
          open,
        )!;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: selected != null && !full ? _close : null,
              ),
            ),
            Positioned.fromRect(
              rect: sides,
              child: Align(
                alignment: sidesAlign,
                child: Transform.scale(
                  scale: lerpDouble(1, _smallSides, open)!,
                  alignment: sidesAlign,
                  child: _sides(),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: Rect.lerp(big, small, open)!,
              child: GestureDetector(
                behavior: full
                    ? HitTestBehavior.opaque
                    : HitTestBehavior.deferToChild,
                onTap: full ? () => _moveSheet(_peekSize) : null,
                child: IgnorePointer(
                  ignoring: full,
                  child: _figure(dimmed: full, onDoubleSelected: _openFull),
                ),
              ),
            ),
            if (selected != null)
              DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: _peekSize,
                minChildSize: _peekSize,
                maxChildSize: _fullSize,
                snap: true,
                builder: (context, scrollController) => AreaMovementsPanel(
                  area: selected,
                  active: true,
                  onClose: _close,
                  scrollController: scrollController,
                  peeking: !full,
                  onExpand: () => _moveSheet(_fullSize),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sides() {
    return SegmentedButton<FigureSide>(
      segments: const [
        ButtonSegment(value: FigureSide.front, label: Text('Front')),
        ButtonSegment(value: FigureSide.back, label: Text('Back')),
      ],
      selected: {side},
      onSelectionChanged: (value) => _setSide(value.first),
    );
  }

  Widget _figure({
    required bool dimmed,
    ValueChanged<BodyArea>? onDoubleSelected,
  }) {
    return BodyFigure(
      side: side,
      hovered: hovered,
      selected: selected,
      onHover: _hover,
      onSelected: _select,
      onDoubleSelected: onDoubleSelected,
      dimmed: dimmed,
      besideHeadLeft: _control(BodyArea.wholeBody, dimmed),
      besideHeadRight: _control(BodyArea.other, dimmed),
    );
  }

  Widget _control(BodyArea area, bool dimmed) {
    return AreaControl(
      label: area.label,
      selected: selected == area,
      dimmed: dimmed,
      onHover: (on) => _hover(on ? area : null),
      onTap: () => _select(area),
    );
  }
}
