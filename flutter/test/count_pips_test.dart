import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/catalog.dart';
import 'package:mending/data/store.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/state/app_model.dart';
import 'package:mending/state/mending_scope.dart';
import 'package:mending/ui/count_pips.dart';
import 'package:mending/ui/movement_page.dart';

import 'test_catalog.dart';

void main() {
  test('fives become groups and the rest stay loose', () {
    expect(tallySplit(3), (groups: 0, loose: 3));
    expect(tallySplit(5), (groups: 1, loose: 0));
    expect(tallySplit(7), (groups: 1, loose: 2));
    expect(tallySplit(10), (groups: 2, loose: 0));
    expect(tallySplit(50), (groups: 10, loose: 0));
  });

  testWidgets('50 reps shrink to fit a narrow row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CountPips(count: 50, shape: PipShape.triangle),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final paint = find.descendant(
      of: find.byType(CountPips),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(paint).width, lessThanOrEqualTo(200));
  });

  testWidgets('plus stops at 10 sets and 50 reps', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final arch = testCatalog.byId('arch-roll');
    final model = AppModel(
      store: MemoryMendingStore(
        StoreData(
          initialized: true,
          exercises: [
            MyExercise(
              user: currentUser,
              movementId: arch.id,
              setsOverride: 10,
              repsOverride: 49,
              starred: true,
            ),
            ...seedExercises(testCatalog).skip(1),
          ],
          completions: const [],
          reviews: const [],
          skippedReviewSession: null,
        ),
      ),
      catalog: testCatalog,
    );
    await model.load();
    await tester.pumpWidget(
      MendingScope(
        notifier: model,
        child: MaterialApp(home: MovementPage(movement: arch)),
      ),
    );
    await tester.pump();

    IconButton button(String key) =>
        tester.widget<IconButton>(find.byKey(Key(key)));
    expect(button('sets-add').onPressed, isNull);
    expect(button('reps-add').onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('reps-add')));
    await tester.pump();
    expect(model.findExercise(arch.id)!.repsOverride, 50);
    expect(button('reps-add').onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
