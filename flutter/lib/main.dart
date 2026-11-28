import 'package:flutter/material.dart';

import 'data/catalog_source.dart';
import 'data/store.dart';
import 'state/app_model.dart';
import 'state/mending_scope.dart';
import 'ui/home_page.dart';
import 'ui/login_page.dart';
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
      child: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          return MaterialApp(
            title: 'Mending',
            debugShowCheckedModeBanner: false,
            theme: mendingTheme(
              model.darkMode ? MendingColors.dark : MendingColors.light,
            ),
            scrollBehavior: const BouncingScrollBehavior(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(alwaysUse24HourFormat: model.use24Hour),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: model.signedIn ? const HomePage() : const LoginPage(),
          );
        },
      ),
    );
  }
}

/// Slides past the end, then stops. The slack is a tenth of the screen.
class LimitedBouncingScrollPhysics extends BouncingScrollPhysics {
  const LimitedBouncingScrollPhysics({super.parent});

  static const overscrollFraction = 0.10;

  @override
  LimitedBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LimitedBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final limit = position.viewportDimension * overscrollFraction;
    final min = position.minScrollExtent - limit;
    final max = position.maxScrollExtent + limit;
    if (value < position.pixels && position.pixels <= min) {
      return value - position.pixels;
    }
    if (max <= position.pixels && position.pixels < value) {
      return value - position.pixels;
    }
    if (value < min && min < position.pixels) return value - min;
    if (position.pixels < max && max < value) return value - max;
    return 0.0;
  }
}

/// Pulling past the end slides the content instead of stretching it.
class BouncingScrollBehavior extends MaterialScrollBehavior {
  const BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const LimitedBouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
