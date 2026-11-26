import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/meta.dart';
import '../core/moves.dart';
import '../state/collection_controller.dart';
import 'collection_widgets.dart';
import 'format.dart';
import 'meta_screen.dart';
import 'move_label.dart';
import 'move_line.dart';
import 'save_pokemon_sheet.dart';
import 'type_badge.dart';
import 'info_button.dart';

/// Lien d'un Pokémon de la collection vers sa fiche méta.
class CollectionMetaLink {
  /// Crée le lien.
  const CollectionMetaLink({required this.entryFor, required this.actions});

  /// Entrée méta de [entry] dans [league] (même espèce, forme obscure si
  /// possible), ou `null` si l'espèce n'y est pas classée.
  final MetaEntry? Function(CollectionEntry entry, MetaLeague league) entryFor;

  /// Actions de la fiche méta.
  final MetaActions actions;

  /// Rang de [entry] dans la méta de la ligue de son tag, ou `null` (ligue
  /// mini, méta pas encore chargée, ou espèce non classée).
  int? metaRankOf(CollectionEntry entry) {
    final league = MetaLeague.fromKey(entry.league.key);
    return league == null ? null : entryFor(entry, league)?.rank;
  }
}

/// Fiche d'un Pokémon de la collection : infos, modifier, voir le rang,
/// voir la fiche méta, supprimer.
class CollectionDetailScreen extends StatelessWidget {
  /// Crée la fiche de l'entrée [entryId].
  const CollectionDetailScreen({
    super.key,
    required this.collection,
    required this.entryId,
    required this.onOpen,
    this.metaMoves,
    this.metaLink,
  });

  /// Attaques recommandées par la méta (menu de modification).
  final MetaMovesFor? metaMoves;

  /// Lien vers la fiche méta de la ligue du Pokémon.
  final CollectionMetaLink? metaLink;

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
          onFavorite: () => collection.toggleFavorite(row.entry.id),
          meta: _metaButton(context, row.entry),
          metaRank: _metaRank(row.entry),
        );
      },
    );
  }

  /// Bouton vers la fiche méta de la ligue du tag ; désactivé en ligue mini
  /// (pas de méta) ou si l'espèce n'est pas classée dans cette ligue.
  Widget? _metaButton(BuildContext context, CollectionEntry entry) {
    final link = metaLink;
    if (link == null) return null;
    final league = MetaLeague.fromKey(entry.league.key);
    final metaEntry = league == null ? null : link.entryFor(entry, league);
    final label = league == null
        ? 'Pas de méta en ligue ${entry.league.label}'
        : metaEntry == null
            ? 'Absent de la méta ${league.label}'
            : 'Voir la fiche méta (${league.label})';
    return OutlinedButton.icon(
      onPressed: league == null || metaEntry == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MetaDetailScreen(
                    entry: metaEntry,
                    league: league,
                    actions: link.actions,
                  ),
                ),
              ),
      icon: const Icon(Icons.insights),
      label: Text(label),
    );
  }

  /// Rang méta à mettre en évidence : (texte, classé ?) ; `null` sans lien.
  (String, bool)? _metaRank(CollectionEntry entry) {
    final link = metaLink;
    if (link == null) return null;
    final league = MetaLeague.fromKey(entry.league.key);
    if (league == null) return ('Pas de méta en ligue ${entry.league.label}', false);
    final rank = link.metaRankOf(entry);
    return rank == null
        ? ('Absent de la méta ${league.label}', false)
        : ('Méta ${league.label} · n° $rank', true);
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
    required this.onFavorite,
    this.meta,
    this.metaRank,
  });

  final CollectionRow row;

  /// Attaques de la méta pour cette espèce, cette ligue et cet état obscur.
  final Set<String> metaIds;
  final VoidCallback onEdit;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  /// Rang méta à mettre en évidence (texte, classé ?), ou `null`.
  final (String, bool)? metaRank;

  /// Bouton vers la fiche méta, ou `null`.
  final Widget? meta;

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
            tooltip: e.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            icon: Icon(
              e.favorite ? Icons.favorite : Icons.favorite_border,
              color: e.favorite ? favoriteRed : null,
            ),
            onPressed: onFavorite,
          ),
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
                        if (e.favorite) ...<Widget>[
                          const SizedBox(width: 8),
                          const FavoriteHeart(size: 30),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            '${e.league.label} · rang ${formatGrouped(e.rank)}',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        const InfoButton(
                          'Rang figé au moment de l\'enregistrement.',
                          key: ValueKey<String>('info-frozen-rank'),
                        ),
                      ],
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
                    if (metaRank != null) ...<Widget>[
                      const SizedBox(height: 10),
                      _MetaRankBanner(text: metaRank!.$1, ranked: metaRank!.$2),
                    ],
                    const SizedBox(height: 8),
                    EntryAttributes(e, withLabels: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text('Attaques', style: theme.textTheme.titleSmall),
                if (row.recordedMoves.any((m) => row.species.isElite(m.id)))
                  const InfoButton(
                    eliteLegend,
                    key: ValueKey<String>('info-elite'),
                  ),
              ],
            ),
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
                    MoveLine(
                      move: m,
                      label: moveLabel(m, row.species),
                      bold: metaIds.contains(m.id),
                    ),
                ],
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.leaderboard),
              label: const Text('Voir le rang'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onFavorite,
              icon: Icon(
                e.favorite ? Icons.favorite : Icons.favorite_border,
                color: favoriteRed,
              ),
              label: Text(
                e.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Modifier'),
            ),
            if (meta != null) ...<Widget>[
              const SizedBox(height: 8),
              meta!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Bandeau du rang dans la méta de la ligue du tag, bien visible.
class _MetaRankBanner extends StatelessWidget {
  const _MetaRankBanner({required this.text, required this.ranked});

  final String text;
  final bool ranked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ranked ? scheme.primaryContainer : scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.insights,
            size: 22,
            color: ranked ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: (ranked ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
                  ?.copyWith(
                fontWeight: ranked ? FontWeight.w800 : null,
                color: ranked ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
