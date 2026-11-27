import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/store.dart';
import 'package:mending/main.dart';
import 'package:mending/state/app_model.dart';
import 'package:mending/ui/body_figure.dart';

import 'test_catalog.dart';

void main() {
  for (final size in const [
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
    Size(600, 1000),
    Size(700, 500),
  ]) {
    testWidgets('fits at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final model = AppModel(
        store: MemoryMendingStore(null),
        catalog: testCatalog,
      );
      await model.load();
      await tester.pumpWidget(MendingApp(model: model));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Body'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.bySemanticsLabel('Feet').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final header = tester.getRect(find.text('Feet'));
      final row = tester.getRect(find.text('Arch roll'));
      await tester.tap(find.text('Feet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final small = tester.getRect(find.byType(BodyFigure));
      // ignore: avoid_print
      print(
        '$size header ${header.height.toStringAsFixed(1)} '
        'row top ${row.top.toStringAsFixed(0)} small $small',
      );
    });
  }
}
