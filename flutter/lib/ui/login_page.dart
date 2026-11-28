import 'package:flutter/material.dart';

import '../state/mending_scope.dart';
import 'theme.dart';

const profileName = 'Melissa';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.mending;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Mending',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('login-melissa'),
                onPressed: () => MendingScope.of(context).signIn(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text(profileName),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
