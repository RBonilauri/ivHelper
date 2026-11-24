import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../state/update_controller.dart';

/// Bannière « nouvelle version disponible » en haut de l'écran de rang.
class UpdateBanner extends StatelessWidget {
  /// Crée la bannière pour [update].
  const UpdateBanner({super.key, required this.update});

  /// État de la mise à jour.
  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final release = update.available;
    if (release == null) return const SizedBox.shrink();
    final failed = update.message?.startsWith('Le téléchargement') ?? false;
    return Card(
      key: const ValueKey<String>('update-banner'),
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.system_update,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nouvelle version ${release.versionName} disponible',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (update.downloading)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 6, 4),
                child: LinearProgressIndicator(
                  value: update.progress > 0 ? update.progress : null,
                ),
              ),
            if (update.message != null && !update.downloading)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  update.message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                spacing: 4,
                children: <Widget>[
                  TextButton(
                    onPressed: update.downloading ? null : update.dismiss,
                    child: const Text('Plus tard'),
                  ),
                  if (failed)
                    TextButton(
                      onPressed: () => unawaited(update.openInBrowser()),
                      child: const Text('Via le navigateur'),
                    ),
                  FilledButton(
                    onPressed: update.downloading
                        ? null
                        : () => unawaited(update.install()),
                    child: Text(
                      update.downloading ? 'Téléchargement…' : 'Mettre à jour',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
