# Movements

The catalog lives in JSON under [flutter/assets/catalog/](flutter/assets/catalog/). The app reads it at startup. Edit the files there, not this page. Shapes match [planning.md](planning.md).

- [movements.json](flutter/assets/catalog/movements.json): one record per movement type. Sets, reps, and cooldown are **Decided**.
- [visuals.json](flutter/assets/catalog/visuals.json): the clip and thumbnail for each movement. How the clips get made is in [planning-unity.md](planning-unity.md).

Each movement has an `id`, like `toe-flex`. Visuals, your exercises, the log, and reviews point at that id. The `name` is display text and can change freely. Never change an `id` once it ships.

A missing optional field falls back to a default. A field the app does not know is ignored. `flutter test` checks that ids are unique and every reference points at a real movement.

The first five movements are starred on first launch. That list is `starterMovementIds` in `flutter/lib/data/catalog.dart`.
