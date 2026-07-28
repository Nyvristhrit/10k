import 'package:equatable/equatable.dart';

import '../enums/game_enums.dart';
import 'final_chance_state.dart';
import 'game_action.dart';
import 'game_rules.dart';
import 'player.dart';
import 'round_state.dart';

/// État complet et immuable d'une partie (§24.11).
///
/// C'est la « photo » du jeu à un instant donné. Le moteur ne modifie jamais
/// un état : il en produit un nouveau (`apply(state, command) -> transition`).
class GameState extends Equatable {
  const GameState({
    required this.id,
    required this.status,
    required this.rules,
    required this.players,
    required this.actions,
    required this.createdAt,
    required this.updatedAt,
    this.roundState,
    this.finalChanceState,
    this.finishedAt,
    this.winnerPlayerId,
    this.schemaVersion = 1,
  });

  final String id;
  final GameStatus status;
  final GameRules rules;
  final List<Player> players;

  /// Journal chronologique des actions (inclut les actions annulées).
  final List<GameAction> actions;

  final RoundState? roundState;
  final FinalChanceState? finalChanceState;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;
  final String? winnerPlayerId;
  final int schemaVersion;

  /// Retrouve un joueur par son id, ou `null`.
  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Joueurs encore dans la partie (non partis), triés par place à la table.
  List<Player> get activePlayers {
    final list = players.where((p) => !p.hasLeftGame).toList()
      ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
    return List.unmodifiable(list);
  }

  /// La dernière action non annulée (cible d'un « Annuler »), ou `null`.
  GameAction? get lastActiveAction {
    for (var i = actions.length - 1; i >= 0; i--) {
      if (!actions[i].isUndone) return actions[i];
    }
    return null;
  }

  GameState copyWith({
    GameStatus? status,
    GameRules? rules,
    List<Player>? players,
    List<GameAction>? actions,
    RoundState? roundState,
    bool clearRoundState = false,
    FinalChanceState? finalChanceState,
    bool clearFinalChanceState = false,
    DateTime? updatedAt,
    DateTime? finishedAt,
    bool clearFinishedAt = false,
    String? winnerPlayerId,
    bool clearWinner = false,
    int? schemaVersion,
  }) {
    return GameState(
      id: id,
      status: status ?? this.status,
      rules: rules ?? this.rules,
      players: players ?? this.players,
      actions: actions ?? this.actions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roundState: clearRoundState ? null : (roundState ?? this.roundState),
      finalChanceState: clearFinalChanceState
          ? null
          : (finalChanceState ?? this.finalChanceState),
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      winnerPlayerId:
          clearWinner ? null : (winnerPlayerId ?? this.winnerPlayerId),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        rules,
        players,
        actions,
        roundState,
        finalChanceState,
        finishedAt,
        winnerPlayerId,
        schemaVersion,
      ];
}
