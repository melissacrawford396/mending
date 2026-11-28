import 'package:flutter/material.dart';

import '../domain/data_export.dart';
import '../state/mending_scope.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'share_export.dart';
import 'theme.dart';

class AppMenuButton extends StatefulWidget {
  const AppMenuButton({super.key});

  @override
  State<AppMenuButton> createState() => _AppMenuButtonState();
}

class _AppMenuButtonState extends State<AppMenuButton> {
  OverlayEntry? _entry;

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _open() {
    final box = context.findRenderObject()! as RenderBox;
    _entry = OverlayEntry(
      builder: (_) => _AppMenu(
        anchor: box.localToGlobal(Offset.zero),
        anchorSize: box.size,
        onClose: _close,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('app-menu'),
      tooltip: 'Menu',
      onPressed: () => _entry == null ? _open() : _close(),
      icon: const Icon(Icons.menu),
    );
  }
}

class _AppMenu extends StatefulWidget {
  const _AppMenu({
    required this.anchor,
    required this.anchorSize,
    required this.onClose,
  });

  final Offset anchor;
  final Size anchorSize;
  final VoidCallback onClose;

  @override
  State<_AppMenu> createState() => _AppMenuState();
}

class _AppMenuState extends State<_AppMenu> {
  var _advanced = false;

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final colors = context.mending;
    final ink = colors.ink;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: widget.anchor.dy + widget.anchorSize.height,
          right: 8,
          width: 280,
          child: Material(
            color: colors.surface,
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const Key('menu-profile'),
                  title: Text(profileName, style: TextStyle(color: ink)),
                  trailing: Icon(Icons.chevron_right, color: ink),
                  onTap: () {
                    final navigator = Navigator.of(context);
                    widget.onClose();
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  key: const Key('use-24-hour'),
                  title: Text('24-hour time', style: TextStyle(color: ink)),
                  value: model.use24Hour,
                  onChanged: model.setUse24Hour,
                ),
                SwitchListTile(
                  key: const Key('dark-mode'),
                  title: Text('Dark mode', style: TextStyle(color: ink)),
                  value: model.darkMode,
                  onChanged: model.setDarkMode,
                ),
                ListTile(
                  key: const Key('menu-advanced'),
                  title: Text('Advanced', style: TextStyle(color: ink)),
                  trailing: Icon(
                    _advanced ? Icons.expand_less : Icons.expand_more,
                    color: ink,
                  ),
                  onTap: () => setState(() => _advanced = !_advanced),
                ),
                if (_advanced)
                  ListTile(
                    key: const Key('menu-export'),
                    contentPadding: const EdgeInsets.only(left: 32, right: 16),
                    title: Text('Export', style: TextStyle(color: ink)),
                    onTap: () {
                      final json = dataExportJson(
                        exercises: model.exercises,
                        completions: model.completions,
                      );
                      widget.onClose();
                      shareExport(json);
                    },
                  ),
                ListTile(
                  key: const Key('menu-log-out'),
                  title: Text('Log out', style: TextStyle(color: ink)),
                  onTap: () {
                    widget.onClose();
                    model.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
