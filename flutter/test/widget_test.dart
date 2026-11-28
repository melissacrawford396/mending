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
import 'package:mending/ui/body_area_icon.dart';
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
    expect(find.byType(BodyAreaIcon), findsNWidgets(5));
    expect(find.text('Ready'), findsWidgets);
  });

  testWidgets('marking a movement done starts its countdown', (tester) async {
    final model = await start(
      tester,
      now: () => DateTime(2026, 11, 25, 8),
      size: const Size(390, 1400),
    );
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
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Feet'),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Mark done'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Mark done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(model.completions.single.movementId, 'arch-roll');
    expect(model.completions.single.sets, 1);
    expect(model.completions.single.reps, 10);
    expect(find.text('Arch roll done'), findsOneWidget);
    expect(find.text('Back to list'), findsOneWidget);
    await tester.tap(find.text('Back to list'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4500));
    expect(find.text('Ready in 1d 18h'), findsWidgets);
  });

  Future<void> openMovement(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
  }

  testWidgets('Start sits under the clip and the description above Mark done', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 2000));
    await openMovement(tester, 'Arch roll');
    final startButton = tester.getTopLeft(
      find.byKey(const Key('start-exercise')),
    );
    final description = tester.getTopLeft(find.textContaining('lacrosse ball'));
    expect(
      tester.getBottomLeft(find.byType(MovementVisualView)).dy,
      lessThanOrEqualTo(startButton.dy),
    );
    expect(
      startButton.dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('sets-add'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('cooldown-add'))).dy,
      lessThan(description.dy),
    );
    expect(
      tester.getTopLeft(find.text('Mark done')).dy,
      greaterThan(description.dy),
    );
  });

  testWidgets('pulling past the end stops within a tenth of the screen', (
    tester,
  ) async {
    await start(tester);
    await openMovement(tester, 'Arch roll');
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final list = find.byType(Scrollable).last;
    final position = tester.state<ScrollableState>(list).position;
    var physics = position.physics as ScrollPhysics?;
    while (physics != null && physics is! LimitedBouncingScrollPhysics) {
      physics = physics.parent;
    }
    expect(physics, isA<LimitedBouncingScrollPhysics>());

    final limit =
        position.viewportDimension *
        LimitedBouncingScrollPhysics.overscrollFraction;
    await tester.drag(list, const Offset(0, -4000));
    expect(position.pixels, closeTo(position.maxScrollExtent + limit, 1));
    await tester.pumpAndSettle();

    await tester.drag(list, const Offset(0, 4000));
    expect(position.pixels, closeTo(position.minScrollExtent - limit, 1));
    await tester.pumpAndSettle();
  });

  testWidgets('cooldown steps from every 7 days down to 3x a day', (
    tester,
  ) async {
    final model = await start(tester, size: const Size(390, 2000));
    await openMovement(tester, 'Toe flex');
    final add = find.byKey(const Key('cooldown-add'));
    final remove = find.byKey(const Key('cooldown-remove'));
    IconButton button(Finder finder) => tester.widget<IconButton>(finder);

    expect(find.text('every day'), findsOneWidget);
    expect(find.text('18 h apart'), findsOneWidget);

    await tester.tap(remove);
    await tester.pump();
    expect(find.text('2x a day'), findsOneWidget);
    expect(find.text('Gap'), findsOneWidget);
    expect(find.text('8 h apart'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gap-add')));
    await tester.pump();
    expect(find.text('9 h apart'), findsOneWidget);
    expect(model.findExercise('toe-flex')!.gapHoursOverride, 9);

    await tester.tap(remove);
    await tester.pump();
    expect(find.text('3x a day'), findsOneWidget);
    expect(find.text('4 h apart'), findsOneWidget);
    expect(button(remove).onPressed, isNull);
    final exercise = model.findExercise('toe-flex')!;
    expect(exercise.perDayOverride, 3);
    expect(exercise.gapHoursOverride, isNull);
    expect(exercise.cooldownOverride, 1);

    for (var i = 0; i < 8; i++) {
      await tester.tap(add);
      await tester.pump();
    }
    expect(find.text('every 7 days'), findsOneWidget);
    expect(find.text('162 h apart'), findsOneWidget);
    expect(button(add).onPressed, isNull);

    await tester.tap(find.text('Use default'));
    await tester.pump();
    expect(find.text('every day'), findsOneWidget);
    expect(model.findExercise('toe-flex')!.cooldownOverride, isNull);
    expect(model.findExercise('toe-flex')!.perDayOverride, isNull);
  });

  testWidgets('a guided session logs once and moves the row to the bottom', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 25, 8);
    final model = await start(
      tester,
      now: () => now,
      size: const Size(390, 1400),
      initial: StoreData(
        initialized: true,
        exercises: seedExercises(testCatalog),
        completions: [
          Completion(
            user: currentUser,
            movementId: 'toe-flex',
            completedAt: DateTime(2026, 11, 25, 7),
            sets: 1,
            reps: 10,
          ),
        ],
        reviews: const [],
        skippedReviewSession: null,
      ),
    );
    await openMovement(tester, 'Ankle stretch');
    await scrollTo(tester, find.text('Start exercise'));
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Set 1 of 2'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('Hold 30 s'), findsOneWidget);
    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
    expect(find.text('Next: set 2 of 2'), findsOneWidget);

    await tester.tap(find.text('Skip rest'));
    await tester.pump();
    expect(find.text('Set 2 of 2'), findsOneWidget);
    expect(model.completions, hasLength(1));

    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ankle stretch done'), findsOneWidget);
    expect(model.completions, hasLength(2));
    expect(model.completions.last.movementId, 'ankle-stretch');
    expect(model.completions.last.sets, 2);
    expect(model.completions.last.setReps, [30, 30]);
    expect(find.text('Back to list'), findsOneWidget);

    await tester.tap(find.text('Back to list'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Move to waiting'), findsOneWidget);
    expect(find.text('Ankle stretch done'), findsNothing);

    await tester.pump(const Duration(milliseconds: 4000));
    expect(model.justCompletedId, isNull);
    expect(find.text('Move to waiting'), findsNothing);
    final waiting = tester.getTopLeft(find.text('Waiting')).dy;
    final toe = tester.getTopLeft(find.text('Toe flex')).dy;
    final ankle = tester.getTopLeft(find.text('Ankle stretch')).dy;
    expect(toe, greaterThan(waiting));
    expect(ankle, greaterThan(toe));
  });

  testWidgets('a circuit names each set and walks one side first', (
    tester,
  ) async {
    await start(
      tester,
      size: const Size(390, 1600),
      initial: StoreData(
        initialized: true,
        exercises: [
          MyExercise.from(testCatalog.byId('hip-circuit'), starred: true),
        ],
        completions: const [],
        reviews: const [],
        skippedReviewSession: null,
      ),
    );
    await openMovement(tester, 'Hip circuit');
    await scrollTo(tester, find.byKey(const Key('sets-add')));
    expect(
      tester.widget<IconButton>(find.byKey(const Key('sets-add'))).onPressed,
      isNull,
    );

    await scrollTo(tester, find.text('Start exercise'));
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Fire hydrant'), findsOneWidget);
    expect(find.text('Left side'), findsOneWidget);
    expect(find.textContaining('Keep the knee bent'), findsOneWidget);
    expect(find.text('Set 1 of 8'), findsNothing);
    expect(find.text('Do 10 reps'), findsOneWidget);

    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    expect(find.text('Rest'), findsNothing);
    expect(find.text('Knee circle'), findsOneWidget);
    expect(find.text('Left side'), findsOneWidget);
  });

  testWidgets('rest stays at zero, can grow by 30s, and leaving logs nothing', (
    tester,
  ) async {
    var clock = DateTime(2026, 11, 25, 8);
    final model = await start(
      tester,
      now: () => clock,
      size: const Size(390, 1400),
    );
    await openMovement(tester, 'Ankle stretch');
    await scrollTo(tester, find.text('Start exercise'));
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    final elapsed = tester.widget<Text>(find.byKey(const Key('rest-elapsed')));
    expect(elapsed.style!.color!.a, lessThan(0.6));

    clock = clock.add(const Duration(milliseconds: 500));
    await tester.pump();
    final ring = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.value, closeTo(29.5 / 30, 0.01));

    clock = clock.add(const Duration(seconds: 30, milliseconds: 500));
    await tester.pump();
    expect(find.text('Set 2 of 2'), findsNothing);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('0:31'), findsOneWidget);
    expect(find.text('Next set'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-rest')));
    await tester.pump();
    expect(find.text('0:29'), findsOneWidget);
    expect(find.text('0:31'), findsOneWidget);
    expect(find.text('Skip rest'), findsOneWidget);

    await tester.tap(find.text('Skip rest'));
    await tester.pump();
    expect(find.text('Set 2 of 2'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    expect(find.text('End exercise?'), findsOneWidget);
    await tester.tap(find.text('End'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Set 2 of 2'), findsNothing);
    expect(find.text('Start exercise'), findsOneWidget);
    expect(model.completions, isEmpty);
  });

  testWidgets('done at 0 reps keeps the sets already finished', (tester) async {
    final model = await start(tester, size: const Size(390, 1400));
    await openMovement(tester, 'Ankle stretch');
    await scrollTo(tester, find.text('Start exercise'));
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('session-reps-remove')));
      await tester.pump();
    }
    await tester.pageBack();
    await tester.pump();
    expect(find.text('Save and finish'), findsNothing);
    await tester.tap(find.text('Keep going'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ankle stretch done'), findsNothing);
    expect(find.text('Start exercise'), findsOneWidget);
    expect(model.completions, isEmpty);

    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    await tester.tap(find.text('Skip rest'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('session-reps-remove')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 set · 30 s'), findsOneWidget);
    expect(model.completions.single.setReps, [30]);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 2000));
  });

  testWidgets('the back arrow can save the set on screen', (tester) async {
    final model = await start(tester, size: const Size(390, 1400));
    await openMovement(tester, 'Ankle stretch');
    await scrollTo(tester, find.text('Start exercise'));
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('session-reps-add')));
    await tester.tap(find.byKey(const Key('session-reps-add')));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    await tester.tap(find.text('Save and finish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 set · 40 s'), findsOneWidget);
    expect(model.completions.single.setReps, [40]);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 2000));
  });

  testWidgets('each set keeps its own rep count', (tester) async {
    final model = await start(tester, size: const Size(390, 1400));
    await openMovement(tester, 'Ankle stretch');
    await scrollTo(tester, find.text('Start exercise'));
    await tester.tap(find.text('Start exercise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('session-reps-add')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    await tester.tap(find.text('Skip rest'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('session-reps-add')));
    }
    await tester.pump();
    await tester.tap(find.byKey(const Key('set-done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2 sets · 35 s, 45 s'), findsOneWidget);
    expect(model.completions.single.setReps, [35, 45]);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 2000));
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
