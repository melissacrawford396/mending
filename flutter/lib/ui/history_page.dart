import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/completion.dart';
import '../domain/my_exercise.dart';
import '../domain/review_prompt.dart';
import '../state/app_model.dart';
import '../state/mending_scope.dart';
import 'history_editor.dart';
import 'theme.dart';

const _titleHeight = 36.0;
const _weekdayHeight = 22.0;
const _pastMonths = 18;
const _futureMonths = 7;
const _monthPage = 12;

const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// One color per [BodyArea], in enum order.
const _areaColors = <Color>[
  Color(0xFF2F6FED),
  Color(0xFF6D28D9),
  Color(0xFF0F766E),
  Color(0xFFC2410C),
  Color(0xFF9A3412),
  Color(0xFF1D4ED8),
  Color(0xFFBE185D),
  Color(0xFF047857),
  Color(0xFF7C3AED),
  Color(0xFFB45309),
  Color(0xFF0E7490),
  Color(0xFF9F1239),
  Color(0xFF3F6212),
  Color(0xFF1E40AF),
  Color(0xFFA21CAF),
  Color(0xFF155E75),
  Color(0xFFA16207),
  Color(0xFF4C1D95),
];

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _Choice {
  const _Choice.all() : deleted = false, movementId = null;
  const _Choice.deleted() : deleted = true, movementId = null;
  const _Choice.exercise(this.movementId) : deleted = false;

  final bool deleted;
  final String? movementId;
}

class _HistoryPageState extends State<HistoryPage> {
  var _showDeleted = false;
  String? _movementId;

  Future<void> _pick(AppModel model) async {
    final choice = await showModalBottomSheet<_Choice>(
      context: context,
      showDragHandle: true,
      backgroundColor: mendingPaper,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.6;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: ListView(
              children: [
                _choiceTile(
                  key: const Key('history-choice-all'),
                  title: 'All exercises',
                  selected: !_showDeleted && _movementId == null,
                  onTap: () => Navigator.of(context).pop(const _Choice.all()),
                ),
                _choiceTile(
                  key: const Key('history-choice-deleted'),
                  title: 'Recently deleted',
                  selected: _showDeleted,
                  onTap: () =>
                      Navigator.of(context).pop(const _Choice.deleted()),
                ),
                const Divider(),
                for (final movement in model.catalog.movements)
                  _choiceTile(
                    key: Key('history-choice-${movement.id}'),
                    title: movement.name,
                    selected: !_showDeleted && _movementId == movement.id,
                    onTap: () => Navigator.of(
                      context,
                    ).pop(_Choice.exercise(movement.id)),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    setState(() {
      _showDeleted = choice.deleted;
      _movementId = choice.movementId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final label = _showDeleted
        ? 'Recently deleted'
        : _movementId == null
        ? 'All exercises'
        : model.catalog.find(_movementId!)?.name ?? _movementId!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('history-mode'),
              onPressed: () => _pick(model),
              icon: const Icon(Icons.arrow_drop_down),
              label: Text(label),
            ),
          ),
        ),
        Expanded(
          child: _showDeleted
              ? _DeletedList(model: model)
              : _HistoryCalendar(
                  today: model.now(),
                  byDay: _byDay(model.completions, movementId: _movementId),
                  byArea: _movementId == null,
                  onDay: _openDay,
                ),
        ),
      ],
    );
  }

  void _openDay(DateTime day, List<Completion> rows) {
    if (rows.length == 1) {
      showHistoryEditor(context, rows.single);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryDayPage(day: day, movementId: _movementId),
      ),
    );
  }
}

Widget _choiceTile({
  required Key key,
  required String title,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ListTile(
    key: key,
    title: Text(title),
    trailing: selected ? const Icon(Icons.check, color: mendingBlue) : null,
    onTap: onTap,
  );
}

class _DeletedList extends StatelessWidget {
  const _DeletedList({required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final row in model.deleted)
        if (row.completion.user == currentUser) row,
    ]..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nothing deleted in the last 7 days.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mendingInk, fontSize: 16),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      children: [
        for (final row in rows)
          ListTile(
            title: Text(_movementName(model, row.completion.movementId)),
            subtitle: Text(
              '${shortDate(row.completion.completedAt)} · ${setsRepsLabel(row.completion.setReps, seconds: model.catalog.find(row.completion.movementId)?.timed ?? false)}',
            ),
            trailing: TextButton(
              onPressed: () => model.restoreCompletion(row.completion.id),
              child: const Text('Restore'),
            ),
          ),
      ],
    );
  }
}

/// The sessions on [day], each circle large enough to select on its own.
class HistoryDayPage extends StatelessWidget {
  const HistoryDayPage({super.key, required this.day, this.movementId});

  final DateTime day;
  final String? movementId;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final rows =
        _byDay(model.completions, movementId: movementId)[sessionKeyFor(day)] ??
        const <Completion>[];
    final byArea = movementId == null;
    return Scaffold(
      key: const Key('history-day-zoom'),
      appBar: AppBar(title: Text(_dayTitle(day))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final row in rows)
            _DaySession(row: row, byArea: byArea, model: model),
        ],
      ),
    );
  }
}

class _DaySession extends StatelessWidget {
  const _DaySession({
    required this.row,
    required this.byArea,
    required this.model,
  });

  final Completion row;
  final bool byArea;
  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final local = row.completedAt.toLocal();
    final movement = model.catalog.find(row.movementId);
    return InkWell(
      onTap: () => showHistoryEditor(context, row),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            HistoryMark(
              color: _markColor(model, row, byArea: byArea),
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (byArea)
                    Text(
                      _movementName(model, row.movementId),
                      style: const TextStyle(
                        color: mendingInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    _clock(local.hour, local.minute),
                    style: const TextStyle(color: mendingInk, fontSize: 16),
                  ),
                  Text(
                    setsRepsLabel(
                      row.setReps,
                      seconds: movement?.timed ?? false,
                    ),
                    style: TextStyle(color: mendingInk.withValues(alpha: 0.72)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A finger move and a fling both cover less ground than the default.
class _SlowCalendarPhysics extends BouncingScrollPhysics {
  const _SlowCalendarPhysics({super.parent});

  static const _dragScale = 0.6;
  static const _flingScale = 0.35;

  @override
  _SlowCalendarPhysics applyTo(ScrollPhysics? ancestor) {
    return _SlowCalendarPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset * _dragScale);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return super.createBallisticSimulation(position, velocity * _flingScale);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    return parent?.applyBoundaryConditions(position, value) ?? 0.0;
  }
}

/// Six weeks of this month fill the screen, leaving the next month's title
/// and one week showing underneath.
double _monthExtent(double height) {
  const headers = _titleHeight + _weekdayHeight;
  final room = height - 2 * headers;
  if (room <= 7) return headers + 6 * 48;
  return headers + 6 * (room / 7);
}

class _HistoryCalendar extends StatefulWidget {
  const _HistoryCalendar({
    required this.today,
    required this.byDay,
    required this.byArea,
    required this.onDay,
  });

  final DateTime today;
  final Map<String, List<Completion>> byDay;
  final bool byArea;
  final void Function(DateTime day, List<Completion> rows) onDay;

  @override
  State<_HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends State<_HistoryCalendar> {
  final _controller = ScrollController();
  static const _nowKey = Key('history-now');
  var _past = _pastMonths;
  var _future = _futureMonths;
  var _extent = 0.0;
  var _ready = false;
  var _growing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ready = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_ready || _growing || _extent == 0 || !_controller.hasClients) return;
    final position = _controller.position;
    final edge = _extent * 2;
    if (position.pixels - position.minScrollExtent < edge) {
      _growing = true;
      setState(() => _past += _monthPage);
      WidgetsBinding.instance.addPostFrameCallback((_) => _growing = false);
    } else if (position.maxScrollExtent - position.pixels < edge) {
      _growing = true;
      setState(() => _future += _monthPage);
      WidgetsBinding.instance.addPostFrameCallback((_) => _growing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width < 7 || height < 7) return const SizedBox.shrink();
        _extent = _monthExtent(height);
        final today = widget.today;
        return CustomScrollView(
          controller: _controller,
          physics: const _SlowCalendarPhysics(),
          center: _nowKey,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _MonthGrid(
                  month: DateTime(today.year, today.month - 1 - index),
                  extent: _extent,
                  byDay: widget.byDay,
                  byArea: widget.byArea,
                  onDay: widget.onDay,
                );
              }, childCount: _past),
            ),
            SliverList(
              key: _nowKey,
              delegate: SliverChildBuilderDelegate((context, index) {
                return _MonthGrid(
                  month: DateTime(today.year, today.month + index),
                  extent: _extent,
                  byDay: widget.byDay,
                  byArea: widget.byArea,
                  onDay: widget.onDay,
                );
              }, childCount: _future),
            ),
          ],
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.extent,
    required this.byDay,
    required this.byArea,
    required this.onDay,
  });

  final DateTime month;
  final double extent;
  final Map<String, List<Completion>> byDay;
  final bool byArea;
  final void Function(DateTime day, List<Completion> rows) onDay;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final first = DateTime(month.year, month.month, 1);
    final start = _weekStart(first);
    return SizedBox(
      height: extent,
      child: Column(
        children: [
          SizedBox(
            height: _titleHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_monthNames[month.month - 1]} ${month.year}',
                  style: const TextStyle(
                    color: mendingInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: _weekdayHeight,
            child: Row(
              children: [
                for (final label in _weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: mendingInk.withValues(alpha: 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (var week = 0; week < 6; week++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var day = 0; day < 7; day++)
                          Expanded(
                            child: _DayCell(
                              day: start.add(Duration(days: week * 7 + day)),
                              month: month.month,
                              rowsFor: byDay,
                              byArea: byArea,
                              model: model,
                              onDay: onDay,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.month,
    required this.rowsFor,
    required this.byArea,
    required this.model,
    required this.onDay,
  });

  final DateTime day;
  final int month;
  final Map<String, List<Completion>> rowsFor;
  final bool byArea;
  final AppModel model;
  final void Function(DateTime day, List<Completion> rows) onDay;

  @override
  Widget build(BuildContext context) {
    final inMonth = day.month == month;
    final rows = inMonth
        ? (rowsFor[sessionKeyFor(day)] ?? const <Completion>[])
        : const <Completion>[];
    final body = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: inMonth ? mendingInk : mendingInk.withValues(alpha: 0.28),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (inMonth)
            Expanded(
              child: rows.isEmpty
                  ? const SizedBox.shrink()
                  : _MarkRow(
                      rows: rows,
                      colorFor: (row) => _markColor(model, row, byArea: byArea),
                    ),
            ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: mendingInk.withValues(alpha: 0.08)),
      ),
      child: inMonth
          ? InkWell(
              key: ValueKey('history-day-${sessionKeyFor(day)}'),
              onTap: rows.isEmpty ? null : () => onDay(day, rows),
              child: body,
            )
          : body,
    );
  }
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({required this.rows, required this.colorFor});

  final List<Completion> rows;
  final Color Function(Completion row) colorFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 2.0;
        final count = rows.length;
        final maxSide = math.min(18.0, math.max(0.0, constraints.maxHeight));
        final room = math.max(0.0, constraints.maxWidth - 4);
        final side = math.min(
          maxSide,
          math.max(2.0, (room - gap * math.max(0, count - 1)) / count),
        );
        return ClipRect(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final row in rows)
                HistoryMark(
                  key: ValueKey('history-mark-${row.id}'),
                  color: colorFor(row),
                  size: side,
                ),
            ],
          ),
        );
      },
    );
  }
}

class HistoryMark extends StatelessWidget {
  const HistoryMark({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Sunday on or before [day]. Weeks start on Sunday.
DateTime _weekStart(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  return date.subtract(Duration(days: date.weekday % 7));
}

String _dayTitle(DateTime day) {
  return '${_shortMonths[day.month - 1]} ${day.day}';
}

String _clock(int hour, int minute) {
  final h = hour.toString().padLeft(2, '0');
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _movementName(AppModel model, String movementId) {
  return model.catalog.find(movementId)?.name ?? movementId;
}

Color _markColor(AppModel model, Completion row, {required bool byArea}) {
  if (!byArea) return mendingBlue;
  final area = model.catalog.find(row.movementId)?.area;
  if (area == null) return mendingBlue;
  return _areaColors[area.index % _areaColors.length];
}

Map<String, List<Completion>> _byDay(
  List<Completion> rows, {
  String? movementId,
}) {
  final map = <String, List<Completion>>{};
  for (final row in rows) {
    if (row.user != currentUser) continue;
    if (movementId != null && row.movementId != movementId) continue;
    (map[sessionKeyFor(row.completedAt)] ??= []).add(row);
  }
  for (final list in map.values) {
    list.sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }
  return map;
}
