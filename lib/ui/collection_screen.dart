import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/poke_type.dart';
import '../state/collection_controller.dart';
import 'format.dart';
import 'type_badge.dart';

/// Rangs proposés par le filtre de rang (`null` : tous).
const List<int?> rankThresholds = <int?>[null, 10, 50, 100, 500];

/// Collection : Pokémon enregistrés avec leurs IV, filtrables et triables.
class CollectionScreen extends StatelessWidget {
  /// Crée l'écran.
  const CollectionScreen({
    super.key,
    required this.collection,
    required this.onOpen,
  });

  /// État de la collection.
  final CollectionController collection;

  /// Ouvre une entrée dans l'écran de rang.
  final void Function(BuildContext context, CollectionEntry entry) onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma collection')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: collection,
          builder: (context, _) {
            final rows = collection.visibleRows;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: rows.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) return _Controls(collection: collection, shown: rows.length);
                final row = rows[i - 1];
                return _RowCard(
                  row: row,
                  onTap: () => onOpen(context, row.entry),
                  onDelete: () => _delete(context, row.entry),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _delete(BuildContext context, CollectionEntry entry) {
    collection.remove(entry.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${entry.speciesName} retiré de la collection'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => collection.restore(entry),
          ),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<League>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            ),
          ),
          segments: <ButtonSegment<League>>[
            for (final l in League.values)
              ButtonSegment<League>(
                value: l,
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l.label),
                    Text(l.capLabel, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
          ],
          selected: <League>{collection.league},
          onSelectionChanged: (s) => collection.setLeague(s.first),
        ),
        const SizedBox(height: 12),
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
                      ? filter.copyWith(clearMaxRank: true)
                      : filter.copyWith(maxRank: t),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ActionChip(
              avatar: const Icon(Icons.category, size: 18),
              label: Text(
                filter.types.isEmpty ? 'Types' : 'Types (${filter.types.length})',
              ),
              onPressed: () => _typeSheet(
                context,
                title: 'Filtrer par type du Pokémon',
                read: () => collection.filter.types,
                write: (v) =>
                    collection.setFilter(collection.filter.copyWith(types: v)),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.flash_on, size: 18),
              label: Text(
                filter.moveTypes.isEmpty && filter.moveQuery.trim().isEmpty
                    ? 'Attaques'
                    : 'Attaques (${filter.moveTypes.length + (filter.moveQuery.trim().isEmpty ? 0 : 1)})',
              ),
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
        const SizedBox(height: 8),
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
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Sur l\'écran de rang, choisis un Pokémon et ses IV puis touche '
              '« Enregistrer » pour l\'ajouter ici.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else if (shown == 0)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Aucun Pokémon ne correspond à ces filtres.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _typeSheet(
    BuildContext context, {
    required String title,
    required Set<PokeType> Function() read,
    required void Function(Set<PokeType>) write,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: collection,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _TypePicker(title: title, selected: read(), onChanged: write),
          ),
        ),
      ),
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
                  title: 'Peut apprendre une attaque de type',
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

class _RowCard extends StatelessWidget {
  const _RowCard({
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
    final r = row.rank;
    final iv = row.entry.iv;
    return Card(
      key: ValueKey<String>('collection-${row.entry.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: <Widget>[
                    Text('Rang', style: theme.textTheme.labelSmall),
                    Text(
                      formatGrouped(r.rank),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            row.species.nameFr,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        for (final t in row.species.types)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: TypeBadge(t, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IV ${iv.atk}/${iv.def}/${iv.sta} · '
                      '${formatPercent(r.percent)} · n° ${row.species.dex}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'PC ${formatGrouped(r.cp)} · niveau ${formatLevel(r.level)}'
                      '${row.entry.maxLevel > 50 ? '' : ' (max 50)'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Retirer ${row.species.nameFr}',
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
