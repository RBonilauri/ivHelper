import 'package:material_ui/material_ui.dart';

import 'core/moves.dart';
import 'core/species_repository.dart';
import 'settings/account_files.dart';
import 'settings/settings_controller.dart';
import 'overlay/overlay_services.dart';
import 'state/meta_controller.dart';
import 'state/update_controller.dart';
import 'ui/app_theme.dart';
import 'ui/home_screen.dart';

/// Application ivHelper : rang PvP des IV en ligue super et hyper.
class IvHelperApp extends StatelessWidget {
  /// Crée l'application à partir du [repository] d'espèces et des [settings].
  const IvHelperApp({
    super.key,
    required this.repository,
    required this.moves,
    required this.settings,
    required this.metaSource,
    required this.updateSource,
    required this.overlayLauncher,
    this.launchActions,
    this.accountFiles = const FilePickerAccountFiles(),
    this.currentBuild = 0,
    this.gameDataUpdated,
  });

  /// Fichiers de sauvegarde du compte.
  final AccountFiles accountFiles;

  /// Lancement de la pastille flottante.
  final OverlayLauncher overlayLauncher;

  /// Lancements rapides de la pastille (raccourci de l'icône, tuile des
  /// réglages rapides), ou `null`.
  final LaunchActions? launchActions;

  /// Source des mises à jour de l'app.
  final UpdateSource updateSource;

  /// Numéro de build de l'app installée (0 en compilation locale).
  final int currentBuild;

  /// Date des données du jeu en service (`AAAA-MM-JJ`), affichée dans le
  /// menu.
  final String? gameDataUpdated;

  /// Source de la méta PvPoke.
  final MetaSource metaSource;

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Attaques connues.
  final MoveBook moves;

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
        home: HomeScreen(
          repository: repository,
          moves: moves,
          settings: settings,
          metaSource: metaSource,
          updateSource: updateSource,
          overlayLauncher: overlayLauncher,
          launchActions: launchActions,
          accountFiles: accountFiles,
          currentBuild: currentBuild,
          gameDataUpdated: gameDataUpdated,
        ),
      ),
    );
  }
}
