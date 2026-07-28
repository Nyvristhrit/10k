import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Génère les images sources de l'icône de l'appli (dessinées en code) puis les
/// enregistre dans `assets/icon/`. À lancer avec :
///   flutter test test/tools/generate_app_icon.dart
/// Ensuite : `dart run flutter_launcher_icons` produit toutes les tailles.
void main() {
  testWidgets('génère les icônes 10K', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1024));

    // Icône « pleine » (dégradé + dé) → icône classique + iOS.
    await _render(tester, const _IconPainter(background: true, dieScale: 0.60),
        'assets/icon/icon.png');
    // Fond seul (dégradé) → arrière-plan de l'icône adaptative Android.
    await _render(tester, const _IconPainter(background: true, dieScale: 0),
        'assets/icon/icon_background.png');
    // Dé seul sur fond transparent → premier plan de l'icône adaptative.
    await _render(tester, const _IconPainter(background: false, dieScale: 0.52),
        'assets/icon/icon_foreground.png');
  });
}

Future<void> _render(
    WidgetTester tester, CustomPainter painter, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: CustomPaint(size: const Size(1024, 1024), painter: painter),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  late Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });

  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  // ignore: avoid_print
  print('Icône écrite : $path (${bytes.length} octets)');
}

/// Dessine l'icône : un dégradé de la charte + un dé blanc à cinq pois.
class _IconPainter extends CustomPainter {
  const _IconPainter({required this.background, required this.dieScale});

  final bool background;
  final double dieScale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (background) {
      // Fond « arc-en-ciel » : des bandeaux de couleur en diagonale, façon
      // pride et clin d'œil aux cartes des joueurs (toutes en couleurs).
      const stripes = [
        Color(0xFFE11D48), // rouge
        Color(0xFFF97316), // orange
        Color(0xFFFACC15), // jaune
        Color(0xFF22C55E), // vert
        Color(0xFF3B82F6), // bleu
        Color(0xFF8B5CF6), // violet
      ];
      canvas.save();
      canvas.clipRect(rect);
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(-0.7853981633974483); // -45° → bandeaux en diagonale
      final n = stripes.length;
      // L'arc-en-ciel complet tient dans la zone centrale : les lanceurs Android
      // « zooment » l'icône adaptative et rognent les bords, donc on garde les 6
      // couleurs bien au milieu. Les coins sont couverts en prolongeant le rouge
      // (en haut) et le violet (en bas).
      final bandH = size.width * 0.66 / n;
      final start = -(n * bandH) / 2;
      const far = 2000.0;
      for (var i = 0; i < n; i++) {
        final top = i == 0 ? -far : start + i * bandH;
        final bottom = i == n - 1 ? far : start + (i + 1) * bandH;
        canvas.drawRect(
          Rect.fromLTRB(-far, top, far, bottom + 0.5),
          Paint()..color = stripes[i],
        );
      }
      canvas.restore();
    }

    if (dieScale <= 0) return;

    final die = size.width * dieScale;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = die * 0.20;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.16);

    final dieRect = Rect.fromCenter(
        center: Offset.zero, width: die, height: die);
    final rrect = RRect.fromRectAndRadius(dieRect, Radius.circular(radius));

    // Ombre portée douce.
    canvas.drawShadow(
        Path()..addRRect(rrect), Colors.black.withValues(alpha: 0.5),
        die * 0.06, false);

    // Corps du dé, léger dégradé blanc → gris très clair.
    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFE9ECF5)],
      ).createShader(dieRect);
    canvas.drawRRect(rrect, body);

    // Un seul pois noir, au centre : le « 1 », le dé le plus fort au 10 000.
    final pip = Paint()..color = const Color(0xFF161616);
    canvas.drawCircle(Offset.zero, die * 0.14, pip);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.background != background || old.dieScale != dieScale;
}
