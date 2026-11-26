import 'package:flutter/material.dart';

import '../domain/movement_visual.dart';
import 'theme.dart';

/// Stand-in until a movement has frames.
class MovementVisualView extends StatelessWidget {
  const MovementVisualView({super.key, required this.visual});

  final MovementVisual visual;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE7ECF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mendingInk, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.accessibility_new_rounded,
              size: 48,
              color: mendingInk,
            ),
            const SizedBox(height: 8),
            const Text(
              'Visual later',
              style: TextStyle(color: mendingInk, fontWeight: FontWeight.w700),
            ),
            if (visual.representation != null) ...[
              const SizedBox(height: 4),
              Text(
                visual.representation!,
                style: const TextStyle(color: mendingInk, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
