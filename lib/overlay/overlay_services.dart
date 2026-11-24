import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ivhelper_capture/ivhelper_capture.dart';

import '../core/screen_reading.dart';
import '../core/species_repository.dart';

/// Lit l'écran du jeu et reconnaît le Pokémon affiché.
abstract interface class ScreenScanner {
  /// Capture l'écran, lit le texte et les barres, et reconnaît le Pokémon.
  Future<ScanResult> scan();
}

/// Taille et comportement de la fenêtre flottante.
abstract interface class OverlayWindow {
  /// Réduit la fenêtre à la pastille.
  Future<void> showBubble();

  /// Agrandit la fenêtre en panneau de résultats.
  Future<void> showPanel();

  /// Masque ou réaffiche la fenêtre (pendant la capture).
  Future<void> setVisible({required bool visible});

  /// Ferme la pastille et la capture.
  Future<void> stopAll();
}

/// Lecture réelle : MediaProjection, ML Kit et analyse des barres.
class DeviceScreenScanner implements ScreenScanner {
  /// Crée le lecteur pour les espèces de [repository].
  DeviceScreenScanner(this.repository, this.window);

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Fenêtre à masquer pendant la capture.
  final OverlayWindow window;

  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<ScanResult> scan() async {
    await window.setVisible(visible: false);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final CapturedScreen shot;
    try {
      shot = await IvhelperCapture.capture();
    } finally {
      await window.setVisible(visible: true);
    }
    final image = await _decode(shot.path);
    final recognized = await _recognizer.processImage(ocrInputFor(image));
    final lines = <OcrLine>[
      for (final block in recognized.blocks)
        for (final line in block.lines)
          OcrLine(
            line.text,
            line.boundingBox.left,
            line.boundingBox.top,
            line.boundingBox.right,
            line.boundingBox.bottom,
          ),
    ];
    final text = parseScreenText(lines);
    return identify(repository, text, readAppraisal(image, text));
  }

  /// Décode la capture PNG en pixels RGBA (une seule fois, pour l'OCR et
  /// les barres).
  static Future<RgbaImage> _decode(String path) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty) {
      throw StateError("La capture de l'écran est vide.");
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data =
        await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) {
      throw StateError("La capture de l'écran est illisible.");
    }
    return RgbaImage(
      frame.image.width,
      frame.image.height,
      data.buffer.asUint8List(),
    );
  }
}

/// Image à lire par ML Kit : les pixels déjà décodés, et non le fichier PNG
/// (ML Kit décode mal le fichier sur certains téléphones : `NullPointerException`).
InputImage ocrInputFor(RgbaImage image) => InputImage.fromBitmap(
      bitmap: image.bytes,
      width: image.width,
      height: image.height,
    );

/// Message court d'un échec de lecture, sans la pile Java des erreurs natives.
String describeScanError(Object error) {
  final detail = switch (error) {
    PlatformException(:final message?) => message,
    StateError(:final message) => message,
    _ => '$error',
  };
  return 'Lecture impossible : ${detail.split('\n').first.trim()}';
}

/// Fenêtre réelle du plugin flutter_overlay_window.
class PluginOverlayWindow implements OverlayWindow {
  /// Crée la fenêtre.
  const PluginOverlayWindow();

  /// Côté de la pastille, en dp.
  static const int bubbleSize = 64;

  @override
  Future<void> showBubble() async {
    await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    await FlutterOverlayWindow.resizeOverlay(bubbleSize, bubbleSize, true);
  }

  @override
  Future<void> showPanel() async {
    final screen = await FlutterOverlayWindow.getScreenSize();
    final height = (screen.y * 0.82).round();
    await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    await FlutterOverlayWindow.resizeOverlay(
      WindowSize.matchParent,
      height,
      false,
    );
    await FlutterOverlayWindow.moveOverlay(
      OverlayPosition(0, screen.y - height - 24),
    );
  }

  @override
  Future<void> setVisible({required bool visible}) async {
    await FlutterOverlayWindow.setOverlayVisible(visible: visible);
  }

  @override
  Future<void> stopAll() async {
    await IvhelperCapture.stop();
    await FlutterOverlayWindow.closeOverlay();
  }
}

/// Lance la pastille depuis l'app.
abstract interface class OverlayLauncher {
  /// Demande les autorisations et affiche la pastille ; renvoie un message
  /// d'erreur, ou `null` si tout va bien.
  Future<String?> start();
}

/// Lancement réel : autorisation de superposition, capture, pastille.
class PluginOverlayLauncher implements OverlayLauncher {
  /// Crée le lanceur.
  const PluginOverlayLauncher();

  @override
  Future<String?> start() async {
    if (!Platform.isAndroid) {
      return 'La superposition n\'existe que sur Android.';
    }
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      final granted = await FlutterOverlayWindow.requestPermission();
      if (granted != true) {
        return 'Autorise ivHelper à s\'afficher par-dessus les autres '
            'applications, puis relance la superposition.';
      }
    }
    if (!await IvhelperCapture.requestCapture()) {
      return 'La capture d\'écran a été refusée.';
    }
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
    await FlutterOverlayWindow.showOverlay(
      height: PluginOverlayWindow.bubbleSize,
      width: PluginOverlayWindow.bubbleSize,
      alignment: OverlayAlignment.centerRight,
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      overlayTitle: 'ivHelper',
      overlayContent: 'Pastille active',
    );
    return null;
  }
}
