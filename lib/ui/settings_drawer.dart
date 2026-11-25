import 'package:material_ui/material_ui.dart';

import '../settings/settings_controller.dart';
import '../state/update_controller.dart';
import 'iv_logo.dart';

/// Barre latérale des réglages : mode d'affichage et taille de police.
class SettingsDrawer extends StatelessWidget {
  /// Crée la barre latérale pour [settings].
  const SettingsDrawer({
    super.key,
    required this.settings,
    required this.onOpenTeam,
    required this.onOpenTypes,
    required this.onOpenMeta,
    required this.onOpenCollection,
    required this.update,
    required this.onStartOverlay,
    required this.onOpenSearch,
    required this.onExportAccount,
    required this.onImportAccount,
  });

  /// Lance la pastille flottante.
  final VoidCallback onStartOverlay;

  /// Ouvre les chaînes de recherche Pokémon GO.
  final VoidCallback onOpenSearch;

  /// Exporte le compte dans un fichier.
  final VoidCallback onExportAccount;

  /// Importe un compte depuis un fichier.
  final VoidCallback onImportAccount;

  /// Mise à jour de l'app.
  final UpdateController update;

  /// Ouvre la collection.
  final VoidCallback onOpenCollection;

  /// Ouvre l'onglet Méta.
  final VoidCallback onOpenMeta;

  /// Réglages modifiés par la barre latérale.
  final SettingsController settings;

  /// Ouvre le team builder.
  final VoidCallback onOpenTeam;

  /// Ouvre la table des types.
  final VoidCallback onOpenTypes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  const IvLogo(size: 40),
                  const SizedBox(width: 12),
                  Text('ivHelper', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.collections_bookmark),
                title: const Text('Ma collection'),
                subtitle: const Text('Tes Pokémon enregistrés, filtres et tri'),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenCollection();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.emoji_events),
                title: const Text('Méta'),
                subtitle: const Text('Top PvPoke en Super, Hyper et Master'),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenMeta();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups),
                title: const Text('Team builder'),
                subtitle: const Text('3 Pokémon, attaques, forces et faiblesses'),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenTeam();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.grid_view),
                title: const Text('Table des types'),
                subtitle: const Text('Forces et faiblesses des 18 types'),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenTypes();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_search),
                title: const Text('Chaînes de recherche'),
                subtitle: const Text(
                  'Texte à coller dans Pokémon GO pour trouver tes candidats',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenSearch();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_in_picture_alt),
                title: const Text('Superposition'),
                subtitle: const Text(
                  'Pastille par-dessus Pokémon GO : lit l\'écran et donne le rang',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onStartOverlay();
                },
              ),
              const Divider(height: 32),
              Text('Paramètres', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Text('Mode d\'affichage', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('Auto'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Jour'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Nuit'),
                  ),
                ],
                selected: <ThemeMode>{settings.themeMode},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
              const SizedBox(height: 24),
              Text(
                'Taille de police · ${(settings.fontScale * 100).round()} %',
                style: theme.textTheme.titleSmall,
              ),
              Slider(
                min: SettingsController.minFontScale,
                max: SettingsController.maxFontScale,
                divisions: 11,
                label: '${(settings.fontScale * 100).round()} %',
                value: settings.fontScale,
                onChanged: settings.setFontScale,
              ),
              TextButton(
                onPressed: () => settings.setFontScale(1),
                child: const Text('Taille normale'),
              ),
              const Divider(height: 32),
              Text('Compte', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Sauvegarde ta collection, ton équipe et tes réglages dans un '
                'fichier, pour les retrouver sur un autre téléphone.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onExportAccount();
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Exporter mon compte'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onImportAccount();
                },
                icon: const Icon(Icons.download),
                label: const Text('Importer un compte'),
              ),
              const Divider(height: 32),
              ListenableBuilder(
                listenable: update,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Version ${update.currentVersion}',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (update.message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          update.message!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (update.available != null)
                      FilledButton.icon(
                        onPressed: update.downloading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                update.install();
                              },
                        icon: const Icon(Icons.system_update),
                        label: Text(
                          'Installer la version '
                          '${update.available!.versionName}',
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: update.checking ? null : update.check,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          update.checking
                              ? 'Vérification…'
                              : 'Vérifier les mises à jour',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
