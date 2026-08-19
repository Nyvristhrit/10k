import '../enums/game_enums.dart';
import '../models/game_rules.dart';

/// Commandes envoyées au moteur (§25.1, §25.2).
///
/// Le moteur transforme une commande + un état en un nouvel état. Les
/// commandes sont de simples intentions, sans logique.
sealed class GameCommand {
  const GameCommand();
}

// ── Commandes de préparation (§25.1) ────────────────────────────────────────

/// Crée une nouvelle partie vide en statut `setup`.
class CreateGame extends GameCommand {
  const CreateGame({this.rules = const GameRules()});
  final GameRules rules;
}

/// Ajoute un joueur (animal + couleur tirés automatiquement).
class AddPlayer extends GameCommand {
  const AddPlayer({
    this.displayName,
    this.trashNames = false,
    this.customTrashAdjectives = const [],
  });

  /// Nom personnalisé facultatif ; sinon un nom « espèce + épithète » tiré au
  /// hasard (§ [AdjectiveCatalog]).
  final String? displayName;

  /// Pioche l'épithète dans le pool trash plutôt que le pool sage.
  final bool trashNames;

  /// Épithètes trash ajoutées par la table (réglages), piochées en plus du
  /// catalogue de base quand [trashNames] est vrai.
  final List<String> customTrashAdjectives;
}

/// Renomme un joueur avant le lancement.
class RenamePlayer extends GameCommand {
  const RenamePlayer({required this.playerId, required this.newName});
  final String playerId;
  final String newName;
}

/// Supprime définitivement un joueur avant le lancement.
class RemovePlayerBeforeStart extends GameCommand {
  const RemovePlayerBeforeStart({required this.playerId});
  final String playerId;
}

/// Met à jour les règles (uniquement en `setup`).
class UpdateRules extends GameCommand {
  const UpdateRules({required this.rules});
  final GameRules rules;
}

/// Démarre la partie : verrouille joueurs/règles, passe en `inProgress`.
class StartGame extends GameCommand {
  const StartGame();
}

// ── Commandes en partie (§25.2) ─────────────────────────────────────────────

/// Rend un autre joueur actif en mode guidé (sélection hors ordre, §9.1).
class SelectGuidedPlayer extends GameCommand {
  const SelectGuidedPlayer({required this.playerId});
  final String playerId;
}

/// Enregistre un score positif pour un joueur.
class RecordScore extends GameCommand {
  const RecordScore({
    required this.playerId,
    required this.amount,
    this.confirmed = false,
  });

  final String playerId;
  final int amount;

  /// `true` quand l'utilisateur a confirmé un dépassement ou un troisième échec.
  final bool confirmed;
}

/// Passe le tour d'un joueur (échec volontaire ou dépassement).
class PassTurn extends GameCommand {
  const PassTurn({
    required this.playerId,
    this.reason = PassReason.manualPass,
    this.confirmed = false,
  });

  final String playerId;
  final PassReason reason;
  final bool confirmed;
}

/// Fait quitter la partie à un joueur (historique conservé, §17).
class LeaveGame extends GameCommand {
  const LeaveGame({required this.playerId});
  final String playerId;
}

/// Annule la dernière action complète non annulée (§19).
class UndoLastAction extends GameCommand {
  const UndoLastAction();
}
