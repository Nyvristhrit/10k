import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'application/providers/app_providers.dart';
import 'data/repositories/file_game_repository.dart';
import 'data/repositories/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On verrouille l'appli en portrait : elle est pensée pour être posée sur la
  // table, et la mise en paysage rend certains écrans illisibles (débordement).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Stockage local dans le dossier de documents de l'application (offline).
  final documentsDir = await getApplicationDocumentsDirectory();
  final repository = FileGameRepository(documentsDir);
  final settings = SettingsRepository(documentsDir);

  runApp(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: const TenkApp(),
    ),
  );
}
