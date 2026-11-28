import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mending/data/catalog.dart';
import 'package:mending/data/catalog_source.dart';
import 'package:mending/domain/body_area.dart';
import 'package:mending/domain/effective.dart';

import 'test_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled asset loads the same catalog as the file', () async {
    final catalog = await AssetCatalogSource().load();
    expect(
      catalog.movements.map((movement) => movement.id),
      testCatalog.movements.map((movement) => movement.id),
    );
    expect(catalog.visuals, hasLength(testCatalog.visuals.length));
  });

  test('ids are unique and every reference points at a movement', () {
    final ids = testCatalog.movements.map((movement) => movement.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final movement in testCatalog.movements) {
      expect(movement.id, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')));
      expect(movement.name, isNotEmpty, reason: movement.id);
      expect(movement.description, isNotEmpty, reason: movement.id);
    }
    for (final visual in testCatalog.visuals) {
      expect(ids, contains(visual.movementId));
    }
    for (final id in starterMovementIds) {
      expect(ids, contains(id));
    }
  });

  test('every movement sets the schedule fields within the caps', () {
    final raw =
        jsonDecode(File(movementsAsset).readAsStringSync())
            as Map<String, dynamic>;
    for (final row in raw['movements'] as List) {
      final json = row as Map<String, dynamic>;
      for (final key in const [
        'defaultSets',
        'defaultReps',
        'defaultCooldown',
        'defaultPerDay',
        'defaultRestSeconds',
      ]) {
        expect(json[key], isA<int>(), reason: '${json['id']} $key');
      }
    }
    for (final movement in testCatalog.movements) {
      final reason = movement.id;
      expect(
        movement.defaultSets,
        inInclusiveRange(1, maxSets),
        reason: reason,
      );
      expect(
        movement.defaultReps,
        inInclusiveRange(1, movement.timed ? maxHoldSeconds : maxReps),
        reason: reason,
      );
      if (movement.id == 'ankle-stretch') {
        expect(movement.timed, isTrue);
        expect(movement.defaultReps, 30);
      }
      expect(
        movement.defaultCooldown,
        inInclusiveRange(1, maxCooldownDays),
        reason: reason,
      );
      expect(
        movement.defaultPerDay,
        inInclusiveRange(1, maxPerDay),
        reason: reason,
      );
      expect(
        movement.defaultRestSeconds,
        inInclusiveRange(0, maxRestSeconds),
        reason: reason,
      );
    }
  });

  test('missing optional fields use defaults and unknown ones are ignored', () {
    final catalog = MovementCatalog.fromJson(
      movements: {
        'schemaVersion': 1,
        'movements': [
          {'id': 'neck-roll', 'area': 'neck', 'equipment': 'none'},
        ],
      },
      visuals: {'schemaVersion': 1},
    );
    final movement = catalog.byId('neck-roll');
    expect(movement.name, 'neck-roll');
    expect(movement.area, BodyArea.neck);
    expect(movement.defaultSets, 1);
    expect(movement.defaultPerDay, 1);
    expect(movement.defaultRestSeconds, 30);
    expect(movement.description, isEmpty);
    expect(catalog.visualFor('neck-roll').representation, isNull);
  });

  test('a newer catalog schema is refused', () {
    expect(
      () => MovementCatalog.fromJson(
        movements: {'schemaVersion': catalogSchemaVersion + 1},
        visuals: {'schemaVersion': 1},
      ),
      throwsFormatException,
    );
  });
}
