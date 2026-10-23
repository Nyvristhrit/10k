import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Icône de l'appli dans le lanceur du téléphone : classique, ou aux couleurs
/// néon quand le mode trash est actif (Android seulement — voir DECISIONS
/// A-014 et `TenkActivity.kt`).
///
/// On ne fait que **déclarer** l'icône voulue : Android ne l'applique qu'au
/// moment où l'on quitte l'appli, pour ne pas la fermer en pleine partie.
class AppIcon {
  const AppIcon._();

  static const MethodChannel _channel = MethodChannel('tenk/app_icon');

  static bool? _last;

  /// Demande l'icône qui correspond au mode trash [trash]. Sans effet si
  /// c'est déjà la dernière demandée, ou hors Android.
  static void sync({required bool trash}) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_last == trash) return;
    _last = trash;
    _channel.invokeMethod<void>('setTrashIcon', trash).catchError((_) {
      // Pas de canal natif (tests) : l'icône reste celle du moment.
      _last = null;
    });
  }
}
