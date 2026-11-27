# Mending

Flutter app for the movement list, stars, and cooldowns. Android first, and it also runs in Chrome.

Clips and thumbnails come from the repo's `visuals/` folder through the `assets/visuals` link. A new clip also needs a line under `assets:` in `pubspec.yaml`, an entry in `assets/catalog/visuals.json`, and a thumbnail from `visuals/make-thumbnails.sh`.

Movement records, including descriptions, live in `assets/catalog/movements.json`. Only `lib/data/catalog_source.dart` knows that format.

```
cd flutter
flutter run            # Android device or emulator
flutter run -d chrome  # Chrome
```
