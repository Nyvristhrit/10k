import '../../domain/enums/game_enums.dart';
import '../../domain/models/final_chance_state.dart';
import '../../domain/models/gain.dart';
import '../../domain/models/game_action.dart';
import '../../domain/models/game_effect.dart';
import '../../domain/models/game_rules.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/round_state.dart';

/// Sérialisation JSON de l'état de jeu (couche `data`).
///
/// Objectif : garantir qu'une partie enregistrée se recharge **exactement**
/// à l'identique (§27.4, §27.6). Le journal d'actions et ses effets réversibles
/// sont conservés, de sorte que l'annulation reste possible après réouverture.
///
/// La couche `domain` reste pure : c'est ici (couche `data`) qu'on connaît le
/// format de stockage.
class GameSerialization {
  const GameSerialization._();

  // ── État complet ────────────────────────────────────────────────────────────

  static Map<String, dynamic> toJson(GameState s) => {
        'id': s.id,
        'status': s.status.name,
        'rules': _rulesToJson(s.rules),
        'players': s.players.map(_playerToJson).toList(),
        'actions': s.actions.map(_actionToJson).toList(),
        'roundState': s.roundState == null ? null : _roundToJson(s.roundState!),
        'finalChanceState':
            s.finalChanceState == null ? null : _fcToJson(s.finalChanceState!),
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
        'finishedAt': s.finishedAt?.toIso8601String(),
        'winnerPlayerId': s.winnerPlayerId,
        'schemaVersion': s.schemaVersion,
      };

  static GameState fromJson(Map<String, dynamic> j) => GameState(
        id: j['id'] as String,
        status: GameStatus.values.byName(j['status'] as String),
        rules: _rulesFromJson(j['rules'] as Map<String, dynamic>),
        players: (j['players'] as List)
            .map((e) => _playerFromJson(e as Map<String, dynamic>))
            .toList(),
        actions: (j['actions'] as List)
            .map((e) => _actionFromJson(e as Map<String, dynamic>))
            .toList(),
        roundState: j['roundState'] == null
            ? null
            : _roundFromJson(j['roundState'] as Map<String, dynamic>),
        finalChanceState: j['finalChanceState'] == null
            ? null
            : _fcFromJson(j['finalChanceState'] as Map<String, dynamic>),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        finishedAt: j['finishedAt'] == null
            ? null
            : DateTime.parse(j['finishedAt'] as String),
        winnerPlayerId: j['winnerPlayerId'] as String?,
        schemaVersion: j['schemaVersion'] as int,
      );

  // ── Règles ──────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _rulesToJson(GameRules r) => {
        'targetScore': r.targetScore,
        'exactTargetRequired': r.exactTargetRequired,
        'scoreStep': r.scoreStep,
        'minimumEntryScore': r.minimumEntryScore,
        'maxLives': r.maxLives,
        'turnMode': r.turnMode.name,
        'confirmThirdMiss': r.confirmThirdMiss,
        'encounterEnabled': r.encounterEnabled,
        'encounterAlertsEnabled': r.encounterAlertsEnabled,
        'encounterAffectsAllMatches': r.encounterAffectsAllMatches,
        'encounterChainsEnabled': r.encounterChainsEnabled,
        'overshootCountsAsMiss': r.overshootCountsAsMiss,
        'finalChanceEnabled': r.finalChanceEnabled,
      };

  static GameRules _rulesFromJson(Map<String, dynamic> j) => GameRules(
        targetScore: j['targetScore'] as int,
        exactTargetRequired: j['exactTargetRequired'] as bool,
        scoreStep: j['scoreStep'] as int,
        minimumEntryScore: j['minimumEntryScore'] as int,
        maxLives: j['maxLives'] as int,
        turnMode: TurnMode.values.byName(j['turnMode'] as String),
        confirmThirdMiss: j['confirmThirdMiss'] as bool,
        encounterEnabled: j['encounterEnabled'] as bool,
        // Défaut `true` pour les parties enregistrées avant l'ajout du réglage.
        encounterAlertsEnabled: (j['encounterAlertsEnabled'] as bool?) ?? true,
        encounterAffectsAllMatches: j['encounterAffectsAllMatches'] as bool,
        encounterChainsEnabled: j['encounterChainsEnabled'] as bool,
        overshootCountsAsMiss: j['overshootCountsAsMiss'] as bool,
        finalChanceEnabled: j['finalChanceEnabled'] as bool,
      );

  // ── Joueur et gains ──────────────────────────────────────────────────────────

  static Map<String, dynamic> _playerToJson(Player p) => {
        'id': p.id,
        'avatarId': p.avatarId,
        'colorId': p.colorId,
        'displayName': p.displayName,
        'seatIndex': p.seatIndex,
        'createdAt': p.createdAt.toIso8601String(),
        'lives': p.lives,
        'hasEnteredGame': p.hasEnteredGame,
        'hasLeftGame': p.hasLeftGame,
        'gains': p.gains.map(_gainToJson).toList(),
      };

  static Player _playerFromJson(Map<String, dynamic> j) => Player(
        id: j['id'] as String,
        avatarId: j['avatarId'] as String,
        colorId: j['colorId'] as String,
        displayName: j['displayName'] as String,
        seatIndex: j['seatIndex'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        lives: j['lives'] as int,
        hasEnteredGame: j['hasEnteredGame'] as bool,
        hasLeftGame: j['hasLeftGame'] as bool,
        gains: (j['gains'] as List)
            .map((e) => _gainFromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static Map<String, dynamic> _gainToJson(Gain g) => {
        'id': g.id,
        'playerId': g.playerId,
        'amount': g.amount,
        'createdByActionId': g.createdByActionId,
        'createdAt': g.createdAt.toIso8601String(),
        'sequence': g.sequence,
        'status': g.status.name,
        'cancelledByActionId': g.cancelledByActionId,
        'cancelReason': g.cancelReason?.name,
        'cancelledAt': g.cancelledAt?.toIso8601String(),
      };

  static Gain _gainFromJson(Map<String, dynamic> j) => Gain(
        id: j['id'] as String,
        playerId: j['playerId'] as String,
        amount: j['amount'] as int,
        createdByActionId: j['createdByActionId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        sequence: j['sequence'] as int,
        status: GainStatus.values.byName(j['status'] as String),
        cancelledByActionId: j['cancelledByActionId'] as String?,
        cancelReason: j['cancelReason'] == null
            ? null
            : GainCancelReason.values.byName(j['cancelReason'] as String),
        cancelledAt: j['cancelledAt'] == null
            ? null
            : DateTime.parse(j['cancelledAt'] as String),
      );

  // ── Actions et effets ────────────────────────────────────────────────────────

  static Map<String, dynamic> _actionToJson(GameAction a) => {
        'id': a.id,
        'type': a.type.name,
        'primaryPlayerId': a.primaryPlayerId,
        'createdAt': a.createdAt.toIso8601String(),
        'roundNumber': a.roundNumber,
        'attemptedScore': a.attemptedScore,
        'effects': a.effects.map(_effectToJson).toList(),
        'isUndone': a.isUndone,
        'undoneAt': a.undoneAt?.toIso8601String(),
      };

  static GameAction _actionFromJson(Map<String, dynamic> j) => GameAction(
        id: j['id'] as String,
        type: GameActionType.values.byName(j['type'] as String),
        primaryPlayerId: j['primaryPlayerId'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        roundNumber: j['roundNumber'] as int?,
        attemptedScore: j['attemptedScore'] as int?,
        effects: (j['effects'] as List)
            .map((e) => _effectFromJson(e as Map<String, dynamic>))
            .toList(),
        isUndone: j['isUndone'] as bool,
        undoneAt: j['undoneAt'] == null
            ? null
            : DateTime.parse(j['undoneAt'] as String),
      );

  static Map<String, dynamic> _effectToJson(GameEffect e) => {
        'id': e.id,
        'type': e.type.name,
        'targetPlayerId': e.targetPlayerId,
        'gainId': e.gainId,
        'delta': e.delta,
        'previousValue': _encodeValue(e.previousValue),
        'nextValue': _encodeValue(e.nextValue),
        'metadata': e.metadata,
      };

  static GameEffect _effectFromJson(Map<String, dynamic> j) => GameEffect(
        id: j['id'] as String,
        type: GameEffectType.values.byName(j['type'] as String),
        targetPlayerId: j['targetPlayerId'] as String?,
        gainId: j['gainId'] as String?,
        delta: j['delta'] as int?,
        previousValue: _decodeValue(j['previousValue']),
        nextValue: _decodeValue(j['nextValue']),
        metadata: (j['metadata'] as Map).cast<String, Object?>(),
      );

  /// Encodage typé des valeurs polymorphes d'un effet (int, bool, String, ou
  /// un instantané de manche / dernière chance) pour l'annulation après reprise.
  static Map<String, dynamic> _encodeValue(Object? v) {
    if (v == null) return {'k': 'null'};
    if (v is int) return {'k': 'int', 'v': v};
    if (v is bool) return {'k': 'bool', 'v': v};
    if (v is String) return {'k': 'str', 'v': v};
    if (v is RoundState) return {'k': 'round', 'v': _roundToJson(v)};
    if (v is FinalChanceState) return {'k': 'fc', 'v': _fcToJson(v)};
    throw ArgumentError('Type d\'effet non sérialisable : ${v.runtimeType}');
  }

  static Object? _decodeValue(Object? raw) {
    final m = raw as Map<String, dynamic>;
    return switch (m['k'] as String) {
      'null' => null,
      'int' => m['v'] as int,
      'bool' => m['v'] as bool,
      'str' => m['v'] as String,
      'round' => _roundFromJson(m['v'] as Map<String, dynamic>),
      'fc' => _fcFromJson(m['v'] as Map<String, dynamic>),
      _ => throw ArgumentError('Clé d\'effet inconnue : ${m['k']}'),
    };
  }

  // ── Manche et dernière chance ────────────────────────────────────────────────

  static Map<String, dynamic> _roundToJson(RoundState r) => {
        'roundNumber': r.roundNumber,
        'currentPlayerId': r.currentPlayerId,
        'pendingPlayerIds': r.pendingPlayerIds,
        'completedPlayerIds': r.completedPlayerIds,
      };

  static RoundState _roundFromJson(Map<String, dynamic> j) => RoundState(
        roundNumber: j['roundNumber'] as int,
        currentPlayerId: j['currentPlayerId'] as String?,
        pendingPlayerIds: (j['pendingPlayerIds'] as List).cast<String>(),
        completedPlayerIds: (j['completedPlayerIds'] as List).cast<String>(),
      );

  static Map<String, dynamic> _fcToJson(FinalChanceState f) => {
        'triggerActionId': f.triggerActionId,
        'initialCandidatePlayerId': f.initialCandidatePlayerId,
        'currentCandidatePlayerId': f.currentCandidatePlayerId,
        'pendingPlayerIds': f.pendingPlayerIds,
        'completedPlayerIds': f.completedPlayerIds,
        'currentPlayerId': f.currentPlayerId,
      };

  static FinalChanceState _fcFromJson(Map<String, dynamic> j) =>
      FinalChanceState(
        triggerActionId: j['triggerActionId'] as String,
        initialCandidatePlayerId: j['initialCandidatePlayerId'] as String,
        currentCandidatePlayerId: j['currentCandidatePlayerId'] as String,
        pendingPlayerIds: (j['pendingPlayerIds'] as List).cast<String>(),
        completedPlayerIds: (j['completedPlayerIds'] as List).cast<String>(),
        currentPlayerId: j['currentPlayerId'] as String?,
      );
}
