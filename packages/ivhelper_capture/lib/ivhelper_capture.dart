import 'package:flutter/services.dart';

/// Image de l'écran enregistrée dans un fichier PNG.
class CapturedScreen {
  /// Crée une capture.
  const CapturedScreen({
    required this.path,
    required this.width,
    required this.height,
  });

  /// Chemin du fichier PNG.
  final String path;

  /// Largeur en pixels.
  final int width;

  /// Hauteur en pixels.
  final int height;
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

  /// Enregistre l'image actuelle de l'écran.
  static Future<CapturedScreen> capture() async {
    final map = await _channel.invokeMapMethod<String, Object?>('capture');
    if (map == null) throw PlatformException(code: 'NO_IMAGE');
    return CapturedScreen(
      path: map['path']! as String,
      width: map['width']! as int,
      height: map['height']! as int,
    );
  }

  /// Ferme la session de capture et la pastille.
  static Future<void> stop() => _channel.invokeMethod<void>('stop');
}
