import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/poke_type.dart';
import '../state/collection_controller.dart';
import 'collection_detail_screen.dart';
import 'collection_widgets.dart';
import 'format.dart';
import 'save_pokemon_sheet.dart';
import 'type_badge.dart';

/// Collection : Pokémon enregistrés, filtrables, triables, en liste ou en
/// mosaïque.
class CollectionScreen extends StatelessWidget {
  /// Crée l'écran.
  const CollectionScreen({
    super.key,
    required this.collection,
    required this.onOpen,
    this.metaMoves,
  });

  /// Attaques recommandées par la méta (menu de modification).
  final MetaMovesFor? metaMoves;

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
            final rows = collection.visibleRows;
            final scale = MediaQuery.textScalerOf(context).scale(1);
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
                            onTap: () => _openDetail(context, rows[i]),
                            onDelete: () => _delete(context, rows[i].entry),
                          ),
                        )
                      : SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisExtent: 168 * scale,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: rows.length,
                          itemBuilder: (context, i) => _GridTile(
                            row: rows[i],
                            onTap: () => _openDetail(context, rows[i]),
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
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, CollectionEntry entry) async {
    if (await confirmDelete(context, entry)) collection.remove(entry.id);
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
    final moveCount =
        filter.moveTypes.length + (filter.moveQuery.trim().isEmpty ? 0 : 1);
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
        Text('Rang d\'IV', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final t in rankThresholds)
              ChoiceChip(
                label: Text(t == null ? 'Tous' : 'Top $t'),
                selected: filter.maxRank == t,
                onSelected: (_) => collection.setFilter(
                  t == null
                      ? collection.filter.copyWith(clearMaxRank: true)
                      : collection.filter.copyWith(maxRank: t),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _TypeFilterRow(collection: collection),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            ActionChip(
              avatar: const Icon(Icons.flash_on, size: 18),
              label: Text(moveCount == 0 ? 'Attaques' : 'Attaques ($moveCount)'),
              onPressed: () => _moveSheet(context),
            ),
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

  Future<void> _moveSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ListenableBuilder(
        listenable: collection,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Attaques enregistrées ; à défaut, celles que le Pokémon '
                  'peut apprendre.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: collection.filter.moveQuery,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'attaque (ex. Rapace)',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => collection.setFilter(
                    collection.filter.copyWith(moveQuery: v),
                  ),
                ),
                const SizedBox(height: 12),
                _TypePicker(
                  title: 'Attaque de type',
                  selected: collection.filter.moveTypes,
                  onChanged: (v) => collection.setFilter(
                    collection.filter.copyWith(moveTypes: v),
                  ),
                ),
              ],
            ),
          ),
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
    final theme = Theme.of(context);
    final counts = <PokeType, int>{};
    for (final row in collection.visibleRowsUnfiltered) {
      for (final t in row.species.types) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final selected = collection.filter.types;
    final types = <PokeType>[
      for (final t in PokeType.values)
        if (counts.containsKey(t) || selected.contains(t)) t,
    ];
    if (types.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                selected.isEmpty
                    ? 'Types (touche pour filtrer)'
                    : 'Types · ${selected.length} choisi${selected.length > 1 ? 's' : ''}',
                style: theme.textTheme.labelLarge,
              ),
            ),
            if (selected.isNotEmpty)
              TextButton(
                onPressed: () => collection.setFilter(
                  collection.filter.copyWith(types: const <PokeType>{}),
                ),
                child: const Text('Tous les types'),
              ),
          ],
        ),
        SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = types[i];
                final on = selected.contains(t);
                final dim = selected.isNotEmpty && !on;
                return Semantics(
                  button: true,
                  selected: on,
                  label: '${t.nameFr}, ${counts[t] ?? 0} Pokémon',
                  child: InkWell(
                    key: ValueKey<String>('type-filter-${t.id}'),
                    customBorder: const CircleBorder(),
                    onTap: () => collection.setFilter(
                      collection.filter.copyWith(
                        types: on
                            ? (<PokeType>{...selected}..remove(t))
                            : <PokeType>{...selected, t},
                      ),
                    ),
                    child: Opacity(
                      opacity: dim ? 0.35 : 1,
                      child: ExcludeSemantics(
                        child: Column(
                          children: <Widget>[
                            TypeBadge(
                              t,
                              size: 40,
                              ring: on ? rankOneGold : null,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${counts[t] ?? 0}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: on ? FontWeight.w800 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.title,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final Set<PokeType> selected;
  final void Function(Set<PokeType>) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            if (selected.isNotEmpty)
              TextButton(
                onPressed: () => onChanged(const <PokeType>{}),
                child: const Text('Tout effacer'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final t in PokeType.values)
              FilterChip(
                avatar: ExcludeSemantics(child: TypeBadge(t, size: 22)),
                label: Text(t.nameFr),
                selected: selected.contains(t),
                showCheckmark: false,
                onSelected: (on) => onChanged(
                  on
                      ? <PokeType>{...selected, t}
                      : <PokeType>{...selected}..remove(t),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.row,
    required this.onTap,
    required this.onDelete,
  });

  final CollectionRow row;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
                    Text(row.species.nameFr, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        LeagueTag(e),
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
  const _GridTile({required this.row, required this.onTap});

  final CollectionRow row;
  final VoidCallback onTap;

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
        borderRadius: BorderRadius.circular(16),
        side: tileBorder(context, row),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  for (final t in row.species.types)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: TypeBadge(t, size: 24),
                    ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: EntryAttributes(e),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                row.species.nameFr,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
              ),
              const Spacer(),
              Text(
                '${iv.atk}/${iv.def}/${iv.sta} · ${formatPercent(e.percent)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              if (e.isRankOne) const RankOneBadge() else LeagueTag(e),
              if (e.isRankOne) ...<Widget>[
                const SizedBox(height: 2),
                Text(e.league.label, style: theme.textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
