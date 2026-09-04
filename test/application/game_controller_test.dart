import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/domain/commands/game_command.dart';

/// Historique de partie (§ évolution « consulter et revenir en arrière ») :
/// `revertToAction` doit annuler exactement les coups postérieurs à l'action
/// visée, un par un, en réutilisant l'annulation déjà testée du moteur.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
    ]);
  });
  tearDown(() => container.dispose());

  Future<void> startTwoPlayerGame() async {
    final notifier = container.read(gameControllerProvider.notifier);
    await notifier.newGame();
    await notifier.dispatch(const AddPlayer(displayName: 'Alpha'));
    await notifier.dispatch(const AddPlayer(displayName: 'Beta'));
    await notifier.dispatch(const StartGame());
  }

  test('revient exactement au coup visé et annule les suivants', () async {
    await startTwoPlayerGame();
    final notifier = container.read(gameControllerProvider.notifier);
    final players = container.read(gameControllerProvider).value!.players;
    final alpha = players[0].id;
    final beta = players[1].id;

    await notifier.dispatch(RecordScore(playerId: alpha, amount: 500));
    await notifier.dispatch(RecordScore(playerId: beta, amount: 800));
    final targetActionId =
        container.read(gameControllerProvider).value!.lastActiveAction!.id;
    await notifier.dispatch(RecordScore(playerId: alpha, amount: 400));

    final reverted = await notifier.revertToAction(targetActionId);
    expect(reverted, isTrue);

    final game = container.read(gameControllerProvider).value!;
    expect(game.playerById(alpha)!.score, 500);
    expect(game.playerById(beta)!.score, 800);
    expect(game.lastActiveAction!.id, targetActionId);
  });

  test('refuse de revenir à une action inconnue sans rien modifier', () async {
    await startTwoPlayerGame();
    final notifier = container.read(gameControllerProvider.notifier);
    final alpha = container.read(gameControllerProvider).value!.players[0].id;
    await notifier.dispatch(RecordScore(playerId: alpha, amount: 500));

    final before = container.read(gameControllerProvider).value!;
    final reverted = await notifier.revertToAction('inconnue');

    expect(reverted, isFalse);
    expect(container.read(gameControllerProvider).value, before);
  });

  test('refuse de revenir à une action déjà annulée', () async {
    await startTwoPlayerGame();
    final notifier = container.read(gameControllerProvider.notifier);
    final alpha = container.read(gameControllerProvider).value!.players[0].id;
    await notifier.dispatch(RecordScore(playerId: alpha, amount: 500));
    final firstActionId =
        container.read(gameControllerProvider).value!.lastActiveAction!.id;
    await notifier.undo();

    final reverted = await notifier.revertToAction(firstActionId);
    expect(reverted, isFalse);
  });

  test('newGame conserve une partie terminée mais efface une abandonnée',
      () async {
    final repo = InMemoryGameRepository();
    final c = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final notifier = c.read(gameControllerProvider.notifier);

    // Partie abandonnée en cours de préparation : effacée à la suivante.
    await notifier.newGame();
    final abandonedId = c.read(gameControllerProvider).value!.id;
    await notifier.newGame();
    expect(await repo.loadGame(abandonedId), isNull);

    // Partie menée jusqu'au bout : conservée (alimente les statistiques).
    await notifier.dispatch(const AddPlayer(displayName: 'Alpha'));
    await notifier.dispatch(const AddPlayer(displayName: 'Beta'));
    await notifier.dispatch(const StartGame());
    final alpha = c.read(gameControllerProvider).value!.players[0].id;
    final beta = c.read(gameControllerProvider).value!.players[1].id;
    await notifier.dispatch(RecordScore(playerId: alpha, amount: 10000));
    await notifier.dispatch(PassTurn(playerId: beta));
    final finishedId = c.read(gameControllerProvider).value!.id;
    expect(c.read(gameControllerProvider).value!.status.name, 'finished');

    await notifier.newGame();
    expect(await repo.loadGame(finishedId), isNotNull);
  });
}
