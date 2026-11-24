import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/species_repository.dart';
import 'settings/prefs_store.dart';
import 'settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SpeciesRepository.load();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(PrefsSettingsStore(prefs));
  await settings.load();
  runApp(IvHelperApp(repository: repository, settings: settings));
}
