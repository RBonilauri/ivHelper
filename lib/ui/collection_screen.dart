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

/// Puces compactes d'un choix unique : un titre à gauche, les puces à
/// droite (passent à la ligne si la place manque).
class _ChoiceLine<T> extends StatelessWidget {
  const _ChoiceLine({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;

  /// (valeur, libellé, clé) de chaque puce.
  final List<(T, String, String?)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(title, style: theme.textTheme.labelLarge),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                for (final (value, label, key) in options)
                  ChoiceChip(
                    key: key == null ? null : ValueKey<String>(key),
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                    showCheckmark: false,
                    selected: selected == value,
                    onSelected: (_) => onSelected(value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Options « Tous / Top 1 / Top 10 / Top 50 » d'un filtre de rang ; clés
/// `<keyPrefix>-all`, `<keyPrefix>-10`…
List<(int?, String, String?)> _rankOptions(String keyPrefix) =>
    <(int?, String, String?)>[
      for (final t in rankThresholds)
        (t, t == null ? 'Tous' : 'Top $t', '$keyPrefix-${t ?? 'all'}'),
    ];

/// En-tête de la collection : bouton « Filtres » (panneau replié par
/// défaut), effacement rapide, nombre de Pokémon et tri.
class _Controls extends StatelessWidget {
  const _Controls({required this.collection, required this.shown});

  final CollectionController collection;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = collection.filter;
    final total = collection.total;
    final active = filter.activeCount;
    final open = collection.filtersOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Wrap : sur un écran étroit ou en grand texte, le tri passe à la
        // ligne au lieu de déborder.
        SizedBox(
          width: double.infinity,
          child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Badge(
                  isLabelVisible: active > 0,
                  label: Text('$active'),
                  child: FilledButton.tonalIcon(
                    key: const ValueKey<String>('filters-toggle'),
                    onPressed: () => collection.setFiltersOpen(!open),
                    icon: Icon(open ? Icons.expand_less : Icons.tune),
                    label: const Text('Filtres'),
                  ),
                ),
                if (active > 0)
                  IconButton(
                    tooltip: 'Effacer les filtres',
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: () =>
                        collection.setFilter(const CollectionFilter()),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
          ],
        ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: open
              ? _FilterPanel(collection: collection)
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0 ? 'Aucun Pokémon enregistré' : '$shown Pokémon sur $total',
          style: theme.textTheme.bodyMedium,
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

/// Panneau des filtres, dans une carte : favoris, ligue, rangs, types,
/// attaques, puis « Effacer les filtres ».
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.collection});

  final CollectionController collection;

  @override
  Widget build(BuildContext context) {
    final filter = collection.filter;
    final favoriteCount =
        collection.visibleRowsUnfiltered.where((r) => r.entry.favorite).length;
    void set(CollectionFilter Function(CollectionFilter current) change) =>
        // Toujours partir du filtre actuel, pas de celui de cet affichage :
        // deux appuis rapides ne s'écrasent pas.
        collection.setFilter(change(collection.filter));
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              key: const ValueKey<String>('favorites-only'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              secondary: Icon(
                filter.favoritesOnly ? Icons.favorite : Icons.favorite_border,
                color: favoriteRed,
              ),
              title: Text('Favoris uniquement ($favoriteCount)'),
              value: filter.favoritesOnly,
              onChanged: (on) => set((f) => f.copyWith(favoritesOnly: on)),
            ),
            _ChoiceLine<League?>(
              title: 'Ligue',
              options: <(League?, String, String?)>[
                (null, 'Toutes', null),
                for (final l in League.values) (l, l.label, null),
              ],
              selected: filter.league,
              onSelected: (l) => set(
                (f) => l == null
                    ? f.copyWith(clearLeague: true)
                    : f.copyWith(league: l),
              ),
            ),
            _ChoiceLine<int?>(
              title: 'Rang d\'IV',
              options: _rankOptions('iv-rank'),
              selected: filter.maxRank,
              onSelected: (t) => set(
                (f) => t == null
                    ? f.copyWith(clearMaxRank: true)
                    : f.copyWith(maxRank: t),
              ),
            ),
            _ChoiceLine<int?>(
              title: 'Rang méta',
              options: _rankOptions('meta-rank'),
              selected: filter.maxMetaRank,
              onSelected: (t) => set(
                (f) => t == null
                    ? f.copyWith(clearMaxMetaRank: true)
                    : f.copyWith(maxMetaRank: t),
              ),
            ),
            const Divider(height: 16),
            _TypeFilterRow(collection: collection),
            const SizedBox(height: 10),
            Text('Attaques', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            MoveFilterButtons(collection: collection),
            if (filter.activeCount > 0) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => set((_) => const CollectionFilter()),
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Effacer les filtres'),
                ),
              ),
            ],
          ],
        ),
      ),
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
