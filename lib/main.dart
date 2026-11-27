import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_update.dart';
import 'core/meta.dart';
import 'overlay/overlay_app.dart';
import 'overlay/overlay_services.dart';
import 'settings/prefs_store.dart';
import 'settings/settings_controller.dart';
import 'state/game_data_controller.dart';
import 'state/github_update_source.dart';
import 'state/http_game_data_source.dart';
import 'state/http_meta_source.dart';
import 'ui/game_data_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(PrefsSettingsStore(prefs));
  await settings.load();
  final gameData = GameDataController(
    source: const HttpGameDataSource(),
    store: settings.store,
  );
  await gameData.load();
  runApp(
    GameDataHost(
      controller: gameData,
      builder: (data) => IvHelperApp(
        repository: data.species,
        moves: data.moves,
        settings: settings,
        metaSource: const HttpMetaSource(),
        updateSource: const GitHubUpdateSource(),
        overlayLauncher: const PluginOverlayLauncher(),
        launchActions: const PluginLaunchActions(),
        currentBuild: currentBuildNumber,
        gameDataUpdated: data.updated,
      ),
    ),
  );
}

/// Point d'entrée de la pastille flottante (plugin flutter_overlay_window).
@pragma('vm:entry-point')
Future<void> overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(PrefsSettingsStore(prefs));
  await settings.load();
  // Mêmes données du jeu que l'appli (copie incluse ou cache plus récent).
  final gameData = GameDataController(
    source: const HttpGameDataSource(),
    store: settings.store,
  );
  await gameData.load();
  final repository = gameData.current.species;
  final moves = gameData.current.moves;
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
