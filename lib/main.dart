import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/db/database.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final server = AppConfig.allowsServerOverride ? await db.getSetting(serverUrlSettingKey) : null;
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      serverUrlProvider.overrideWith(() => ServerUrlController(server)),
    ],
    child: const SpendrooApp(),
  ));
}
 