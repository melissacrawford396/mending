import 'package:flutter/material.dart';

import '../domain/completion.dart';
import '../domain/effective.dart';
import '../state/mending_scope.dart';
import 'theme.dart';

/// Opens the editor for one logged session.
Future<void> showHistoryEditor(BuildContext context, Completion completion) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: mendingPaper,
    builder: (context) {
      final inset = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: _HistoryEditor(completion: completion),
      );
    },
  );
}

class _HistoryEditor extends StatefulWidget {
  const _HistoryEditor({required this.completion});

  final Completion completion;

  @override
  State<_HistoryEditor> createState() => _HistoryEditorState();
}

class _HistoryEditorState extends State<_HistoryEditor> {
  var _ready = false;
  var _busy = false;
  var _timed = false;
  var _name = '';
  late DateTime _date;
  late TimeOfDay _time;
  late int _sets;
  late int _reps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final local = widget.completion.completedAt.toLocal();
    _date = DateTime(local.year, local.month, local.day);
    _time = TimeOfDay(hour: local.hour, minute: local.minute);
    final movement = MendingScope.of(
      context,
    ).catalog.find(widget.completion.movementId);
    _timed = movement?.timed ?? false;
    _name = movement?.name ?? widget.completion.movementId;
    final count = widget.completion.setReps.isEmpty
        ? widget.completion.reps
        : widget.completion.setReps.first;
    _sets = widget.completion.sets.clamp(1, maxSets);
    _reps = _timed
        ? count.clamp(minHoldSeconds, maxHoldSeconds)
        : count.clamp(1, maxReps);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
  }

  void _changeSets(int delta) {
    setState(() => _sets = (_sets + delta).clamp(1, maxSets));
  }

  void _changeReps(int delta) {
    setState(() {
      _reps = _timed
          ? (_reps + delta * holdStepSeconds).clamp(
              minHoldSeconds,
              maxHoldSeconds,
            )
          : (_reps + delta).clamp(1, maxReps);
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    await MendingScope.of(context).updateCompletion(
      widget.completion.copyWith(
        completedAt: when,
        reps: _reps,
        setReps: List<int>.filled(_sets, _reps),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this exercise?'),
        content: const Text(
          'You can restore it from Recently deleted for 7 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    await MendingScope.of(context).deleteCompletion(widget.completion.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox(height: 48);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _name,
                    style: const TextStyle(
                      color: mendingInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('history-delete'),
                  tooltip: 'Delete',
                  onPressed: _delete,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            _PickerRow(
              label: 'Date',
              value: _dateLabel(_date),
              onTap: _pickDate,
            ),
            _PickerRow(
              label: 'Time',
              value: _clock(_time.hour, _time.minute),
              onTap: _pickTime,
            ),
            _StepperRow(
              label: 'Sets',
              value: '$_sets',
              onRemove: _sets > 1 ? () => _changeSets(-1) : null,
              onAdd: _sets < maxSets ? () => _changeSets(1) : null,
            ),
            _StepperRow(
              label: _timed ? 'Hold' : 'Reps',
              value: _timed ? restLabel(_reps) : '$_reps',
              onRemove: _reps > (_timed ? minHoldSeconds : 1)
                  ? () => _changeReps(-1)
                  : null,
              onAdd: _reps < (_timed ? maxHoldSeconds : maxReps)
                  ? () => _changeReps(1)
                  : null,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 64, child: Text(label, style: _labelStyle)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: mendingInk, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onRemove,
    required this.onAdd,
  });

  final String label;
  final String value;
  final VoidCallback? onRemove;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: _labelStyle)),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.remove)),
        SizedBox(
          width: 72,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mendingInk, fontSize: 16),
          ),
        ),
        IconButton(onPressed: onAdd, icon: const Icon(Icons.add)),
      ],
    );
  }
}

const _labelStyle = TextStyle(color: mendingInk, fontWeight: FontWeight.w700);

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

String _dateLabel(DateTime date) {
  return '${_shortMonths[date.month - 1]} ${date.day}, ${date.year}';
}

String _clock(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
