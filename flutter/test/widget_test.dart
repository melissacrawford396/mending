import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/catalog.dart';
import 'package:mending/data/store.dart';
import 'package:mending/domain/body_area.dart';
import 'package:mending/domain/completion.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/domain/sensation.dart';
import 'package:mending/main.dart';
import 'package:mending/state/app_model.dart';
import 'package:mending/ui/body_figure.dart';

void main() {
  Future<AppModel> start(
    WidgetTester tester, {
    StoreData? initial,
    DateTime Function()? now,
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final model = AppModel(
      store: MemoryMendingStore(initial),
      catalog: movementCatalog,
      now: now,
    );
    await model.load();
    await tester.pumpWidget(MendingApp(model: model));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return model;
  }

  testWidgets('starred movements start ready', (tester) async {
    await start(tester);
    expect(find.text('Arch roll'), findsOneWidget);
    expect(find.text('Toe flex'), findsOneWidget);
    expect(find.text('Small shoulder circles'), findsOneWidget);
    expect(find.text('Large arm circles'), findsOneWidget);
    expect(find.text('Ankle stretch'), findsOneWidget);
    expect(find.text('Ready'), findsWidgets);
  });

  testWidgets('marking a movement done starts its countdown', (tester) async {
    final model = await start(tester, now: () => DateTime(2026, 11, 25, 8));
    await tester.tap(find.text('Arch roll'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Visual later'), findsOneWidget);
    expect(find.textContaining('lacrosse ball'), findsOneWidget);

    await tester.ensureVisible(find.text('Mark done'));
    await tester.tap(find.text('Mark done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(model.completions.single.exerciseName, 'Arch roll');
    expect(model.completions.single.sets, 1);
    expect(model.completions.single.reps, 10);
    expect(find.text('Ready in 2 days'), findsWidgets);
  });

  testWidgets('a sets override can return to the default', (tester) async {
    final model = await start(tester);
    await tester.tap(find.text('Arch roll'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.byKey(const Key('sets-add')));
    await tester.tap(find.byKey(const Key('sets-add')));
    await tester.pump();
    expect(model.findExercise('Arch roll')!.setsOverride, 2);

    await tester.tap(find.text('Use default'));
    await tester.pump();
    expect(model.findExercise('Arch roll')!.setsOverride, isNull);
    expect(model.findExercise('Arch roll')!.starred, isTrue);
  });

  testWidgets('tapping a body part opens its list and an empty back region', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Body'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Feet').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Toe flex'), findsOneWidget);

    await tester.tap(find.text('Toe flex'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.widgetWithText(AppBar, 'Toe flex'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Upper back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No movements for Upper back yet.'), findsOneWidget);
  });

  testWidgets('hover previews movements, starred first, and click selects', (
    tester,
  ) async {
    final model = await start(tester, size: const Size(1280, 800));
    await model.setStarred(movementCatalog.byName('Arch roll'), false);
    await tester.tap(find.text('Body'));
    await tester.pump();
    expect(
      find.text('Point at a body part to see its movements.'),
      findsOneWidget,
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final feet = find.bySemanticsLabel('Feet').first;
    await mouse.moveTo(tester.getCenter(feet));
    await tester.pump();

    expect(find.text('Click to choose'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Toe flex')).dy,
      lessThan(tester.getTopLeft(find.text('Arch roll')).dy),
    );
    expect(
      find.ancestor(
        of: find.text('Toe flex'),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
    expect(find.byTooltip('Unstar'), findsNothing);

    final before = tester.getSize(find.byType(BodyFigure));
    await mouse.down(tester.getCenter(feet));
    await mouse.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Click to choose'), findsNothing);
    expect(find.byTooltip('Unstar'), findsOneWidget);
    expect(find.byTooltip('Star'), findsOneWidget);
    expect(
      tester.getSize(find.byType(BodyFigure)).height,
      lessThan(before.height),
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Close'), findsNothing);
  });

  testWidgets('skipping a review writes nothing', (tester) async {
    final store = MemoryMendingStore(
      StoreData(
        initialized: true,
        exercises: seedExercises(movementCatalog),
        completions: [
          Completion(
            user: currentUser,
            exerciseName: 'Toe flex',
            completedAt: DateTime(2026, 11, 24, 9),
            sets: 1,
            reps: 10,
          ),
        ],
        reviews: const [],
        skippedReviewSession: null,
      ),
    );
    final model = await start(
      tester,
      initial: await _snapshot(store),
      now: () => DateTime(2026, 11, 25, 8),
    );
    expect(find.text('Last time'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Last time'), findsNothing);
    expect(model.reviews, isEmpty);
    expect(model.skippedReviewSession, '2026-11-24');
  });

  testWidgets('saving a review keeps the sensation and the completion time', (
    tester,
  ) async {
    final completedAt = DateTime(2026, 11, 24, 9);
    final model = await start(
      tester,
      initial: StoreData(
        initialized: true,
        exercises: seedExercises(movementCatalog),
        completions: [
          Completion(
            user: currentUser,
            exerciseName: 'Toe flex',
            completedAt: completedAt,
            sets: 1,
            reps: 10,
          ),
        ],
        reviews: const [],
        skippedReviewSession: null,
      ),
      now: () => DateTime(2026, 11, 25, 8),
    );
    await tester.tap(find.text('Fine'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final review = model.reviews.single;
    expect(review.exerciseName, 'Toe flex');
    expect(review.area, BodyArea.feet);
    expect(review.sensation, Sensation.fine);
    expect(review.exercisedAt.isAtSameMomentAs(completedAt), isTrue);
    expect(model.completions, hasLength(1));
  });
}

Future<StoreData> _snapshot(MemoryMendingStore store) => store.load();
