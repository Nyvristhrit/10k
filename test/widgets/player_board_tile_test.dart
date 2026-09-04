import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/domain/models/player.dart';
import 'package:tenk/features/game_board/widgets/player_board_tile.dart';

/// Un nom trop long (espèce + épithète composées) ne doit jamais être coupé
/// au milieu d'un mot ni faire déborder la tuile — voir CHANGELOG (correctif
/// FittedBox du 4 sept. 2026, suite à un signalement sur un écran large où
/// « Crevette rose Raclure de bidet » était tronqué en plein mot).
void main() {
  testWidgets('un nom très long ne fait pas déborder une tuile étroite',
      (tester) async {
    final player = Player(
      id: 'p1',
      avatarId: 'inconnu',
      colorId: 'inconnu',
      displayName: 'Blaireau d’Europe Raclure de bidet supplémentaire',
      seatIndex: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          // Tuile étroite, comme dans une grille à plusieurs colonnes (la
          // plus petite taille réaliste produite par `_columnsFor` sur un
          // téléphone compact — en dessous, même l'emoji et les cœurs seuls
          // ne tiennent plus, indépendamment de tout nom de joueur).
          width: 200,
          height: 160,
          child: PlayerBoardTile(
            player: player,
            isActive: false,
            onTap: () {},
            compact: true,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Raclure'), findsOneWidget);
  });
}
