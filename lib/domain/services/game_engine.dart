import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../data/catalogs/adjective_catalog.dart';
import '../../data/catalogs/animal_catalog.dart';
import '../../data/catalogs/color_catalog.dart';
import '../commands/game_command.dart';
import '../enums/game_enums.dart';
import '../errors/game_rule_violation.dart';
import '../models/animal_avatar.dart';
import '../models/color_token.dart';
import '../models/final_chance_state.dart';
import '../models/gain.dart';
import '../models/game_action.dart';
import '../models/game_effect.dart';
import '../models/game_rules.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/round_state.dart';
import 'game_transition.dart';

/// Nombre maximum de joueurs (= nombre de couleurs disponibles).
const int kMaxPlayers = 12;

/// Le moteur de jeu : logique métier pure, sans aucune dépendance Flutter.
///
/// Utilisation : `engine.apply(state, command)` renvoie soit un [Success]
/// (avec la transition), soit un [Failure] (violation de règle). Le moteur ne
/// modifie jamais l'état reçu : il en produit un nouveau (immuabilité).
class GameEngine {
  GameEngine({
    String Function()? idGenerator,
    DateTime Function()? clock,
    Random? random,
  })  : _newId = idGenerator ?? (() => const Uuid().v4()),
        _now = clock ?? DateTime.now,
        _random = random ?? Random();

  final String Function() _newId;
  final DateTime Function() _now;
  final Random _random;

  // ── API publique ──────────────────────────────────────────────────────────

  /// Crée une nouvelle partie vide en statut `setup`.
  GameState createGame({GameRules rules = const GameRules()}) {
    final now = _now();
    return GameState(
      id: _newId(),
      status: GameStatus.setup,
      rules: rules,
      players: const [],
      actions: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Applique une commande à un état et renvoie le résultat.
  EngineResult apply(GameState state, GameCommand command) {
    return switch (command) {
      CreateGame(:final rules) => Success(GameTransition(
          previousState: state,
          nextState: createGame(rules: rules),
        )),
      AddPlayer() => _addPlayer(state, command),
      RenamePlayer() => _renamePlayer(state, command),
      SetPlayerAlias() => _setPlayerAlias(state, command),
      RemovePlayerBeforeStart() => _removePlayer(state, command),
      UpdateRules() => _updateRules(state, command),
      StartGame() => _startGame(state),
      SelectGuidedPlayer() => _selectGuidedPlayer(state, command),
      RecordScore() => _recordScore(state, command),
      PassTurn() => _passTurn(state, command),
      LeaveGame() => _leaveGame(state, command),
      UndoLastAction() => _undo(state),
    };
  }

  // ── Préparation ─────────────────────────────────────────────────────────────

  EngineResult _addPlayer(GameState state, AddPlayer cmd) {
    if (state.status != GameStatus.setup) {
      return _fail(GameRuleViolationCode.gameAlreadyStarted);
    }
    if (state.players.length >= kMaxPlayers) {
      return _fail(GameRuleViolationCode.maximumPlayersReached);
    }

    final avatar = _drawAvatar(state.players);
    if (avatar == null) return _fail(GameRuleViolationCode.noAvatarAvailable);
    final color = _drawColor(state.players);
    if (color == null) return _fail(GameRuleViolationCode.noColorAvailable);

    final name = (cmd.displayName ?? '').trim();
    final now = _now();
    final player = Player(
      id: _newId(),
      avatarId: avatar.id,
      colorId: color.id,
      displayName: name.isEmpty
          ? _scoutName(avatar,
              trash: cmd.trashNames, custom: cmd.customTrashAdjectives)
          : name,
      seatIndex: state.players.length,
      createdAt: now,
    );

    final action = _prepAction(GameActionType.playerAdded, player.id);
    final next = state.copyWith(
      players: [...state.players, player],
      actions: [...state.actions, action],
      updatedAt: now,
    );
    return _ok(state, next, action);
  }

  EngineResult _renamePlayer(GameState state, RenamePlayer cmd) {
    if (state.status != GameStatus.setup) {
      return _fail(GameRuleViolationCode.gameAlreadyStarted);
    }
    final player = state.playerById(cmd.playerId);
    if (player == null) return _fail(GameRuleViolationCode.playerNotFound);

    final name = cmd.newName.trim();
    if (name.isEmpty || name.characters().length > 16) {
      return _fail(GameRuleViolationCode.invalidPlayerName,
          'Le nom doit contenir de 1 à 16 caractères.');
    }

    final now = _now();
    final players = state.players
        .map((p) => p.id == cmd.playerId ? p.copyWith(displayName: name) : p)
        .toList();
    final action = _prepAction(GameActionType.playerRenamed, cmd.playerId);
    final next = state.copyWith(
      players: players,
      actions: [...state.actions, action],
      updatedAt: now,
    );
    return _ok(state, next, action);
  }

  /// Un alias doit commencer par `@` (§ évolution « alias joueur ») : c'est ce
  /// qui le distingue visuellement du nom d'animal tiré au hasard. On ajoute
  /// le `@` nous-mêmes si l'appelant l'a omis, plutôt que de refuser.
  EngineResult _setPlayerAlias(GameState state, SetPlayerAlias cmd) {
    if (state.status != GameStatus.setup) {
      return _fail(GameRuleViolationCode.gameAlreadyStarted);
    }
    final player = state.playerById(cmd.playerId);
    if (player == null) return _fail(GameRuleViolationCode.playerNotFound);

    final raw = (cmd.alias ?? '').trim();
    final clear = raw.isEmpty || raw == '@';
    String? alias;
    if (!clear) {
      final withAt = raw.startsWith('@') ? raw : '@$raw';
      alias = withAt.length > 24 ? withAt.substring(0, 24) : withAt;
    }

    final now = _now();
    final players = state.players
        .map((p) => p.id == cmd.playerId
            ? p.copyWith(alias: alias, clearAlias: clear)
            : p)
        .toList();
    final action = _prepAction(GameActionType.playerAliasSet, cmd.playerId);
    final next = state.copyWith(
      players: players,
      actions: [...state.actions, action],
      updatedAt: now,
    );
    return _ok(state, next, action);
  }

  EngineResult _removePlayer(GameState state, RemovePlayerBeforeStart cmd) {
    if (state.status != GameStatus.setup) {
      return _fail(GameRuleViolationCode.gameAlreadyStarted);
    }
    final player = state.playerById(cmd.playerId);
    if (player == null) return _fail(GameRuleViolationCode.playerNotFound);

    final now = _now();
    // Retire le joueur et recompacte les positions autour de la table.
    final remaining = state.players.where((p) => p.id != cmd.playerId).toList()
      ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
    final reindexed = <Player>[];
    for (var i = 0; i < remaining.length; i++) {
      reindexed.add(remaining[i].copyWith(seatIndex: i));
    }
    final action =
        _prepAction(GameActionType.playerRemovedBeforeStart, cmd.playerId);
    final next = state.copyWith(
      players: reindexed,
      actions: [...state.actions, action],
      updatedAt: now,
    );
    return _ok(state, next, action);
  }

  EngineResult _updateRules(GameState state, UpdateRules cmd) {
    if (state.status != GameStatus.setup) {
      return _fail(GameRuleViolationCode.gameAlreadyStarted);
    }
    final now = _now();
    final next = state.copyWith(rules: cmd.rules, updatedAt: now);
    return _ok(state, next, null);
  }

  EngineResult _startGame(GameState state) {
    if (state.status != GameStatus.setup) {
      return _fail(GameRuleViolationCode.gameAlreadyStarted);
    }
    if (state.players.length < 2) {
      return _fail(GameRuleViolationCode.notEnoughPlayers);
    }

    final now = _now();
    final ordered = [...state.players]
      ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
    final ids = ordered.map((p) => p.id).toList();

    RoundState? round;
    if (state.rules.turnMode == TurnMode.guided) {
      round = RoundState(
        roundNumber: 1,
        currentPlayerId: ids.first,
        pendingPlayerIds: ids,
        completedPlayerIds: const [],
      );
    }

    final action = _prepAction(GameActionType.gameStarted, null);
    final next = state.copyWith(
      status: GameStatus.inProgress,
      roundState: round,
      actions: [...state.actions, action],
      updatedAt: now,
    );
    return _ok(state, next, action);
  }

  // ── Sélection guidée ────────────────────────────────────────────────────────

  EngineResult _selectGuidedPlayer(GameState state, SelectGuidedPlayer cmd) {
    if (state.status != GameStatus.inProgress) {
      return _fail(GameRuleViolationCode.playerNotAllowedToPlay);
    }
    if (state.rules.turnMode != TurnMode.guided || state.roundState == null) {
      return _fail(GameRuleViolationCode.playerNotAllowedToPlay);
    }
    final player = state.playerById(cmd.playerId);
    if (player == null) return _fail(GameRuleViolationCode.playerNotFound);
    if (player.hasLeftGame) return _fail(GameRuleViolationCode.playerHasLeft);
    if (!state.roundState!.pendingPlayerIds.contains(cmd.playerId)) {
      return _fail(GameRuleViolationCode.playerAlreadyPlayedThisRound);
    }

    final now = _now();
    final next = state.copyWith(
      roundState: state.roundState!.copyWith(currentPlayerId: cmd.playerId),
      updatedAt: now,
    );
    return _ok(state, next, null);
  }

  // ── Enregistrement d'un score (§22) ─────────────────────────────────────────

  EngineResult _recordScore(GameState state, RecordScore cmd) {
    final guard = _guardTurn(state, cmd.playerId);
    if (guard != null) return Failure(guard);

    if (cmd.amount <= 0) {
      return _fail(GameRuleViolationCode.scoreMustBePositive);
    }
    if (cmd.amount % state.rules.scoreStep != 0) {
      return _fail(GameRuleViolationCode.invalidScoreStep);
    }
    final player = state.playerById(cmd.playerId)!;
    // « Sortie » : il faut atteindre le minimum d'entrée non seulement au tout
    // premier score, mais AUSSI chaque fois qu'on repart de zéro (retombé à 0
    // après un 3ᵉ échec ou une rencontre). Tant que le total est nul, il faut
    // refaire le score de sortie pour rentrer.
    if (player.score == 0 && cmd.amount < state.rules.minimumEntryScore) {
      return _fail(GameRuleViolationCode.entryMinimumNotReached);
    }

    final future = player.score + cmd.amount;
    final wasFinalChance = state.status == GameStatus.finalChance;
    final target = state.rules.targetScore;

    final actionId = _newId();
    final ctx = _Ctx.from(state, actionId, _newId, _now);

    // Cas du dépassement : aucun gain, échec.
    if (state.rules.exactTargetRequired && future > target) {
      if (!cmd.confirmed) {
        return _fail(GameRuleViolationCode.confirmationRequiredForOvershoot,
            'Ce score ferait dépasser $target. Le tour deviendra un échec.');
      }
      _applyMiss(ctx, cmd.playerId);
      _advanceAfterTurn(ctx, cmd.playerId,
          wasFinalChance: wasFinalChance, startedFinalChance: false);
      final action = _turnAction(GameActionType.overshootRecorded, cmd.playerId,
          state, ctx, attemptedScore: cmd.amount);
      return _ok(state, ctx.build(state, action), action);
    }

    // Score valide.
    ctx.addGain(cmd.playerId, cmd.amount);
    ctx.markEntered(cmd.playerId);
    ctx.restoreLives(cmd.playerId);

    if (state.rules.encounterEnabled) {
      _resolveEncounters(ctx, cmd.playerId,
          chain: state.rules.encounterChainsEnabled);
    }

    final markerScore = ctx.player(cmd.playerId).score;
    var startedFinalChance = false;
    if (state.rules.finalChanceEnabled && markerScore == target) {
      startedFinalChance =
          _handleReachedTarget(ctx, cmd.playerId, wasFinalChance, actionId);
    }

    _advanceAfterTurn(ctx, cmd.playerId,
        wasFinalChance: wasFinalChance, startedFinalChance: startedFinalChance);

    final action =
        _turnAction(GameActionType.scoreRecorded, cmd.playerId, state, ctx);
    return _ok(state, ctx.build(state, action), action);
  }

  // ── Passage (§23) ────────────────────────────────────────────────────────────

  EngineResult _passTurn(GameState state, PassTurn cmd) {
    final guard = _guardTurn(state, cmd.playerId);
    if (guard != null) return Failure(guard);

    final player = state.playerById(cmd.playerId)!;
    final wouldBeThirdMiss = player.hasActiveGain && player.lives <= 1;
    if (wouldBeThirdMiss && state.rules.confirmThirdMiss && !cmd.confirmed) {
      return _fail(GameRuleViolationCode.confirmationRequiredForThirdMiss,
          'Troisième échec : le dernier gain sera annulé.');
    }

    final wasFinalChance = state.status == GameStatus.finalChance;
    final ctx = _Ctx.from(state, _newId(), _newId, _now);
    _applyMiss(ctx, cmd.playerId);
    _advanceAfterTurn(ctx, cmd.playerId,
        wasFinalChance: wasFinalChance, startedFinalChance: false);

    final action =
        _turnAction(GameActionType.passRecorded, cmd.playerId, state, ctx);
    return _ok(state, ctx.build(state, action), action);
  }

  // ── Départ d'un joueur (§17) ──────────────────────────────────────────────────

  EngineResult _leaveGame(GameState state, LeaveGame cmd) {
    if (state.status != GameStatus.inProgress &&
        state.status != GameStatus.finalChance) {
      return _fail(GameRuleViolationCode.gameNotStarted);
    }
    final player = state.playerById(cmd.playerId);
    if (player == null) return _fail(GameRuleViolationCode.playerNotFound);
    if (player.hasLeftGame) return _fail(GameRuleViolationCode.playerHasLeft);

    // Le candidat courant à 10 000 ne peut pas quitter individuellement (§17.2).
    if (state.status == GameStatus.finalChance &&
        state.finalChanceState?.currentCandidatePlayerId == cmd.playerId) {
      return _fail(GameRuleViolationCode.playerNotAllowedToPlay,
          'Le candidat à la victoire ne peut pas quitter la partie.');
    }

    final wasCurrent = _isCurrentPlayer(state, cmd.playerId);
    final ctx = _Ctx.from(state, _newId(), _newId, _now);
    ctx.markLeft(cmd.playerId);
    _removeFromTurnStructures(ctx, cmd.playerId, wasCurrent);

    final messages = <String>[];
    if (ctx.activePlayerIds().length < 2) {
      messages.add('Moins de deux joueurs actifs : fin anticipée possible.');
    }

    final action = _turnAction(GameActionType.playerLeft, cmd.playerId, state, ctx);
    return _ok(state, ctx.build(state, action), action, messages);
  }

  // ── Annulation (§19) ──────────────────────────────────────────────────────────

  EngineResult _undo(GameState state) {
    final action = state.lastActiveAction;
    const undoable = {
      GameActionType.scoreRecorded,
      GameActionType.passRecorded,
      GameActionType.overshootRecorded,
      GameActionType.playerLeft,
      GameActionType.gameFinished,
    };
    if (action == null || !undoable.contains(action.type)) {
      return _fail(GameRuleViolationCode.noActionToUndo);
    }

    final now = _now();
    final players = {for (final p in state.players) p.id: p};
    var status = state.status;
    var round = state.roundState;
    var finalChance = state.finalChanceState;
    var winner = state.winnerPlayerId;
    DateTime? finishedAt = state.finishedAt;

    // Rejoue les effets à l'envers, chacun restaurant sa valeur précédente.
    for (final effect in action.effects.reversed) {
      switch (effect.type) {
        case GameEffectType.lifeLost:
        case GameEffectType.livesRestored:
          final p = players[effect.targetPlayerId]!;
          players[p.id] = p.copyWith(lives: effect.previousValue! as int);
        case GameEffectType.playerEnteredGame:
          final p = players[effect.targetPlayerId]!;
          players[p.id] =
              p.copyWith(hasEnteredGame: effect.previousValue! as bool);
        case GameEffectType.playerMarkedAsLeft:
          final p = players[effect.targetPlayerId!]!;
          players[p.id] = p.copyWith(hasLeftGame: effect.previousValue! as bool);
        case GameEffectType.scoreGainCreated:
          final p = players[effect.targetPlayerId]!;
          players[p.id] = p.copyWith(
              gains: p.gains.where((g) => g.id != effect.gainId).toList());
        case GameEffectType.gainCancelledByThirdMiss:
        case GameEffectType.gainCancelledByEncounter:
          final p = players[effect.targetPlayerId]!;
          players[p.id] = p.copyWith(
            gains: p.gains
                .map((g) => g.id == effect.gainId
                    ? g.copyWith(
                        status: GainStatus.active, clearCancellation: true)
                    : g)
                .toList(),
          );
        case GameEffectType.gameStatusChanged:
          status = GameStatus.values.byName(effect.previousValue! as String);
          winner = effect.metadata['prevWinner'] as String?;
          final iso = effect.metadata['prevFinishedAt'] as String?;
          finishedAt = iso == null ? null : DateTime.parse(iso);
        case GameEffectType.roundAdvanced:
        case GameEffectType.currentPlayerChanged:
          round = effect.previousValue as RoundState?;
        case GameEffectType.finalChanceStarted:
        case GameEffectType.finalChanceConsumed:
        case GameEffectType.winnerCandidateChanged:
          finalChance = effect.previousValue as FinalChanceState?;
        case GameEffectType.encounterTriggered:
          break;
      }
    }

    final updatedActions = state.actions
        .map((a) => a.id == action.id
            ? a.copyWith(isUndone: true, undoneAt: now)
            : a)
        .toList();

    final next = state.copyWith(
      status: status,
      players: state.players.map((p) => players[p.id]!).toList(),
      actions: updatedActions,
      roundState: round,
      clearRoundState: round == null,
      finalChanceState: finalChance,
      clearFinalChanceState: finalChance == null,
      winnerPlayerId: winner,
      clearWinner: winner == null,
      finishedAt: finishedAt,
      clearFinishedAt: finishedAt == null,
      updatedAt: now,
    );
    return _ok(state, next, null);
  }

  // ── Sous-logiques partagées ───────────────────────────────────────────────────

  /// Vérifie qu'un joueur a le droit de jouer maintenant. Renvoie une violation
  /// ou `null` si tout est bon.
  GameRuleViolation? _guardTurn(GameState state, String playerId) {
    if (state.status == GameStatus.finished ||
        state.status == GameStatus.archived) {
      return const GameRuleViolation(GameRuleViolationCode.gameAlreadyFinished);
    }
    if (state.status == GameStatus.setup) {
      return const GameRuleViolation(GameRuleViolationCode.gameNotStarted);
    }
    final player = state.playerById(playerId);
    if (player == null) {
      return const GameRuleViolation(GameRuleViolationCode.playerNotFound);
    }
    if (player.hasLeftGame) {
      return const GameRuleViolation(GameRuleViolationCode.playerHasLeft);
    }
    if (!_isCurrentPlayer(state, playerId)) {
      return const GameRuleViolation(
          GameRuleViolationCode.playerNotAllowedToPlay);
    }
    return null;
  }

  /// Le joueur est-il autorisé à agir maintenant (selon mode et statut).
  bool _isCurrentPlayer(GameState state, String playerId) {
    if (state.status == GameStatus.finalChance) {
      final fc = state.finalChanceState;
      if (fc == null) return false;
      if (state.rules.turnMode == TurnMode.guided) {
        return fc.currentPlayerId == playerId;
      }
      return fc.pendingPlayerIds.contains(playerId);
    }
    // inProgress
    if (state.rules.turnMode == TurnMode.guided) {
      return state.roundState?.currentPlayerId == playerId;
    }
    return true; // mode libre : tout joueur actif peut agir
  }

  /// Applique la logique d'échec (passage ou dépassement) sur un joueur (§23).
  void _applyMiss(_Ctx ctx, String playerId) {
    final player = ctx.player(playerId);
    if (!player.hasActiveGain) {
      ctx.restoreLives(playerId); // aucune vie perdue, normalisation à max
      return;
    }
    if (player.lives > 1) {
      ctx.loseLife(playerId);
      return;
    }
    // Troisième échec : perte de la dernière vie, annulation, retour à max.
    ctx.loseLife(playerId);
    ctx.cancelLastActiveGain(playerId, GainCancelReason.thirdMiss);
    ctx.restoreLives(playerId);
  }

  /// Résout les rencontres déclenchées par le marqueur, **en cascade** (§14).
  ///
  /// Le marqueur « arrive » sur son nouveau total : tout adversaire actif au
  /// même score perd son dernier gain et redescend. En redescendant, cette
  /// victime peut à son tour percuter un autre joueur au même total, et ainsi
  /// de suite (`chain`). Un joueur ne peut être percuté qu'une fois par cascade,
  /// et le nombre de gains actifs décroît à chaque coup : la cascade se termine
  /// donc toujours. Contrairement à un tour réussi, une victime **ne récupère
  /// pas** ses cœurs simplement pour avoir été touchée : subir une rencontre
  /// n'est pas un tour joué (bug corrigé). En revanche, si le coup lui vide
  /// entièrement sa pile (retour à 0), elle redevient « hors jeu » et ses
  /// vies sont normalisées à 3 (F-003, DECISIONS.md).
  void _resolveEncounters(_Ctx ctx, String markerId, {required bool chain}) {
    // File des « arrivants » : joueurs qui viennent d'atterrir sur un nouveau
    // total et peuvent percuter un résident. On commence par le marqueur.
    final queue = <String>[markerId];
    final bumped = <String>{}; // déjà percutés (une seule fois chacun)
    final victims = <String>[]; // ordre des victimes, pour le récap / l'anim

    while (queue.isNotEmpty) {
      final arriverId = queue.removeAt(0);
      final score = ctx.player(arriverId).score;
      if (score <= 0) continue;

      final residents = ctx
          .activePlayerIds()
          .where((id) =>
              id != arriverId &&
              !bumped.contains(id) &&
              ctx.player(id).hasActiveGain &&
              ctx.player(id).score == score)
          .toList(); // figé avant toute annulation

      for (final residentId in residents) {
        final cancelled =
            ctx.cancelLastActiveGain(residentId, GainCancelReason.encounter);
        if (cancelled == null) continue;
        bumped.add(residentId);
        victims.add(residentId);
        // Pile vidée (retombée à 0) : la victime redevient « hors jeu » comme
        // au tout début — elle doit ressortir (F-003, DECISIONS.md). Ses vies
        // sont normalisées à 3, contrairement à une rencontre qui ne fait que
        // l'entamer (subir une rencontre n'est pas un tour joué).
        if (!ctx.player(residentId).hasActiveGain) {
          ctx.restoreLives(residentId);
        }
        // La victime redescend : en mode cascade, elle peut percuter à son tour.
        if (chain) queue.add(residentId);
      }
    }

    if (victims.isNotEmpty) {
      ctx.recordEncounter(markerId, victims, ctx.player(markerId).score);
    }
  }

  /// Le marqueur atteint exactement la cible : démarre ou met à jour la phase de
  /// dernière chance (§16). Renvoie `true` si la phase vient d'être créée.
  bool _handleReachedTarget(
      _Ctx ctx, String markerId, bool wasFinalChance, String actionId) {
    if (wasFinalChance) {
      // Le marqueur déloge le candidat (déjà annulé via la rencontre) et devient
      // le nouveau candidat.
      final fc = ctx.finalChance!;
      ctx.setFinalChance(
        fc.copyWith(currentCandidatePlayerId: markerId),
        GameEffectType.winnerCandidateChanged,
      );
      return false;
    }

    // Démarrage de la phase.
    final others = _orderStartingAfter(ctx, markerId);
    final fc = FinalChanceState(
      triggerActionId: actionId,
      initialCandidatePlayerId: markerId,
      currentCandidatePlayerId: markerId,
      pendingPlayerIds: others,
      completedPlayerIds: const [],
      currentPlayerId: others.isEmpty ? null : others.first,
    );
    ctx.setStatus(GameStatus.finalChance);
    ctx.setFinalChance(fc, GameEffectType.finalChanceStarted);
    return true;
  }

  /// Avance le tour après une action, selon le contexte.
  void _advanceAfterTurn(_Ctx ctx, String actorId,
      {required bool wasFinalChance, required bool startedFinalChance}) {
    if (wasFinalChance) {
      _advanceFinalChance(ctx, actorId);
      return;
    }
    if (startedFinalChance) {
      // Le marqueur est candidat, ne rejoue pas. Si personne d'autre : victoire.
      if (ctx.finalChance!.pendingPlayerIds.isEmpty) {
        _finishGame(ctx, ctx.finalChance!.currentCandidatePlayerId);
      }
      return;
    }
    // Partie normale.
    if (ctx.round != null) {
      _advanceGuidedRound(ctx, actorId);
    }
  }

  void _advanceFinalChance(_Ctx ctx, String actorId) {
    final fc = ctx.finalChance!;
    final pending = fc.pendingPlayerIds.where((id) => id != actorId).toList();
    final completed = [...fc.completedPlayerIds, actorId];
    if (pending.isEmpty) {
      ctx.setFinalChance(
        fc.copyWith(
            pendingPlayerIds: const [],
            completedPlayerIds: completed,
            clearCurrentPlayer: true),
        GameEffectType.finalChanceConsumed,
      );
      _finishGame(ctx, fc.currentCandidatePlayerId);
    } else {
      ctx.setFinalChance(
        fc.copyWith(
            pendingPlayerIds: pending,
            completedPlayerIds: completed,
            currentPlayerId: pending.first),
        GameEffectType.finalChanceConsumed,
      );
    }
  }

  void _advanceGuidedRound(_Ctx ctx, String actorId) {
    final r = ctx.round!;
    final pending = r.pendingPlayerIds.where((id) => id != actorId).toList();
    final completed = r.completedPlayerIds.contains(actorId)
        ? r.completedPlayerIds
        : [...r.completedPlayerIds, actorId];

    if (pending.isEmpty) {
      final actives = ctx.activePlayerIdsBySeat();
      ctx.setRound(RoundState(
        roundNumber: r.roundNumber + 1,
        currentPlayerId: actives.isEmpty ? null : actives.first,
        pendingPlayerIds: actives,
        completedPlayerIds: const [],
      ));
    } else {
      ctx.setRound(r.copyWith(
        pendingPlayerIds: pending,
        completedPlayerIds: completed,
        currentPlayerId: _nextBySeat(ctx, actorId, pending),
      ));
    }
  }

  void _removeFromTurnStructures(_Ctx ctx, String leaverId, bool wasCurrent) {
    // Manche ordinaire.
    if (ctx.round != null) {
      final r = ctx.round!;
      final pending = r.pendingPlayerIds.where((id) => id != leaverId).toList();
      final completed =
          r.completedPlayerIds.where((id) => id != leaverId).toList();
      String? current = r.currentPlayerId == leaverId ? null : r.currentPlayerId;
      if (wasCurrent) {
        if (pending.isEmpty) {
          final actives = ctx.activePlayerIdsBySeat();
          ctx.setRound(RoundState(
            roundNumber: r.roundNumber + 1,
            currentPlayerId: actives.isEmpty ? null : actives.first,
            pendingPlayerIds: actives,
            completedPlayerIds: const [],
          ));
          return;
        }
        current = _nextBySeat(ctx, leaverId, pending);
      }
      ctx.setRound(r.copyWith(
        pendingPlayerIds: pending,
        completedPlayerIds: completed,
        currentPlayerId: current,
        clearCurrentPlayer: current == null,
      ));
    }

    // Phase de dernière chance.
    if (ctx.finalChance != null) {
      final fc = ctx.finalChance!;
      final pending = fc.pendingPlayerIds.where((id) => id != leaverId).toList();
      final completed =
          fc.completedPlayerIds.where((id) => id != leaverId).toList();
      if (pending.isEmpty) {
        ctx.setFinalChance(
          fc.copyWith(
              pendingPlayerIds: const [],
              completedPlayerIds: completed,
              clearCurrentPlayer: true),
          GameEffectType.finalChanceConsumed,
        );
        _finishGame(ctx, fc.currentCandidatePlayerId);
      } else {
        final current =
            fc.currentPlayerId == leaverId ? pending.first : fc.currentPlayerId;
        ctx.setFinalChance(
          fc.copyWith(
              pendingPlayerIds: pending,
              completedPlayerIds: completed,
              currentPlayerId: current),
          GameEffectType.finalChanceConsumed,
        );
      }
    }
  }

  void _finishGame(_Ctx ctx, String winnerId) {
    ctx.setStatus(GameStatus.finished, winner: winnerId, finishedAt: _now());
  }

  // ── Aides diverses ─────────────────────────────────────────────────────────

  /// Ordre des autres joueurs actifs en commençant juste après le marqueur (§16.2).
  List<String> _orderStartingAfter(_Ctx ctx, String markerId) {
    final actives = ctx.activePlayersBySeat();
    final idx = actives.indexWhere((p) => p.id == markerId);
    final result = <String>[];
    for (var i = 1; i <= actives.length; i++) {
      final p = actives[(idx + i) % actives.length];
      if (p.id != markerId) result.add(p.id);
    }
    return result;
  }

  String _nextBySeat(_Ctx ctx, String actorId, List<String> pending) {
    final actorSeat = ctx.player(actorId).seatIndex;
    final pendingPlayers = pending.map(ctx.player).toList()
      ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
    for (final p in pendingPlayers) {
      if (p.seatIndex > actorSeat) return p.id;
    }
    return pendingPlayers.first.id; // repli circulaire
  }

  /// Nom affiché par défaut : une vraie espèce tirée au hasard parmi les
  /// variantes du totem (ex. « Bouvreuil » pour l'oiseau), ou le nom générique
  /// si aucune variante n'est définie.
  String _speciesName(AnimalAvatar avatar) {
    if (avatar.species.isEmpty) return avatar.defaultFrenchName;
    return avatar.species[_random.nextInt(avatar.species.length)];
  }

  /// Nom façon totem scout : l'espèce tirée + une épithète piochée dans le
  /// catalogue sage ou trash (§ [AdjectiveCatalog]), ex. « Bouvreuil Farceur ».
  String _scoutName(AnimalAvatar avatar,
      {required bool trash, List<String> custom = const []}) {
    final species = _speciesName(avatar);
    // Les épithètes perso (ajoutées à la table) comptent double dans le tirage :
    // face aux ~70 épithètes du catalogue de base, elles ne sortiraient presque
    // jamais sinon. Les dupliquer dans le pool est la façon la plus simple de
    // leur donner un poids 2× sous un tirage uniforme.
    final pool = trash
        ? [...AdjectiveCatalog.trash, ...custom, ...custom]
        : AdjectiveCatalog.safe;
    if (pool.isEmpty) return species;
    return '$species ${pool[_random.nextInt(pool.length)]}';
  }

  AnimalAvatar? _drawAvatar(List<Player> players) {
    final usedIds = players.map((p) => p.avatarId).toSet();
    final usedFamilies = players
        .map((p) => AnimalCatalog.all
            .firstWhere((a) => a.id == p.avatarId)
            .familyId)
        .toSet();
    final candidates =
        AnimalCatalog.eligible.where((a) => !usedIds.contains(a.id)).toList();
    if (candidates.isEmpty) return null;

    // Préférence : éviter une famille déjà utilisée quand c'est possible (§6.3).
    final preferred =
        candidates.where((a) => !usedFamilies.contains(a.familyId)).toList();
    final pool = preferred.isNotEmpty ? preferred : candidates;
    return pool[_random.nextInt(pool.length)];
  }

  ColorToken? _drawColor(List<Player> players) {
    final usedIds = players.map((p) => p.colorId).toSet();
    final candidates =
        ColorCatalog.all.where((c) => !usedIds.contains(c.id)).toList();
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  GameAction _prepAction(GameActionType type, String? playerId) {
    return GameAction(
      id: _newId(),
      type: type,
      primaryPlayerId: playerId,
      createdAt: _now(),
      effects: const [],
    );
  }

  GameAction _turnAction(GameActionType type, String playerId, GameState state,
      _Ctx ctx,
      {int? attemptedScore}) {
    return GameAction(
      id: ctx.actionId,
      type: type,
      primaryPlayerId: playerId,
      createdAt: _now(),
      roundNumber: state.roundState?.roundNumber,
      attemptedScore: attemptedScore,
      effects: ctx.effects,
    );
  }

  Success _ok(GameState prev, GameState next, GameAction? action,
          [List<String> messages = const []]) =>
      Success(GameTransition(
          previousState: prev,
          nextState: next,
          action: action,
          userMessages: messages));

  Failure _fail(GameRuleViolationCode code, [String? message]) =>
      Failure(GameRuleViolation(code, message));
}

/// Contexte mutable interne, le temps de résoudre une action. Il accumule les
/// effets réversibles et une copie de travail des champs modifiables.
class _Ctx {
  _Ctx._(
    this.actionId,
    this._players,
    this.status,
    this.round,
    this.finalChance,
    this.winner,
    this.finishedAt,
    this._newId,
    this._now,
  );

  factory _Ctx.from(GameState state, String actionId, String Function() newId,
      DateTime Function() now) {
    return _Ctx._(
      actionId,
      {for (final p in state.players) p.id: p},
      state.status,
      state.roundState,
      state.finalChanceState,
      state.winnerPlayerId,
      state.finishedAt,
      newId,
      now,
    );
  }

  final String actionId;
  final Map<String, Player> _players;
  GameStatus status;
  RoundState? round;
  FinalChanceState? finalChance;
  String? winner;
  DateTime? finishedAt;
  final String Function() _newId;
  final DateTime Function() _now;
  final List<GameEffect> effects = [];

  Player player(String id) => _players[id]!;

  List<String> activePlayerIds() =>
      _players.values.where((p) => !p.hasLeftGame).map((p) => p.id).toList();

  List<Player> activePlayersBySeat() {
    final list = _players.values.where((p) => !p.hasLeftGame).toList()
      ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
    return list;
  }

  List<String> activePlayerIdsBySeat() =>
      activePlayersBySeat().map((p) => p.id).toList();

  int _nextGainSequence() {
    var max = -1;
    for (final p in _players.values) {
      for (final g in p.gains) {
        if (g.sequence > max) max = g.sequence;
      }
    }
    return max + 1;
  }

  GameEffect _effect(
    GameEffectType type, {
    String? targetPlayerId,
    String? gainId,
    int? delta,
    Object? previousValue,
    Object? nextValue,
    Map<String, Object?> metadata = const {},
  }) {
    final e = GameEffect(
      id: _newId(),
      type: type,
      targetPlayerId: targetPlayerId,
      gainId: gainId,
      delta: delta,
      previousValue: previousValue,
      nextValue: nextValue,
      metadata: metadata,
    );
    effects.add(e);
    return e;
  }

  // Mutations enregistrées comme effets réversibles.

  Gain addGain(String playerId, int amount) {
    final p = player(playerId);
    final gain = Gain(
      id: _newId(),
      playerId: playerId,
      amount: amount,
      createdByActionId: actionId,
      createdAt: _now(),
      sequence: _nextGainSequence(),
    );
    _players[playerId] = p.copyWith(gains: [...p.gains, gain]);
    _effect(GameEffectType.scoreGainCreated,
        targetPlayerId: playerId,
        gainId: gain.id,
        delta: amount,
        nextValue: amount);
    return gain;
  }

  Gain? cancelLastActiveGain(String playerId, GainCancelReason reason) {
    final p = player(playerId);
    final last = p.lastActiveGain;
    if (last == null) return null;
    final cancelled = last.copyWith(
      status: GainStatus.cancelled,
      cancelReason: reason,
      cancelledByActionId: actionId,
      cancelledAt: _now(),
    );
    _players[playerId] = p.copyWith(
        gains: p.gains.map((g) => g.id == last.id ? cancelled : g).toList());
    final type = reason == GainCancelReason.thirdMiss
        ? GameEffectType.gainCancelledByThirdMiss
        : GameEffectType.gainCancelledByEncounter;
    _effect(type,
        targetPlayerId: playerId,
        gainId: last.id,
        delta: -last.amount,
        previousValue: 'active',
        nextValue: 'cancelled');
    return last;
  }

  void loseLife(String playerId) {
    final p = player(playerId);
    final next = p.lives - 1;
    _players[playerId] = p.copyWith(lives: next);
    _effect(GameEffectType.lifeLost,
        targetPlayerId: playerId,
        delta: -1,
        previousValue: p.lives,
        nextValue: next);
  }

  void restoreLives(String playerId) {
    final p = player(playerId);
    const max = 3;
    if (p.lives == max) return;
    _players[playerId] = p.copyWith(lives: max);
    _effect(GameEffectType.livesRestored,
        targetPlayerId: playerId, previousValue: p.lives, nextValue: max);
  }

  void markEntered(String playerId) {
    final p = player(playerId);
    if (p.hasEnteredGame) return;
    _players[playerId] = p.copyWith(hasEnteredGame: true);
    _effect(GameEffectType.playerEnteredGame,
        targetPlayerId: playerId, previousValue: false, nextValue: true);
  }

  void markLeft(String playerId) {
    final p = player(playerId);
    _players[playerId] = p.copyWith(hasLeftGame: true);
    _effect(GameEffectType.playerMarkedAsLeft,
        targetPlayerId: playerId, previousValue: false, nextValue: true);
  }

  void setStatus(GameStatus newStatus, {String? winner, DateTime? finishedAt}) {
    final prevStatus = status;
    final prevWinner = this.winner;
    final prevFinishedAt = this.finishedAt;
    status = newStatus;
    if (winner != null) this.winner = winner;
    if (finishedAt != null) this.finishedAt = finishedAt;
    _effect(GameEffectType.gameStatusChanged,
        previousValue: prevStatus.name,
        nextValue: newStatus.name,
        metadata: {
          'prevWinner': prevWinner,
          'nextWinner': this.winner,
          'prevFinishedAt': prevFinishedAt?.toIso8601String(),
          'nextFinishedAt': this.finishedAt?.toIso8601String(),
        });
  }

  void setRound(RoundState? newRound) {
    final prev = round;
    final type = (prev?.roundNumber != newRound?.roundNumber)
        ? GameEffectType.roundAdvanced
        : GameEffectType.currentPlayerChanged;
    round = newRound;
    _effect(type, previousValue: prev, nextValue: newRound);
  }

  void setFinalChance(FinalChanceState? newFc, GameEffectType type) {
    final prev = finalChance;
    finalChance = newFc;
    _effect(type, previousValue: prev, nextValue: newFc);
  }

  void recordEncounter(String markerId, List<String> victimIds, int score) {
    _effect(GameEffectType.encounterTriggered,
        targetPlayerId: markerId,
        metadata: {'victimIds': victimIds, 'score': score});
  }

  /// Assemble le nouvel état à partir de la copie de travail.
  GameState build(GameState state, GameAction action) {
    return state.copyWith(
      status: status,
      players: state.players.map((p) => _players[p.id]!).toList(),
      actions: [...state.actions, action],
      roundState: round,
      clearRoundState: round == null,
      finalChanceState: finalChance,
      clearFinalChanceState: finalChance == null,
      winnerPlayerId: winner,
      clearWinner: winner == null,
      finishedAt: finishedAt,
      clearFinishedAt: finishedAt == null,
      updatedAt: _now(),
    );
  }
}

/// Petit utilitaire pour compter les caractères visibles (approché) sans couper
/// les emojis multi-codepoints de façon grossière.
extension _CharCount on String {
  Iterable<int> characters() => runes;
}
