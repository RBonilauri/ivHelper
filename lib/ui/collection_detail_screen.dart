import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/moves.dart';
import '../state/collection_controller.dart';
import 'collection_widgets.dart';
import 'format.dart';
import 'move_label.dart';
import 'save_pokemon_sheet.dart';
import 'type_badge.dart';

/// Fiche d'un Pokémon de la collection : infos, modifier, voir le rang,
/// supprimer.
class CollectionDetailScreen extends StatelessWidget {
  /// Crée la fiche de l'entrée [entryId].
  const CollectionDetailScreen({
    super.key,
    required this.collection,
    required this.entryId,
    required this.onOpen,
    this.metaMoves,
  });

  /// Attaques recommandées par la méta (menu de modification).
  final MetaMovesFor? metaMoves;

  /// État de la collection.
  final CollectionController collection;

  /// Identifiant de l'entrée affichée.
  final String entryId;

  /// Ouvre l'entrée dans l'écran de rang.
  final void Function(BuildContext context, CollectionEntry entry) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: collection,
      builder: (context, _) {
        final row = collection.rowOf(entryId);
        if (row == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pokémon retiré de la collection')),
          );
        }
        return _Detail(
          row: row,
          metaIds: metaMoves
                  ?.call(row.species, row.entry.league, row.entry.shadow)
                  .toSet() ??
              const <String>{},
          onEdit: () => _edit(context, row),
          onOpen: () => onOpen(context, row.entry),
          onDelete: () => _delete(context, row.entry),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, CollectionRow row) {
    final e = row.entry;
    return showSaveSheet(
      context,
      SavePokemonSheet(
        species: row.species,
        iv: e.iv,
        moves: collection.moves,
        initialLeague: e.league,
        initial: e,
        saveLabel: 'Mettre à jour',
        metaMoves: metaMoves,
        rankFor: (league) =>
            collection.rankFor(row.species, e.iv, e.maxLevel, league),
        onSave: (options) => collection.update(e.id, options),
      ),
    );
  }

  Future<void> _delete(BuildContext context, CollectionEntry entry) async {
    if (!await confirmDelete(context, entry)) return;
    collection.remove(entry.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.row,
    required this.metaIds,
    required this.onEdit,
    required this.onOpen,
    required this.onDelete,
  });

  final CollectionRow row;

  /// Attaques de la méta pour cette espèce, cette ligue et cet état obscur.
  final Set<String> metaIds;
  final VoidCallback onEdit;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = row.entry;
    final iv = e.iv;
    return Scaffold(
      appBar: AppBar(
        title: Text(row.species.nameFr),
        actions: <Widget>[
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              margin: EdgeInsets.zero,
              color: tileColor(context, row),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: tileBorder(context, row),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        for (final t in row.species.types)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: TypeBadge(t, size: 40),
                          ),
                        const Spacer(),
                        if (e.isRankOne) const RankOneBadge(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${e.league.label} · rang ${formatGrouped(e.rank)}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      '${formatPercent(e.percent)} · PC ${formatGrouped(e.cp)}'
                      ' · niveau ${formatLevel(e.level)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'IV ${iv.atk}/${iv.def}/${iv.sta} · n° ${row.species.dex}'
                      ' · niveau max ${formatLevel(e.maxLevel)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    EntryAttributes(e, withLabels: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rang figé au moment de l\'enregistrement.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text('Attaques', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            if (row.recordedMoves.isEmpty)
              Text('Aucune attaque enregistrée.', style: theme.textTheme.bodySmall)
            else ...<Widget>[
              for (final group in <(String, List<Move>)>[
                ('Immédiate', <Move>[
                  for (final m in row.recordedMoves)
                    if (m.isFast) m,
                ]),
                ('Chargée(s)', <Move>[
                  for (final m in row.recordedMoves)
                    if (!m.isFast) m,
                ]),
              ])
                if (group.$2.isNotEmpty) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      group.$1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final m in group.$2)
                    _MoveLine(
                      move: m,
                      label: moveLabel(m, row.species),
                      isMeta: metaIds.contains(m.id),
                    ),
                ],
            ],
            if (row.recordedMoves.any((m) => row.species.isElite(m.id)))
              Text(eliteLegend, style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.leaderboard),
              label: const Text('Voir le rang'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une attaque de la fiche : type, nom (en gras si méta) et puissance.
class _MoveLine extends StatelessWidget {
  const _MoveLine({
    required this.move,
    required this.label,
    required this.isMeta,
  });

  final Move move;
  final String label;
  final bool isMeta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          TypeBadge(move.type, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isMeta ? FontWeight.w800 : null,
              ),
            ),
          ),
          Text(
            '${move.power}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
