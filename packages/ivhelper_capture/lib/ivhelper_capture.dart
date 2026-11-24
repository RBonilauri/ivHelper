import 'package:flutter/services.dart';

/// Ligne de texte lue par ML Kit, avec son cadre en pixels de la capture.
class RecognizedLine {
  /// Crée une ligne.
  const RecognizedLine(this.text, this.left, this.top, this.right, this.bottom);

  /// Texte lu.
  final String text;

  /// Bord gauche.
  final int left;

  /// Bord haut.
  final int top;

  /// Bord droit.
  final int right;

  /// Bord bas.
  final int bottom;
}

/// Image de l'écran enregistrée dans un fichier PNG, et son texte.
class CapturedScreen {
  /// Crée une capture.
  const CapturedScreen({
    required this.path,
    required this.width,
    required this.height,
    this.lines = const <RecognizedLine>[],
  });

  /// Lit la réponse du canal natif.
  factory CapturedScreen.fromMap(Map<Object?, Object?> map) {
    final raw = map['lines'];
    return CapturedScreen(
      path: map['path']! as String,
      width: (map['width']! as num).toInt(),
      height: (map['height']! as num).toInt(),
      lines: <RecognizedLine>[
        if (raw is List)
          for (final item in raw.whereType<Map<Object?, Object?>>())
            RecognizedLine(
              item['text']! as String,
              (item['left']! as num).toInt(),
              (item['top']! as num).toInt(),
              (item['right']! as num).toInt(),
              (item['bottom']! as num).toInt(),
            ),
      ],
    );
  }

  /// Chemin du fichier PNG.
  final String path;

  /// Largeur en pixels.
  final int width;

  /// Hauteur en pixels.
  final int height;

  /// Lignes de texte lues sur l'écran.
  final List<RecognizedLine> lines;
}

/// Capture de l'écran par MediaProjection (Android).
class IvhelperCapture {
  IvhelperCapture._();

  static const MethodChannel _channel = MethodChannel('ivhelper/capture');

  /// Vrai si une session de capture est ouverte.
  static Future<bool> isActive() async =>
      await _channel.invokeMethod<bool>('isActive') ?? false;

  /// Demande l'autorisation de capturer l'écran et ouvre la session ;
  /// renvoie faux si l'utilisateur refuse.
  static Future<bool> requestCapture() async =>
      await _channel.invokeMethod<bool>('requestCapture') ?? false;

  /// Enregistre l'image actuelle de l'écran et lit son texte.
  static Future<CapturedScreen> capture() async {
    final map = await _channel.invokeMethod<Map<Object?, Object?>>('capture');
    if (map == null) throw PlatformException(code: 'NO_IMAGE');
    return CapturedScreen.fromMap(map);
  }

  /// Ferme la session de capture et la pastille.
  static Future<void> stop() => _channel.invokeMethod<void>('stop');
}
