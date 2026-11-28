import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/catalog.dart';
import 'package:mending/data/store.dart';
import 'package:mending/domain/completion.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/main.dart';
import 'package:mending/state/app_model.dart';
import 'package:mending/ui/history_page.dart';

import 'test_catalog.dart';

void main() {
  final now = DateTime(2026, 11, 25, 18);

  Completion session(String movementId, DateTime at) {
    return Completion(
      user: currentUser,
      movementId: movementId,
      completedAt: at,
      sets: 1,
      reps: 10,
    );
  }

  StoreData logged(List<Completion> rows) {
    return StoreData(
      initialized: true,
      exercises: seedExercises(testCatalog),
      completions: rows,
      reviews: const [],
      skippedReviewSession: null,
    );
  }

  Future<AppModel> start(WidgetTester tester, StoreData initial) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final model = AppModel(
      store: MemoryMendingStore(initial),
      catalog: testCatalog,
      now: () => now,
    );
    await model.load();
    await tester.pumpWidget(MendingApp(model: model));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return model;
  }

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('one circle opens the editor and delete asks first', (
    tester,
  ) async {
    final model = await start(
      tester,
      logged([session('toe-flex', DateTime(2026, 11, 25, 8))]),
    );
    await openHistory(tester);

    expect(find.byType(HistoryMark), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-day-2026-11-25')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete this exercise?'), findsOneWidget);
    expect(model.completions, hasLength(1));

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete this exercise?'), findsNothing);
    expect(model.completions, hasLength(1));
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(model.completions, isEmpty);
    expect(model.deleted, hasLength(1));
    expect(find.byType(HistoryMark), findsNothing);

    await tester.tap(find.byKey(const Key('history-mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('history-choice-deleted')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nothing deleted in the last 7 days.'), findsNothing);
    await tester.tap(find.text('Restore'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('history-mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('history-choice-all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(model.completions, hasLength(1));
    expect(model.deleted, isEmpty);
    expect(find.byType(HistoryMark), findsOneWidget);
  });

  testWidgets('several circles on a day open that day', (tester) async {
    await start(
      tester,
      logged([
        session('toe-flex', DateTime(2026, 11, 25, 8)),
        session('arch-roll', DateTime(2026, 11, 25, 9)),
      ]),
    );
    await openHistory(tester);

    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('December 2026'), findsOneWidget);
    expect(find.text('January 2027'), findsNothing);
    final day = tester.getSize(
      find.byKey(const ValueKey('history-day-2026-11-25')),
    );
    expect(day.height, greaterThan(day.width));
    expect(find.byType(HistoryMark), findsNWidgets(2));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1600));
    await tester.pump();
    expect(find.text('October 2026'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
    await tester.pump();
    await tester.tap(find.byKey(const Key('history-mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('history-choice-toe-flex')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HistoryMark), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('history-choice-all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('history-day-2026-11-25')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('history-day-zoom')), findsOneWidget);
    expect(find.text('Nov 25'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });
}
