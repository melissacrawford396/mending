import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import 'area_movements.dart';
import 'body_figure.dart';
import 'figure_layout.dart';

const _wideBreakpoint = 720.0;
const _shrink = Duration(milliseconds: 260);

// Layout as fractions of the page so it scales with the screen. Heights are
// of the page height, and margins are of the page width.
const _wideMargin = 0.0125;
const _wideTop = 0.01;
const _wideGap = 0.015;

const _phoneMargin = 0.04;
const _phoneTop = 0.01;
const _phoneGap = 0.017;

/// Room for Front/Back above the figure.
const _sidesFraction = 0.068;

/// The peek: the sheet's header plus the top of the first movement row.
const _peekFraction = 0.13;
const _headerFraction = 0.06;

/// The figure's size, and Front/Back's, once the sheet is full.
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
        return wide ? _wide(constraints.biggest) : _narrow(constraints.biggest);
      },
    );
  }

  Widget _wide(Size page) {
    final margin = page.width * _wideMargin;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        margin,
        page.height * _wideTop,
        margin,
        margin,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _sides(),
                SizedBox(height: page.height * _wideGap),
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
          SizedBox(width: margin),
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
    final margin = page.width * _phoneMargin;
    final gap = page.height * _phoneGap;
    final header = page.height * _headerFraction;
    final strip = page.height * _peekFraction;
    final area = Rect.fromLTRB(
      margin,
      page.height * _phoneTop,
      page.width - margin,
      page.height - strip - gap,
    );
    final sides = Rect.fromLTWH(
      area.left,
      area.top,
      area.width,
      page.height * _sidesFraction,
    );
    final big = Rect.fromLTRB(
      area.left,
      sides.bottom + gap,
      area.right,
      area.bottom,
    );
    final small = Rect.fromLTWH(
      area.left,
      area.top,
      big.width * _smallFigure,
      big.height * _smallFigure,
    );
    _peekSize = _peekFraction;
    _fullSize = ((page.height - small.bottom - gap) / page.height).clamp(
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
                  child: FittedBox(fit: BoxFit.scaleDown, child: _sides()),
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
                  headerHeight: header,
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
