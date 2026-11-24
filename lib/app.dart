import 'package:material_ui/material_ui.dart';

import 'core/species_repository.dart';
import 'settings/settings_controller.dart';
import 'ui/app_theme.dart';
import 'ui/home_screen.dart';

/// Application ivHelper : rang PvP des IV en ligue super et hyper.
class IvHelperApp extends StatelessWidget {
  /// Crée l'application à partir du [repository] d'espèces et des [settings].
  const IvHelperApp({
    super.key,
    required this.repository,
    required this.settings,
  });

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Réglages d'affichage.
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'ivHelper',
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: settings.themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: child!,
        ),
        home: HomeScreen(repository: repository, settings: settings),
      ),
    );
  }
}
