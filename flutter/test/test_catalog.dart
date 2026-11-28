import 'dart:convert';
import 'dart:io';

import 'package:mending/data/catalog.dart';
import 'package:mending/data/catalog_source.dart';

/// The bundled catalog, read from disk so tests can use it without awaiting.
final testCatalog = MovementCatalog.fromJson(
  movements: _read(movementsAsset),
  visuals: _read(visualsAsset),
);

Map<String, dynamic> _read(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}
