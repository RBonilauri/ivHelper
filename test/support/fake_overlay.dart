import 'package:ivhelper/core/screen_reading.dart';
import 'package:ivhelper/overlay/overlay_services.dart';

/// Lanceur de pastille sans Android.
class FakeOverlayLauncher implements OverlayLauncher {
  /// Crée le lanceur ; [error] simule un refus.
  FakeOverlayLauncher({this.error});

  /// Message d'erreur renvoyé, ou `null`.
  final String? error;

  /// Nombre de lancements.
  int starts = 0;

  @override
  Future<String?> start() async {
    starts++;
    return error;
  }
}

/// Fenêtre flottante qui note les appels.
class FakeOverlayWindow implements OverlayWindow {
  /// Appels reçus, dans l'ordre.
  final List<String> calls = <String>[];

  @override
  Future<void> setVisible({required bool visible}) async =>
      calls.add(visible ? 'show' : 'hide');

  @override
  Future<void> showBubble() async => calls.add('bubble');

  @override
  Future<void> showPanel() async => calls.add('panel');

  @override
  Future<void> stopAll() async => calls.add('stop');

  /// Textes copiés.
  final List<String> copied = <String>[];

  @override
  Future<bool> copyText(String text) async {
    copied.add(text);
    return true;
  }
}

/// Lecteur d'écran qui renvoie un résultat préparé.
class FakeScreenScanner implements ScreenScanner {
  /// Crée le lecteur.
  FakeScreenScanner(this.result);

  /// Résultat renvoyé.
  ScanResult result;

  @override
  Future<ScanResult> scan() async => result;
}

/// Lancements rapides simulés (raccourci de l'icône, tuile).
class FakeLaunchActions implements LaunchActions {
  /// Crée la source ; [pending] simule une appli ouverte par un raccourci.
  FakeLaunchActions({this.pending = false});

  /// Vrai si une demande attend l'écoute.
  bool pending;

  void Function()? _onBubble;

  /// Nombre de retours à l'appli précédente.
  int leaves = 0;

  @override
  void listen(void Function() onBubble) {
    _onBubble = onBubble;
    if (pending) {
      pending = false;
      onBubble();
    }
  }

  /// Simule un appui sur le raccourci ou la tuile, appli ouverte.
  void fire() => _onBubble?.call();

  @override
  Future<void> leaveApp() async => leaves++;
}
