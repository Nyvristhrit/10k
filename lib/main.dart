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

  // Portrait par défaut (posée sur la table), mais paysage autorisé pour une
  // utilisation sur tablette — les écrans adaptent leur disposition en
  // conséquence (voir `game_board_screen._playerGrid`). Pas de « tête en
  // bas » : ni portraitDown, ni les deux paysages inversés n'apportent rien
  // ici et compliqueraient les tests manuels.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
