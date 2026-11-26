import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/poke_type.dart';
import '../state/collection_controller.dart';
import 'collection_detail_screen.dart';
import 'collection_widgets.dart';
import 'format.dart';
import 'move_filter.dart';
import 'save_pokemon_sheet.dart';
import 'type_badge.dart';
import 'type_filter_row.dart';

/// Collection : Pokémon enregistrés, filtrables, triables, en liste ou en
/// mosaïque.
class CollectionScreen extends StatelessWidget {
  /// Crée l'écran.
  const CollectionScreen({
    super.key,
    required this.collection,
    required this.onOpen,
    this.metaMoves,
    this.metaLink,
  });

  /// Attaques recommandées par la méta (menu de modification).
  final MetaMovesFor? metaMoves;

  /// Lien vers la fiche méta depuis la fiche d'un Pokémon.
  final CollectionMetaLink? metaLink;

  /// État de la collection.
  final CollectionController collection;

  /// Ouvre une entrée dans l'écran de rang.
  final void Function(BuildContext context, CollectionEntry entry) onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma collection'),
        actions: <Widget>[
          ListenableBuilder(
            listenable: collection,
            builder: (context, _) => collection.view == CollectionView.list
                ? IconButton(
                    tooltip: 'Afficher en mosaïque',
                    icon: const Icon(Icons.grid_view),
                    onPressed: () => collection.setView(CollectionView.grid),
                  )
                : IconButton(
                    tooltip: 'Afficher en liste',
                    icon: const Icon(Icons.view_list),
                    onPressed: () => collection.setView(CollectionView.list),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: collection,
          builder: (context, _) {
            final metaRankOf = metaLink?.metaRankOf;
            final rows = collection.visibleRowsWith(metaRankOf);
            // Mosaïque : au moins 3 colonnes, une de plus par 140 dp de
            // largeur disponible (marges de 16 dp de chaque côté).
            final columns = ((MediaQuery.sizeOf(context).width - 32) ~/ 140)
                .clamp(3, 8);
            return CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: _Controls(collection: collection, shown: rows.length),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: collection.view == CollectionView.list
                      ? SliverList.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, i) => _ListTile(
                            row: rows[i],
                            metaRank: metaRankOf?.call(rows[i].entry),
                            onTap: () => _openDetail(context, rows[i]),
                            onDelete: () => _delete(context, rows[i].entry),
                          ),
                        )
                      // Mosaïque en lignes de [columns] cases : chaque ligne
                      // prend la hauteur de sa case la plus haute (pas de
                      // débordement avec un grand texte).
                      : SliverList.builder(
                          itemCount: (rows.length + columns - 1) ~/ columns,
                          itemBuilder: (context, line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  for (var c = 0; c < columns; c++) ...<Widget>[
                                    if (c > 0) const SizedBox(width: 6),
                                    Expanded(
                                      child: line * columns + c < rows.length
                                          ? _GridTile(
                                              row: rows[line * columns + c],
                                              metaRank: metaRankOf?.call(
                                                rows[line * columns + c].entry,
                                              ),
                                              onTap: () => _openDetail(
                                                context,
                                                rows[line * columns + c],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, CollectionRow row) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectionDetailScreen(
          collection: collection,
          entryId: row.entry.id,
          onOpen: onOpen,
          metaMoves: metaMoves,
          metaLink: metaLink,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, CollectionEntry entry) async {
    if (await confirmDelete(context, entry)) collection.remove(entry.id);
  }
}

/// Rangée « Tous / Top 1 / Top 10 / Top 50 » d'un filtre de rang.
class _RankChips extends StatelessWidget {
  const _RankChips({
    required this.title,
    required this.keyPrefix,
    required this.selected,
    required this.onSelected,
  });

  final String title;

  /// Préfixe des clés : `<keyPrefix>-all`, `<keyPrefix>-10`…
  final String keyPrefix;

  /// Seuil choisi, ou `null` pour tous.
  final int? selected;

  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final t in rankThresholds)
              ChoiceChip(
                key: ValueKey<String>('$keyPrefix-${t ?? 'all'}'),
                label: Text(t == null ? 'Tous' : 'Top $t'),
                selected: selected == t,
                onSelected: (_) => onSelected(t),
              ),
          ],
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.collection, required this.shown});

  final CollectionController collection;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = collection.filter;
    final total = collection.total;
    final favoriteCount =
        collection.visibleRowsUnfiltered.where((r) => r.entry.favorite).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Ligue', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Toutes'),
              selected: filter.league == null,
              onSelected: (_) =>
                  collection.setFilter(collection.filter.copyWith(clearLeague: true)),
            ),
            for (final l in League.values)
              ChoiceChip(
                label: Text(l.label),
                selected: filter.league == l,
                onSelected: (_) =>
                    collection.setFilter(collection.filter.copyWith(league: l)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FilterChip(
          avatar: Icon(
            filter.favoritesOnly ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: favoriteRed,
          ),
          label: Text('Favoris uniquement ($favoriteCount)'),
          selected: filter.favoritesOnly,
          onSelected: (on) => collection.setFilter(
            collection.filter.copyWith(favoritesOnly: on),
          ),
        ),
        const SizedBox(height: 10),
        _RankChips(
          title: 'Rang d\'IV',
          keyPrefix: 'iv-rank',
          selected: filter.maxRank,
          onSelected: (t) => collection.setFilter(
            t == null
                ? collection.filter.copyWith(clearMaxRank: true)
                : collection.filter.copyWith(maxRank: t),
          ),
        ),
        const SizedBox(height: 10),
        _RankChips(
          title: 'Rang de ligue',
          keyPrefix: 'meta-rank',
          selected: filter.maxMetaRank,
          onSelected: (t) => collection.setFilter(
            t == null
                ? collection.filter.copyWith(clearMaxMetaRank: true)
                : collection.filter.copyWith(maxMetaRank: t),
          ),
        ),
        const SizedBox(height: 10),
        _TypeFilterRow(collection: collection),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            MoveFilterButtons(collection: collection),
            if (filter.activeCount > 0)
              ActionChip(
                avatar: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Effacer les filtres'),
                onPressed: () =>
                    collection.setFilter(const CollectionFilter()),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                total == 0
                    ? 'Aucun Pokémon enregistré'
                    : '$shown Pokémon sur $total',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.sort, size: 18),
            const SizedBox(width: 4),
            DropdownButton<CollectionSort>(
              value: collection.sort,
              underline: const SizedBox.shrink(),
              items: <DropdownMenuItem<CollectionSort>>[
                for (final s in CollectionSort.values)
                  DropdownMenuItem<CollectionSort>(
                    value: s,
                    child: Text(s.label),
                  ),
              ],
              onChanged: (s) {
                if (s != null) collection.setSort(s);
              },
            ),
          ],
        ),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sur l\'écran de rang, choisis un Pokémon et ses IV puis touche '
              '« Enregistrer » pour l\'ajouter ici.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else if (shown == 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Aucun Pokémon ne correspond à ces filtres.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// Filtre de type en un appui : une pastille par type présent dans la
/// collection, avec le nombre de Pokémon de ce type. Plusieurs types
/// sélectionnés = au moins un des types.
class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({required this.collection});

  final CollectionController collection;

  @override
  Widget build(BuildContext context) {
    final counts = <PokeType, int>{};
    for (final row in collection.visibleRowsUnfiltered) {
      for (final t in row.species.types) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return TypeFilterRow(
      title: 'Types',
      hint: 'Types (touche pour filtrer)',
      keyPrefix: 'type-filter',
      counts: counts,
      selected: collection.filter.types,
      onChanged: (types) => collection.setFilter(
        collection.filter.copyWith(types: types),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.row,
    this.metaRank,
    required this.onTap,
    required this.onDelete,
  });

  final CollectionRow row;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Rang dans la méta de la ligue du tag, ou `null`.
  final int? metaRank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = row.entry;
    final iv = e.iv;
    return Card(
      key: ValueKey<String>('collection-${e.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      color: tileColor(context, row),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: tileBorder(context, row),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: <Widget>[
              Column(
                children: <Widget>[
                  for (final t in row.species.types)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: TypeBadge(t, size: 30),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            row.species.nameFr,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (e.favorite) const FavoriteHeart(size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        LeagueTag(e),
                        if (metaRank != null) MetaRankTag(metaRank!),
                        if (e.isRankOne) const RankOneBadge(),
                        EntryAttributes(e),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IV ${iv.atk}/${iv.def}/${iv.sta} · '
                      '${formatPercent(e.percent)} · PC ${formatGrouped(e.cp)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Supprimer ${row.species.nameFr}',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.row, required this.onTap, this.metaRank});

  final CollectionRow row;
  final VoidCallback onTap;

  /// Rang dans la méta de la ligue du tag, ou `null`.
  final int? metaRank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = row.entry;
    final iv = e.iv;
    return Card(
      key: ValueKey<String>('collection-${e.id}'),
      margin: EdgeInsets.zero,
      color: tileColor(context, row),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: tileBorder(context, row),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  for (final t in row.species.types)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 2),
                      child: TypeBadge(t, size: 18),
                    ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: EntryAttributes(e, compact: true),
                    ),
                  ),
                  if (e.favorite) ...<Widget>[
                    const SizedBox(width: 2),
                    const FavoriteHeart(size: 14),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                row.species.nameFr,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              const Spacer(),
              Wrap(
                spacing: 6,
                children: <Widget>[
                  Text(
                    '${iv.atk}/${iv.def}/${iv.sta}',
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    formatPercent(e.percent),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              _CompactLeague(entry: e),
              if (metaRank != null) ...<Widget>[
                const SizedBox(height: 3),
                MetaRankTag(metaRank!, compact: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligue et rang d'une case de mosaïque : « Super · 12 », sur fond or avec
/// une étoile pour un rang 1.
class _CompactLeague extends StatelessWidget {
  const _CompactLeague({required this.entry});

  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = entry.isRankOne;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: first
            ? rankOneGold
            : theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        first
            ? '★ ${entry.league.label} · 1'
            : '${entry.league.label} · ${formatGrouped(entry.rank)}',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: first ? const Color(0xFF1D2A5B) : null,
        ),
      ),
    );
  }
}
