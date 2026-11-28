import 'package:flutter/material.dart';

import '../state/mending_scope.dart';
import 'login_page.dart';
import 'theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MendingScope.of(context);
    final colors = context.mending;
    final days = model.daysLogged();
    final dayLabel = days == 1 ? '1 day' : '$days days';
    return Scaffold(
      appBar: AppBar(title: const Text(profileName)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profileName,
              style: TextStyle(
                color: colors.ink,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Days logged',
              style: TextStyle(
                color: colors.ink.withValues(alpha: 0.72),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayLabel,
              key: const Key('days-logged'),
              style: TextStyle(
                color: colors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
