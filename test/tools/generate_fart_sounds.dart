import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Synthétise les prouts du « bon dernier » (mode trash) puis les enregistre
/// dans `assets/sounds/`. Fabriqués en code plutôt que téléchargés : aucun
/// souci de droits, et on peut les retoucher ici. À lancer avec :
///   flutter test test/tools/generate_fart_sounds.dart
///
/// Principe : un train d'impulsions grave (la « vibration »), dont la hauteur
/// tremble et glisse, plus un souffle de bruit (le côté « mouillé »), le tout
/// étouffé par un filtre passe-bas et enveloppé court — bref et concis.
void main() {
  test('génère les prouts', () {
    final dir = Directory('assets/sounds')..createSync(recursive: true);
    for (var i = 0; i < _variants.length; i++) {
      final samples = _synth(_variants[i], Random(1000 + i));
      File('${dir.path}/prout_${i + 1}.wav').writeAsBytesSync(_wav(samples));
    }
  });
}

const int _rate = 22050;

class _Fart {
  const _Fart({
    required this.seconds,
    required this.pitch,
    this.slide = 0,
    this.wobble = 0.08,
    this.wetness = 0.25,
    this.sputter = 0,
    this.brightness = 900,
  });

  /// Durée totale.
  final double seconds;

  /// Hauteur de départ (Hz) de la vibration.
  final double pitch;

  /// Glissement de hauteur sur la durée (-0.4 = descend de 40 %).
  final double slide;

  /// Tremblement de la hauteur (proportion).
  final double wobble;

  /// Part de souffle bruité (0 = sec, 1 = très mouillé).
  final double wetness;

  /// Nombre de hoquets (coupures) — 0 pour un prout continu.
  final int sputter;

  /// Fréquence de coupure du passe-bas (Hz) : plus bas = plus étouffé.
  final double brightness;
}

const _variants = <_Fart>[
  _Fart(seconds: 0.16, pitch: 105, slide: -0.15), // le bref
  _Fart(seconds: 0.30, pitch: 68, slide: -0.25, brightness: 650), // le grave
  _Fart(seconds: 0.24, pitch: 190, slide: 0.30, wobble: 0.12), // le couinant
  _Fart(seconds: 0.28, pitch: 90, wetness: 0.65, brightness: 1100), // mouillé
  _Fart(seconds: 0.36, pitch: 85, sputter: 3, wobble: 0.15), // la pétarade
  _Fart(seconds: 0.40, pitch: 150, slide: -0.5, wobble: 0.1), // le dégonflé
];

List<double> _synth(_Fart f, Random rnd) {
  final n = (f.seconds * _rate).round();
  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  var jitter = 0.0; // marche aléatoire : la hauteur ne tient jamais en place
  var ampWalk = 1.0;
  var lp = 0.0;
  var noiseLp = 0.0;
  final alpha = 1 - exp(-2 * pi * f.brightness / _rate);
  final noiseAlpha = 1 - exp(-2 * pi * 500 / _rate);

  for (var i = 0; i < n; i++) {
    final t = i / n; // 0 → 1
    jitter = (jitter + (rnd.nextDouble() - 0.5) * 0.02).clamp(-0.2, 0.2);
    ampWalk = (ampWalk + (rnd.nextDouble() - 0.5) * 0.02).clamp(0.6, 1.0);
    final freq = f.pitch *
        (1 + f.slide * t) *
        (1 + f.wobble * sin(2 * pi * 23 * t * f.seconds) + jitter);
    phase += freq / _rate;
    phase -= phase.floorToDouble();

    // Impulsion qui claque puis retombe : le « brrr » des lèvres… ou presque.
    final buzz = exp(-phase * 7) * 2 - 0.55;
    noiseLp += noiseAlpha * ((rnd.nextDouble() * 2 - 1) - noiseLp);
    // Le souffle bat au rythme de la vibration, comme de l'air qui s'échappe.
    final breath = noiseLp * 3 * (0.4 + 0.6 * exp(-phase * 3));
    final raw = buzz * (1 - f.wetness) + breath * f.wetness;

    lp += alpha * (raw - lp);

    // Enveloppe : attaque franche, tenue irrégulière, chute rapide.
    final attack = min(1.0, i / (_rate * 0.012));
    final release = min(1.0, (n - i) / (_rate * 0.05));
    var gate = 1.0;
    if (f.sputter > 0) {
      // Hoquets : quelques trous nets répartis sur la durée.
      final s = (t * (f.sputter + 1)) % 1;
      gate = s < 0.78 ? 1.0 : 0.08;
    }
    out[i] = lp * attack * release * ampWalk * gate;
  }

  // Normalise à -2 dB environ.
  final peak = out.fold<double>(0, (m, v) => max(m, v.abs()));
  return [for (final v in out) v / peak * 0.8];
}

Uint8List _wav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // taille du bloc fmt
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _rate, Endian.little);
  data.setUint32(28, _rate * 2, Endian.little); // octets par seconde
  data.setUint16(32, 2, Endian.little); // octets par échantillon
  data.setUint16(34, 16, Endian.little); // bits
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, (samples[i] * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}
