import 'dart:convert';

import 'package:flutter/services.dart';

import 'catalog.dart';

const movementsAsset = 'assets/catalog/movements.json';
const visualsAsset = 'assets/catalog/visuals.json';

/// Where the catalog comes from. The rest of the app only sees
/// [MovementCatalog], so a different source does not change it.
abstract class CatalogSource {
  Future<MovementCatalog> load();
}

/// Reads the JSON files bundled with the app.
class AssetCatalogSource implements CatalogSource {
  AssetCatalogSource([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<MovementCatalog> load() async {
    return MovementCatalog.fromJson(
      movements: await _read(movementsAsset),
      visuals: await _read(visualsAsset),
    );
  }

  Future<Map<String, dynamic>> _read(String path) async {
    return jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;
  }
}
