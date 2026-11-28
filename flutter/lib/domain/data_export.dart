import 'dart:convert';

import 'completion.dart';
import 'my_exercise.dart';

/// Working-exercise rows and the completion history, as one JSON document.
String dataExportJson({
  required List<MyExercise> exercises,
  required List<Completion> completions,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'exercises': [for (final row in exercises) row.toJson()],
    'completions': [for (final row in completions) row.toJson()],
  });
}
