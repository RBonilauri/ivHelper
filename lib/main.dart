import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_update.dart';
import 'core/meta.dart';
import 'core/moves.dart';
import 'core/species_repository.dart';
import 'overlay/overlay_app.dart';
import 'overlay/overlay_services.dart';
import 'settings/prefs_store.dart';
import 'settings/settings_controller.dart';
import 'state/github_update_source.dart';
import 'state/http_meta_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SpeciesRepository.load();
  final moves = await MoveBook.load();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(PrefsSettingsStore(prefs));
  await settings.load();
  runApp(
    IvHelperApp(
      repository: repository,
      moves: moves,
      settings: settings,
      metaSource: const HttpMetaSource(),
      updateSource: const GitHubUpdateSource(),
      overlayLauncher: const PluginOverlayLauncher(),
      currentBuild: currentBuildNumber,
    ),
  );
}

/// Point d'entrée de la pastille flottante (plugin flutter_overlay_window).
@pragma('vm:entry-point')
Future<void> overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SpeciesRepository.load();
  final moves = await MoveBook.load();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(PrefsSettingsStore(prefs));
  await settings.load();
  MetaSnapshot? meta;
  final cached = await settings.store.readMeta();
  for (final source in <String?>[
    cached,
    await const HttpMetaSource().bundled(),
  ]) {
    if (source == null) continue;
    try {
      final candidate = MetaSnapshot.fromJson(source);
      if (meta == null || candidate.isNewerThan(meta)) meta = candidate;
    } on FormatException {
      continue;
    }
  }
  const window = PluginOverlayWindow();
  runApp(
    OverlayApp(
      repository: repository,
      moves: moves,
      settings: settings,
      scanner: DeviceScreenScanner(repository, window),
      window: window,
      meta: meta,
    ),
  );
}
