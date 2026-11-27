import 'package:flutter/material.dart';

import 'data/catalog_source.dart';
import 'data/store.dart';
import 'state/app_model.dart';
import 'state/mending_scope.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = await AssetCatalogSource().load();
  final model = AppModel(store: PrefsMendingStore(), catalog: catalog);
  await model.load();
  runApp(MendingApp(model: model));
}

class MendingApp extends StatelessWidget {
  const MendingApp({super.key, required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    return MendingScope(
      notifier: model,
      child: MaterialApp(
        title: 'Mending',
        debugShowCheckedModeBanner: false,
        theme: mendingTheme(),
        scrollBehavior: const BouncingScrollBehavior(),
        home: const HomePage(),
      ),
    );
  }
}

/// Pulling past the end slides the content instead of stretching it.
class BouncingScrollBehavior extends MaterialScrollBehavior {
  const BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
