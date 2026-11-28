import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/store.dart';
import 'package:mending/domain/completion.dart';
import 'package:mending/domain/data_export.dart';
import 'package:mending/domain/my_exercise.dart';
import 'package:mending/main.dart';
import 'package:mending/state/app_model.dart';
import 'package:mending/ui/home_page.dart';
import 'package:mending/ui/share_export.dart';
import 'package:mending/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shortDate follows 24-hour and 12-hour clocks', () {
    final evening = DateTime(2026, 11, 2, 18, 30);
    final midnight = DateTime(2026, 11, 2, 0, 5);
    final noon = DateTime(2026, 11, 2, 12);
    expect(shortDate(evening), 'Nov 2 · 18:30');
    expect(shortDate(evening, use24Hour: false), 'Nov 2 · 6:30 PM');
    expect(shortDate(midnight, use24Hour: false), 'Nov 2 · 12:05 AM');
    expect(shortDate(noon, use24Hour: false), 'Nov 2 · 12:00 PM');
  });

  test('days logged counts distinct local days', () async {
    final model = AppModel(
      store: MemoryMendingStore(
        StoreData(
          initialized: true,
          exercises: const [],
          completions: [
            Completion(
              user: currentUser,
              movementId: 'arch-roll',
              completedAt: DateTime(2026, 11, 1, 8),
              sets: 1,
              reps: 10,
            ),
            Completion(
              user: currentUser,
              movementId: 'arch-roll',
              completedAt: DateTime(2026, 11, 1, 21),
              sets: 1,
              reps: 8,
            ),
            Completion(
              user: currentUser,
              movementId: 'toe-flex',
              completedAt: DateTime(2026, 11, 2, 18, 30),
              sets: 2,
              reps: 6,
            ),
          ],
          reviews: const [],
          skippedReviewSession: null,
        ),
      ),
      catalog: testCatalog,
    );
    await model.load();
    expect(model.daysLogged(), 2);
  });

  test('export json keeps working-exercise overrides and completions', () {
    final json = dataExportJson(
      exercises: const [
        MyExercise(
          user: currentUser,
          movementId: 'arch-roll',
          setsOverride: 3,
          repsOverride: 12,
          cooldownOverride: 2,
          starred: true,
        ),
      ],
      completions: [
        Completion(
          user: currentUser,
          movementId: 'arch-roll',
          completedAt: DateTime.utc(2026, 11, 2, 18, 30),
          sets: 2,
          reps: 6,
        ),
      ],
    );
    expect(json, contains('"setsOverride": 3'));
    expect(json, contains('"repsOverride": 12'));
    expect(json, contains('"cooldownOverride": 2'));
    expect(json, contains('"starred": true'));
    expect(json, contains('"movementId": "arch-roll"'));
    expect(json, contains('"setReps": ['));
  });

  test(
    'saved settings reload, and missing fields stay at the defaults',
    () async {
      final fresh = StoreData.fromJson({
        'initialized': true,
        'exercises': [],
        'completions': [],
        'reviews': [],
      });
      expect(fresh.use24Hour, isTrue);
      expect(fresh.darkMode, isFalse);
      expect(fresh.signedIn, isTrue);

      SharedPreferences.setMockInitialValues({});
      final model = AppModel(store: PrefsMendingStore(), catalog: testCatalog);
      await model.load();
      await model.setUse24Hour(false);
      await model.setDarkMode(true);
      await model.signOut();

      final again = AppModel(store: PrefsMendingStore(), catalog: testCatalog);
      await again.load();
      expect(again.use24Hour, isFalse);
      expect(again.darkMode, isTrue);
      expect(again.signedIn, isFalse);
    },
  );

  testWidgets('the menu switches theme and time, exports, and logs out', (
    tester,
  ) async {
    String? shared;
    final previous = shareExport;
    shareExport = (json) {
      shared = json;
      return Future<void>.value();
    };
    addTearDown(() => shareExport = previous);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final model = AppModel(
      store: MemoryMendingStore(
        StoreData(
          initialized: true,
          exercises: const [
            MyExercise(
              user: currentUser,
              movementId: 'arch-roll',
              setsOverride: 3,
              repsOverride: 12,
              cooldownOverride: 2,
              starred: true,
            ),
          ],
          completions: [
            Completion(
              user: currentUser,
              movementId: 'arch-roll',
              completedAt: DateTime(2026, 11, 1, 8),
              sets: 1,
              reps: 10,
            ),
            Completion(
              user: currentUser,
              movementId: 'arch-roll',
              completedAt: DateTime(2026, 11, 2, 18, 30),
              sets: 1,
              reps: 8,
            ),
          ],
          reviews: const [],
          skippedReviewSession: null,
        ),
      ),
      catalog: testCatalog,
      now: () => DateTime(2026, 11, 2, 20),
    );
    await model.load();
    await tester.pumpWidget(MendingApp(model: model));
    await tester.pump();

    await tester.tap(find.byKey(const Key('app-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Melissa'), findsOneWidget);
    expect(find.text('24-hour time'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);

    await tester.tap(find.byKey(const Key('use-24-hour')));
    await tester.pumpAndSettle();
    expect(model.use24Hour, isFalse);
    expect(
      MediaQuery.alwaysUse24HourFormatOf(tester.element(find.byType(HomePage))),
      isFalse,
    );
    expect(find.byKey(const Key('use-24-hour')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dark-mode')));
    await tester.pumpAndSettle();
    final colors = MendingColors.of(tester.element(find.byType(HomePage)));
    expect(colors.paper, const Color(0xFF141820));
    expect(colors.ink, const Color(0xFFE6EAF3));
    expect(colors.blue, const Color(0xFF7AA2FF));
    expect(colors.nav, const Color(0xFF1C2230));
    expect(colors.figureFill, Colors.white);
    expect(find.byKey(const Key('dark-mode')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Days logged'), findsOneWidget);
    expect(find.byKey(const Key('days-logged')), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('app-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-advanced')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-export')));
    await tester.pumpAndSettle();
    expect(shared, contains('"setsOverride": 3'));
    expect(shared, contains('"cooldownOverride": 2'));
    expect(shared, contains('"movementId": "arch-roll"'));
    expect(find.byKey(const Key('menu-export')), findsNothing);

    await tester.tap(find.byKey(const Key('app-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-log-out')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-melissa')), findsOneWidget);
    expect(find.text('Melissa'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-melissa')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-menu')), findsOneWidget);
    expect(find.byKey(const Key('login-melissa')), findsNothing);
  });
}
