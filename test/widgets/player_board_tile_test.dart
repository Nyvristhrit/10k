import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/domain/models/player.dart';
import 'package:tenk/features/game_board/widgets/player_board_tile.dart';

/// Un nom trop long ne doit ni être coupé en plein mot ni faire déborder la
/// tuile.
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
          // Plus petite tuile réaliste (grille à plusieurs colonnes sur un
          // téléphone compact).
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
