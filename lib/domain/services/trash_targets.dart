import '../models/game_state.dart';

/// Désigne le « bonnet d'âne » d'une partie : le joueur bon dernier, qui se voit
/// confisquer son totem au profit d'un 💩 en mode trash (§ mode trash).
///
/// Logique volontairement clémente — on ne se moque que quand c'est mérité :
/// * il faut au moins deux joueurs encore en lice ;
/// * il faut que la partie ait vraiment commencé (quelqu'un a marqué) ;
/// * il faut un dernier **unique** : en cas d'ex æquo, personne n'est humilié.
///
/// Renvoie l'identifiant du joueur concerné, ou `null` s'il n'y a pas lieu.
String? lastPlaceId(GameState game) {
  final contenders = game.players.where((p) => !p.hasLeftGame).toList();
  if (contenders.length < 2) return null;

  var highest = contenders.first.score;
  var lowest = contenders.first.score;
  for (final p in contenders) {
    if (p.score > highest) highest = p.score;
    if (p.score < lowest) lowest = p.score;
  }

  // Tout le monde à zéro (ou début de partie) : rien à railler pour l'instant.
  if (highest <= 0) return null;

  final trailing = contenders.where((p) => p.score == lowest).toList();
  if (trailing.length != 1) return null; // ex æquo : pas de bonnet d'âne
  return trailing.first.id;
}
