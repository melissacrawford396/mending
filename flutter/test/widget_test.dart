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
import 'package:mending/ui/movement_visual_view.dart';

import 'test_catalog.dart';

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
      catalog: testCatalog,
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
    expect(
      find.descendant(
        of: find.byType(MovementVisualView),
        matching: find.image(
          const AssetImage('assets/visuals/thumbnails/arch-roll.jpg'),
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('lacrosse ball'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Mark done'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Mark done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(model.completions.single.movementId, 'arch-roll');
    expect(model.completions.single.sets, 1);
    expect(model.completions.single.reps, 10);
    expect(find.text('Ready in 2 days'), findsWidgets);
  });

  testWidgets('a sets override can return to the default', (tester) async {
    final model = await start(tester);
    await tester.tap(find.text('Arch roll'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.byKey(const Key('sets-add')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('sets-add')));
    await tester.pump();
    expect(model.findExercise('arch-roll')!.setsOverride, 2);

    await tester.tap(find.text('Use default'));
    await tester.pump();
    expect(model.findExercise('arch-roll')!.setsOverride, isNull);
    expect(model.findExercise('arch-roll')!.starred, isTrue);
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
    expect(find.text('Arch roll'), findsOneWidget);

    await tester.tap(find.text('Feet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
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

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder feet() => find.bySemanticsLabel('Feet').first;

  testWidgets('a body part peeks its list without moving the body', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Body'));
    await settle(tester);
    final before = tester.getRect(find.byType(BodyFigure));

    await tester.tap(feet());
    await settle(tester);
    final tabs = tester.getTopLeft(find.byType(NavigationBar)).dy;
    final header = tester.getRect(find.text('Feet'));
    final firstRow = tester.getTopLeft(find.text('Arch roll')).dy;
    expect(header.bottom, lessThan(tabs));
    expect(firstRow, lessThan(tabs));
    expect(tester.getRect(find.byType(BodyFigure)), before);

    await tester.tap(find.text('Feet'));
    await settle(tester);
    final small = tester.getRect(find.byType(BodyFigure));
    expect(small.height, lessThan(before.height * 0.5));
    expect(small.topLeft.dx, lessThan(40));
    expect(small.topLeft.dy, lessThan(before.top));

    await tester.tap(find.bySemanticsLabel('Knees').first, warnIfMissed: false);
    await settle(tester);
    expect(find.text('Feet'), findsOneWidget);
    expect(tester.getRect(find.byType(BodyFigure)), before);

    await tester.drag(find.text('Feet'), const Offset(0, -400));
    await settle(tester);
    expect(
      tester.getSize(find.byType(BodyFigure)).height,
      closeTo(small.height, 1),
    );
  });

  testWidgets('tapping the part again or beside the body closes the list', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Body'));
    await settle(tester);

    await tester.tap(feet());
    await settle(tester);
    expect(find.text('Feet'), findsOneWidget);
    await tester.tap(feet());
    await settle(tester);
    expect(find.text('Feet'), findsNothing);

    await tester.tap(feet());
    await settle(tester);
    final figure = tester.getRect(find.byType(BodyFigure));
    await tester.tapAt(Offset(figure.left + 4, figure.center.dy));
    await settle(tester);
    expect(find.text('Feet'), findsNothing);
  });

  testWidgets('double-tapping a part opens the full list', (tester) async {
    await start(tester);
    await tester.tap(find.text('Body'));
    await settle(tester);
    final before = tester.getRect(find.byType(BodyFigure));

    await tester.tap(feet());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(feet());
    await settle(tester);
    expect(find.text('Feet'), findsOneWidget);
    expect(
      tester.getSize(find.byType(BodyFigure)).height,
      lessThan(before.height * 0.5),
    );
  });

  testWidgets('hover previews movements, starred first, and click selects', (
    tester,
  ) async {
    final model = await start(tester, size: const Size(1280, 800));
    await model.setStarred(testCatalog.byId('arch-roll'), false);
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
        exercises: seedExercises(testCatalog),
        completions: [
          Completion(
            user: currentUser,
            movementId: 'toe-flex',
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
        exercises: seedExercises(testCatalog),
        completions: [
          Completion(
            user: currentUser,
            movementId: 'toe-flex',
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
    expect(review.movementId, 'toe-flex');
    expect(review.area, BodyArea.feet);
    expect(review.sensation, Sensation.fine);
    expect(review.exercisedAt.isAtSameMomentAs(completedAt), isTrue);
    expect(model.completions, hasLength(1));
  });
}

Future<StoreData> _snapshot(MemoryMendingStore store) => store.load();
