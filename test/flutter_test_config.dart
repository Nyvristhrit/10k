import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/l10n/l10n.dart';

/// Configuration commune à tous les tests (chargée par `flutter test`).
///
/// L'environnement de test simule un téléphone en anglais : on force le
/// français. Les tests de `test/l10n/` changent eux-mêmes de langue.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.localeTestValue = const Locale('fr', 'FR');
  binding.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
  setUp(() => L10n.current = AppLanguage.fr);
  await testMain();
}
