import 'package:flutter/material.dart';

import '../domain/body_area.dart';
import '../domain/my_exercise.dart';
import '../domain/review_prompt.dart';
import '../domain/review_row.dart';
import '../domain/sensation.dart';
import '../state/app_model.dart';
import '../state/mending_scope.dart';
import 'theme.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.pending});

  final PendingReview pending;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _Answer {
  _Answer(this.area);

  BodyArea area;
  Sensation? sensation;
}

class _ReviewPageState extends State<ReviewPage> {
  late final Map<String, _Answer> answers = {
    for (final item in widget.pending.items)
      item.exerciseName: _Answer(
        MendingScope.of(context).catalog.find(item.exerciseName)?.area ??
            BodyArea.other,
      ),
  };

  bool get canSave => answers.values.any((answer) => answer.sensation != null);

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Last time')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Did a body part hurt, or feel off? You can skip this. Skipping saves nothing.',
              style: TextStyle(color: mendingInk, height: 1.35),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                for (final item in widget.pending.items)
                  _ReviewCard(
                    name: item.exerciseName,
                    when: shortDate(item.completedAt),
                    answer: answers[item.exerciseName]!,
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              TextButton(
                onPressed: () => _skip(model),
                child: const Text('Skip'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: canSave ? () => _save(model) : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _skip(AppModel model) async {
    await model.skipReview(widget.pending.sessionKey);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _save(AppModel model) async {
    final reviewedAt = model.now();
    final rows = <ReviewRow>[];
    for (final item in widget.pending.items) {
      final answer = answers[item.exerciseName]!;
      final sensation = answer.sensation;
      if (sensation == null) continue;
      rows.add(
        ReviewRow(
          user: currentUser,
          exerciseName: item.exerciseName,
          area: answer.area,
          reviewedAt: reviewedAt,
          exercisedAt: item.completedAt,
          sensation: sensation,
        ),
      );
    }
    await model.addReviews(rows);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.when,
    required this.answer,
    required this.onChanged,
  });

  final String name;
  final String when;
  final _Answer answer;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: mendingInk.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: mendingInk,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              when,
              style: TextStyle(color: mendingInk.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            const Text(
              'How it feels',
              style: TextStyle(color: mendingInk, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sensation in Sensation.values)
                  ChoiceChip(
                    label: Text(sensation.label),
                    selected: answer.sensation == sensation,
                    onSelected: (selected) {
                      answer.sensation = selected ? sensation : null;
                      onChanged();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Body part',
              style: TextStyle(color: mendingInk, fontWeight: FontWeight.w700),
            ),
            DropdownButton<BodyArea>(
              value: answer.area,
              isExpanded: true,
              items: [
                for (final area in BodyArea.values)
                  DropdownMenuItem(value: area, child: Text(area.label)),
              ],
              onChanged: (area) {
                if (area == null) return;
                answer.area = area;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
