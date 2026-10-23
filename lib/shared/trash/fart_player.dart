import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

/// Joue un prout bref, tiré au hasard parmi les sons synthétisés
/// (`assets/sounds/prout_N.wav`, voir `test/tools/generate_fart_sounds.dart`)
/// — jamais deux fois le même d'affilée.
///
/// Quelques « voix » tournent à tour de rôle, pour que des taps rapides se
/// chevauchent au lieu de se couper. Le son se mélange à la musique en cours
/// (s'il y en a une autour de la table) plutôt que de la mettre en pause.
class FartPlayer {
  FartPlayer({Random? random}) : _random = random ?? Random();

  static const int variantCount = 6;
  static const int _voiceCount = 3;

  final Random _random;
  final List<AudioPlayer> _voices = [];
  int _nextVoice = 0;
  int? _lastVariant;

  Future<void> play() async {
    try {
      if (_voices.isEmpty) await _warmUp();
      var variant = _random.nextInt(variantCount);
      if (variant == _lastVariant) variant = (variant + 1) % variantCount;
      _lastVariant = variant;

      final voice = _voices[_nextVoice];
      _nextVoice = (_nextVoice + 1) % _voices.length;
      await voice.stop();
      await voice.play(AssetSource('sounds/prout_${variant + 1}.wav'));
    } catch (_) {
      // Pas de son possible (tests, lecteur indisponible) : la blague
      // tombe à plat, mais la saisie du score, elle, ne doit jamais planter.
    }
  }

  Future<void> _warmUp() async {
    final context =
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build();
    for (var i = 0; i < _voiceCount; i++) {
      final voice = AudioPlayer();
      _voices.add(voice);
      await voice.setPlayerMode(PlayerMode.lowLatency);
      await voice.setAudioContext(context);
    }
  }

  void dispose() {
    for (final voice in _voices) {
      voice.dispose();
    }
    _voices.clear();
  }
}
