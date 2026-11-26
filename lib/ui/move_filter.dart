import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/moves.dart';
import '../core/poke_type.dart';
import '../core/species_repository.dart';
import '../state/collection_controller.dart';
import 'search_field.dart';
import 'type_badge.dart';
import 'type_filter_row.dart';

/// Boutons « Immédiate », « ET » / « OU » et « Chargée » du filtre
/// d'attaques de la collection.
class MoveFilterButtons extends StatelessWidget {
  /// Crée les boutons pour [collection].
  const MoveFilterButtons({required this.collection, super.key});

  /// Collection filtrée.
  final CollectionController collection;

  @override
  Widget build(BuildContext context) {
    final filter = collection.filter;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _SideButton(collection: collection, fast: true),
        ActionChip(
          key: const ValueKey<String>('move-filter-op'),
          tooltip: filter.movesEither
              ? 'Immédiate ou chargée : une seule suffit (touche pour ET)'
              : 'Immédiate et chargée : les deux doivent correspondre '
                  '(touche pour OU)',
          label: Text(
            filter.movesEither ? 'OU' : 'ET',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          onPressed: () => collection.setFilter(
            filter.copyWith(movesEither: !filter.movesEither),
          ),
        ),
        _SideButton(collection: collection, fast: false),
      ],
    );
  }
}

/// Bouton d'un côté (immédiate ou chargée), avec le nombre de choix et les
/// logos des types choisis.
class _SideButton extends StatelessWidget {
  const _SideButton({required this.collection, required this.fast});

  final CollectionController collection;
  final bool fast;

  @override
  Widget build(BuildContext context) {
    final filter = collection.filter;
    final ids = fast ? filter.fastMoves : filter.chargedMoves;
    final kinds = fast ? filter.fastTypes : filter.chargedTypes;
    final n = ids.length + kinds.length;
    final name = fast ? 'Immédiate' : 'Chargée';
    return ActionChip(
      key: ValueKey<String>('move-filter-${fast ? 'fast' : 'charged'}'),
      avatar: Icon(fast ? Icons.flash_on : Icons.bolt, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(n == 0 ? name : '$name ($n)'),
          for (final t in PokeType.values)
            if (kinds.contains(t))
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: TypeBadge(t, size: 18),
              ),
        ],
      ),
      onPressed: () => showMoveSideSheet(context, collection, fast: fast),
    );
  }
}

/// Ouvre la feuille de filtre du côté immédiate ([fast]) ou chargée.
Future<void> showMoveSideSheet(
  BuildContext context,
  CollectionController collection, {
  required bool fast,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _MoveSideSheet(collection: collection, fast: fast),
  );
}

class _MoveSideSheet extends StatefulWidget {
  const _MoveSideSheet({required this.collection, required this.fast});

  final CollectionController collection;
  final bool fast;

  @override
  State<_MoveSideSheet> createState() => _MoveSideSheetState();
}

class _MoveSideSheetState extends State<_MoveSideSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  CollectionController get _collection => widget.collection;
  bool get _fast => widget.fast;
  String get _side => _fast ? 'fast' : 'charged';

  Set<String> get _ids =>
      _fast ? _collection.filter.fastMoves : _collection.filter.chargedMoves;

  Set<PokeType> get _kinds =>
      _fast ? _collection.filter.fastTypes : _collection.filter.chargedTypes;

  void _setIds(Set<String> ids) => _collection.setFilter(
        _fast
            ? _collection.filter.copyWith(fastMoves: ids)
            : _collection.filter.copyWith(chargedMoves: ids),
      );

  void _setKinds(Set<PokeType> kinds) => _collection.setFilter(
        _fast
            ? _collection.filter.copyWith(fastTypes: kinds)
            : _collection.filter.copyWith(chargedTypes: kinds),
      );

  void _pick(Move move) {
    _setIds(<String>{..._ids, move.id});
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _collection,
      builder: (context, _) {
        final theme = Theme.of(context);
        final rows = _collection.visibleRowsUnfiltered;
        final options = moveOptions(rows, fast: _fast);
        final byId = <String, Move>{for (final m in options) m.id: m};
        final q = normalizeName(_query);
        final matches = q.isEmpty
            ? const <Move>[]
            : <Move>[
                for (final m in options)
                  if (!_ids.contains(m.id) &&
                      normalizeName(m.nameFr).contains(q))
                    m,
              ].take(20).toList();
        final ids = _ids;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _fast ? 'Attaque immédiate' : 'Attaque chargée',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Attaques enregistrées ; à défaut, celles que le Pokémon '
                    'peut apprendre. Une des attaques ou un des types choisis '
                    'suffit.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  if (ids.isNotEmpty) ...<Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final id in ids)
                          InputChip(
                            key: ValueKey<String>('move-selected-$id'),
                            avatar: byId[id] == null
                                ? null
                                : TypeBadge(byId[id]!.type, size: 20),
                            label: Text(byId[id]?.nameFr ?? id),
                            onDeleted: () => _setIds(<String>{
                              for (final x in ids)
                                if (x != id) x,
                            }),
                            deleteButtonTooltipMessage: 'Retirer',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  SearchField(
                    key: ValueKey<String>('move-search-$_side'),
                    controller: _search,
                    label: _fast
                        ? 'Nom d\'attaque immédiate'
                        : 'Nom d\'attaque chargée',
                    hint: _fast ? 'ex. Calcination' : 'ex. Rapace',
                    dense: true,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  if (q.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    if (matches.isEmpty)
                      Text(
                        _fast
                            ? 'Aucune attaque immédiate de ta collection ne '
                                'correspond.'
                            : 'Aucune attaque chargée de ta collection ne '
                                'correspond.',
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final m in matches)
                            ActionChip(
                              key: ValueKey<String>('move-option-${m.id}'),
                              avatar: TypeBadge(m.type, size: 20),
                              label: Text(m.nameFr),
                              onPressed: () => _pick(m),
                            ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 12),
                  TypeFilterRow(
                    title: 'Types',
                    hint: 'Types d\'attaque (touche pour filtrer)',
                    keyPrefix: '$_side-type',
                    counts: moveTypeCounts(rows, fast: _fast),
                    selected: _kinds,
                    onChanged: _setKinds,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
