import 'package:material_ui/material_ui.dart';

import '../core/meta.dart';
import '../state/meta_controller.dart';
import 'info_button.dart';

/// Explication de la carte des coupes, dans la bulle « i ».
const String cupsExplanation =
    'Coupes mises en avant par PvPoke, mises à jour chaque jour avec la méta. '
    'Seules celles où ce Pokémon est admis sont listées. Le rang de ses IV '
    'est celui de la ligue de même limite de PC ; le numéro est sa place '
    'dans la méta de la coupe.';

/// Carte « Coupes en cours » de l'écran de rang : coupes qui acceptent
/// [speciesName] et sa place dans leur méta. Rien si la méta n'a pas de
/// coupe.
class CupsCard extends StatelessWidget {
  /// Crée la carte.
  const CupsCard({super.key, required this.meta, required this.speciesName});

  /// Méta PvPoke.
  final MetaController meta;

  /// Espèce affichée.
  final String speciesName;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meta,
      builder: (context, _) {
        final data = meta.data;
        if (data == null || data.cups.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final standings = cupStandings(data, speciesName);
        return Card(
          key: const ValueKey<String>('cups-card'),
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.emoji_events_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coupes en cours',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const InfoButton(
                      cupsExplanation,
                      key: ValueKey<String>('info-cups'),
                    ),
                  ],
                ),
                if (standings.isEmpty)
                  Text(
                    'Admis dans aucune coupe en cours.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  for (final s in standings)
                    Padding(
                      key: ValueKey<String>('cup-${s.cup.key}'),
                      padding: const EdgeInsetsDirectional.only(
                        top: 4,
                        end: 6,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${s.cup.label} · ${s.cup.league.label}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cupStandingLabel(s),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
