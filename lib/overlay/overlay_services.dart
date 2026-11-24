import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
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
    final text = parseScreenText(ocrLinesOf(shot));
    return identify(repository, text, readAppraisal(image, text));
  }

  /// Décode la capture PNG en pixels RGBA pour lire les barres.
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

/// Lignes lues par ML Kit (côté Android, sur le Bitmap de la capture).
List<OcrLine> ocrLinesOf(CapturedScreen shot) => <OcrLine>[
      for (final l in shot.lines)
        OcrLine(
          l.text,
          l.left.toDouble(),
          l.top.toDouble(),
          l.right.toDouble(),
          l.bottom.toDouble(),
        ),
    ];

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
