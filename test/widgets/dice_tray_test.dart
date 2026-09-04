import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/features/dice_tray/dice_tray_screen.dart';

/// Plateau de dés virtuel (§ évolution « jouer sans dés physiques ») :
/// lancer, garder de côté, relancer le reste.
void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        const MaterialApp(home: DiceTrayScreen()),
      );

  Finder dieAt(int i) => find.byKey(ValueKey('dice_tray_die_$i'));

  testWidgets('propose de lancer avant le premier jet', (tester) async {
    await pump(tester);
    expect(find.text('Lancer les dés'), findsOneWidget);
  });

  testWidgets('lancer les dés fait passer au bouton « Relancer »',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Lancer les dés'));
    await tester.pump();
    // Laisse l'animation (lancer + délai aléatoire par dé) se terminer.
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('Relancer'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      expect(dieAt(i), findsOneWidget);
    }
  });

  testWidgets('garder tous les dés désactive la relance', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Lancer les dés'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i++) {
      await tester.tap(dieAt(i));
      await tester.pump();
    }

    expect(find.text('Tous gardés'), findsOneWidget);
    final button =
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    // « Tout libérer » réapparaît et rend la relance possible.
    await tester.tap(find.text('Tout libérer'));
    await tester.pump();
    expect(find.textContaining('Relancer (6)'), findsOneWidget);
  });
}
