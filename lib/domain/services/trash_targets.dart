import '../models/game_state.dart';

/// Le bon dernier de la partie (mode trash), ou `null`.
///
/// Il faut au moins deux joueurs en lice, au moins un score marqué et un
/// dernier unique (pas d'ex aequo).
String? lastPlaceId(GameState game) {
  final contenders = game.players.where((p) => !p.hasLeftGame).toList();
  if (contenders.length < 2) return null;

  var highest = contenders.first.score;
  var lowest = contenders.first.score;
  for (final p in contenders) {
    if (p.score > highest) highest = p.score;
    if (p.score < lowest) lowest = p.score;
  }

  // Personne n'a encore marqué.
  if (highest <= 0) return null;

  final trailing = contenders.where((p) => p.score == lowest).toList();
  if (trailing.length != 1) return null; // ex æquo : pas de bonnet d'âne
  return trailing.first.id;
}
