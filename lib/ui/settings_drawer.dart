import 'package:material_ui/material_ui.dart';

import '../settings/settings_controller.dart';
import 'iv_logo.dart';

/// Barre latérale des réglages : mode d'affichage et taille de police.
class SettingsDrawer extends StatelessWidget {
  /// Crée la barre latérale pour [settings].
  const SettingsDrawer({super.key, required this.settings});

  /// Réglages modifiés par la barre latérale.
  final SettingsController settings;

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
                  Text('Paramètres', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 24),
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
            ],
          ),
        ),
      ),
    );
  }
}
