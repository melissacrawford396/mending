import 'package:flutter/widgets.dart';

import 'app_model.dart';

class MendingScope extends InheritedNotifier<AppModel> {
  const MendingScope({
    super.key,
    required AppModel super.notifier,
    required super.child,
  });

  static AppModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MendingScope>();
    assert(scope != null, 'MendingScope missing');
    return scope!.notifier!;
  }
}
