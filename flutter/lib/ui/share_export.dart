import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet. Tests replace this.
Future<void> Function(String json) shareExport = _shareExport;

Future<void> _shareExport(String json) {
  return SharePlus.instance.share(
    ShareParams(
      title: 'Mending',
      files: [
        XFile.fromData(
          utf8.encode(json),
          mimeType: 'application/json',
          name: 'mending.json',
        ),
      ],
      fileNameOverrides: const ['mending.json'],
    ),
  );
}
