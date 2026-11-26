import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/advanced_search.dart';
import '../core/moves.dart';
import '../core/poke_type.dart';
import '../core/species_repository.dart';
import 'search_field.dart';
import 'type_badge.dart';

/// Générateur avancé de chaîne de recherche : cases à trois états (ajouter,
/// exclure, retirer) par rubrique, bornes d'IV, de PC et de date, et la
/// chaîne résultante à copier en bas.
class AdvancedSearchView extends StatefulWidget {
  /// Crée le générateur.
  const AdvancedSearchView({
    required this.repository,
    required this.moves,
    required this.onCopy,
    super.key,
  });

  /// Espèces proposées dans la rubrique Pokémon.
  final SpeciesRepository repository;

  /// Attaques proposées dans la rubrique Nom d'attaque.
  final MoveBook moves;

  /// Copie la chaîne dans le presse-papiers.
  final Future<void> Function(String text) onCopy;

  @override
  State<AdvancedSearchView> createState() => _AdvancedSearchViewState();
}

class _AdvancedSearchViewState extends State<AdvancedSearchView> {
  final PickGroup _species = PickGroup(const <SearchTerm>[]);
  final PickGroup _types =
      PickGroup(<SearchTerm>[for (final t in PokeType.values) typeTerm(t)]);
  final PickGroup _categories = PickGroup(categoryTerms);
  final PickGroup _status = PickGroup(statusTerms);
  final PickGroup _sizes = PickGroup(sizeTerms);
  final Map<MoveSlot, PickGroup> _moveTypes = <MoveSlot, PickGroup>{
    for (final slot in MoveSlot.values)
      slot: PickGroup(
        <SearchTerm>[for (final t in PokeType.values) moveTypeTerm(t, slot)],
      ),
  };
  final PickGroup _moveNames = PickGroup(const <SearchTerm>[]);
  final PickGroup _elite = PickGroup(<SearchTerm>[eliteTerm]);
  final PickGroup _stars = PickGroup(starTerms);

  MoveSlot _slot = MoveSlot.any;

  /// Rubriques ouvertes (gardé ici : une rubrique sortie de l'écran est
  /// reconstruite).
  final Set<String> _open = <String>{};
  String _speciesQuery = '';
  String _moveQuery = '';
  final TextEditingController _speciesSearch = TextEditingController();
  final TextEditingController _moveSearch = TextEditingController();

  RangeValues _atk = const RangeValues(0, 4);
  RangeValues _def = const RangeValues(0, 4);
  RangeValues _hp = const RangeValues(0, 4);
  final Map<String, TextEditingController> _numbers =
      <String, TextEditingController>{
    for (final k in <String>[
      'cp-min',
      'cp-max',
      'age-min',
      'age-max',
      'year-min',
      'year-max',
    ])
      k: TextEditingController(),
  };

  @override
  void dispose() {
    _speciesSearch.dispose();
    _moveSearch.dispose();
    for (final c in _numbers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? _number(String key) => int.tryParse(_numbers[key]!.text.trim());

  List<PickGroup> get _groups => <PickGroup>[
        _species,
        _types,
        _categories,
        _status,
        _sizes,
        for (final slot in MoveSlot.values) _moveTypes[slot]!,
        _moveNames,
        _elite,
        _stars,
      ];

  String get _result => buildSearch(
        <SearchSection>[for (final g in _groups) g.section()],
        ranges: <String?>[
          statRange(_atk.start.round(), _atk.end.round(), 'attaque'),
          statRange(_def.start.round(), _def.end.round(), 'défense'),
          statRange(_hp.start.round(), _hp.end.round(), 'PV'),
          numberRange('PC', _number('cp-min'), _number('cp-max')),
          numberRange('âge', _number('age-min'), _number('age-max')),
          numberRange('année', _number('year-min'), _number('year-max')),
        ],
      );

  void _clearAll() {
    setState(() {
      for (final g in _groups) {
        g.clear(dropTerms: identical(g, _species) || identical(g, _moveNames));
      }
      _atk = _def = _hp = const RangeValues(0, 4);
      for (final c in _numbers.values) {
        c.clear();
      }
      _speciesSearch.clear();
      _moveSearch.clear();
      _speciesQuery = '';
      _moveQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            key: const ValueKey<String>('adv-list'),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: <Widget>[
              Text(
                '1 appui : ajouter · 2 appuis : exclure (!) · 3 appuis : '
                'retirer. Les rubriques se cumulent (ET) ; dans une rubrique, '
                'le bouton ET/OU relie les cases ajoutées.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              _Section(
                open: _open,
                id: 'species',
                title: 'Pokémon ou famille',
                group: _species,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  SearchField(
                    key: const ValueKey<String>('adv-species-search'),
                    controller: _speciesSearch,
                    label: 'Ajouter un Pokémon',
                    hint: 'Nosferapti ou 41',
                    dense: true,
                    onChanged: (v) => setState(() => _speciesQuery = v),
                  ),
                  if (_speciesQuery.trim().isNotEmpty)
                    _Suggestions(
                      children: <Widget>[
                        for (final s in widget.repository.suggest(_speciesQuery))
                          for (final family in <bool>[false, true])
                            ActionChip(
                              key: ValueKey<String>(
                                'adv-add-${family ? 'family' : 'species'}-${s.dex}',
                              ),
                              avatar: Icon(
                                family ? Icons.account_tree : Icons.add,
                                size: 18,
                              ),
                              label: Text(
                                family ? 'Famille ${s.nameFr}' : s.nameFr,
                              ),
                              onPressed: () => setState(() {
                                _species.add(speciesTerm(s.nameFr, family: family));
                                _speciesSearch.clear();
                                _speciesQuery = '';
                              }),
                            ),
                      ],
                    ),
                  _PickWrap(
                    section: 'species',
                    group: _species,
                    removable: true,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'types',
                title: 'Type du Pokémon',
                group: _types,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  _PickWrap(
                    section: 'types',
                    group: _types,
                    typeOf: PokeType.fromId,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'categories',
                title: 'Légendaire, fabuleux, ultra-chimère',
                group: _categories,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  _PickWrap(
                    section: 'categories',
                    group: _categories,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'status',
                title: 'Chanceux, shiny, obscur, purifié',
                group: _status,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  _PickWrap(
                    section: 'status',
                    group: _status,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'sizes',
                title: 'Taille',
                group: _sizes,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  _PickWrap(
                    section: 'sizes',
                    group: _sizes,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'move-types-${_slot.name}',
                title: 'Type d\'attaque',
                group: _moveTypes[_slot]!,
                extraCount: MoveSlot.values
                    .where((s) => s != _slot)
                    .fold<int>(0, (n, s) => n + _moveTypes[s]!.activeCount),
                onChanged: () => setState(() {}),
                children: <Widget>[
                  SegmentedButton<MoveSlot>(
                    key: const ValueKey<String>('adv-move-slot'),
                    showSelectedIcon: false,
                    segments: <ButtonSegment<MoveSlot>>[
                      for (final s in MoveSlot.values)
                        ButtonSegment<MoveSlot>(
                          value: s,
                          label: Text(
                            _moveTypes[s]!.activeCount == 0
                                ? s.label
                                : '${s.label} (${_moveTypes[s]!.activeCount})',
                          ),
                        ),
                    ],
                    selected: <MoveSlot>{_slot},
                    onSelectionChanged: (s) => setState(() => _slot = s.first),
                  ),
                  _PickWrap(
                    section: 'move-types-${_slot.name}',
                    group: _moveTypes[_slot]!,
                    typeOf: PokeType.fromId,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'moves',
                title: 'Nom d\'attaque',
                group: _moveNames,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  SearchField(
                    key: const ValueKey<String>('adv-move-search'),
                    controller: _moveSearch,
                    label: 'Ajouter une attaque',
                    hint: 'Rapace',
                    dense: true,
                    onChanged: (v) => setState(() => _moveQuery = v),
                  ),
                  if (_moveQuery.trim().isNotEmpty)
                    _Suggestions(
                      children: <Widget>[
                        for (final m in _moveMatches())
                          ActionChip(
                            key: ValueKey<String>('adv-add-move-${m.id}'),
                            avatar: TypeBadge(m.type, size: 20),
                            label: Text(
                              '${m.nameFr} · ${m.isFast ? 'immédiate' : 'chargée'}',
                            ),
                            onPressed: () => setState(() {
                              _moveNames.add(moveNameTerm(m));
                              _moveSearch.clear();
                              _moveQuery = '';
                            }),
                          ),
                      ],
                    ),
                  _PickWrap(
                    section: 'moves',
                    group: _moveNames,
                    removable: true,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'elite',
                title: 'Attaque élite',
                group: _elite,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  Text(
                    'Attaques spéciales, non apprenables par CT (« @spécial »).',
                    style: theme.textTheme.bodySmall,
                  ),
                  _PickWrap(
                    section: 'elite',
                    group: _elite,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'iv',
                title: 'IV',
                group: _stars,
                extraCount: <RangeValues>[_atk, _def, _hp]
                    .where((r) => r.start > 0 || r.end < 4)
                    .length,
                onChanged: () => setState(() {}),
                children: <Widget>[
                  Text('Évaluation', style: theme.textTheme.labelLarge),
                  _PickWrap(
                    section: 'stars',
                    group: _stars,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Par stat, en tranches du jeu (0, 1-5, 6-10, 11-14, 15)',
                    style: theme.textTheme.labelLarge,
                  ),
                  _IvSlider(
                    id: 'atk',
                    label: 'Attaque',
                    values: _atk,
                    onChanged: (v) => setState(() => _atk = v),
                  ),
                  _IvSlider(
                    id: 'def',
                    label: 'Défense',
                    values: _def,
                    onChanged: (v) => setState(() => _def = v),
                  ),
                  _IvSlider(
                    id: 'hp',
                    label: 'PV',
                    values: _hp,
                    onChanged: (v) => setState(() => _hp = v),
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'cp',
                title: 'PC',
                extraCount: _filled('cp'),
                onChanged: () => setState(() {}),
                children: <Widget>[
                  _NumberRow(
                    minKey: 'cp-min',
                    maxKey: 'cp-max',
                    unit: 'PC',
                    controllers: _numbers,
                    onChanged: () => setState(() {}),
                  ),
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      for (final cap in const <int>[500, 1500, 2500])
                        ActionChip(
                          key: ValueKey<String>('adv-cp-cap-$cap'),
                          label: Text('≤ $cap'),
                          onPressed: () => setState(() {
                            _numbers['cp-min']!.clear();
                            _numbers['cp-max']!.text = '$cap';
                          }),
                        ),
                    ],
                  ),
                ],
              ),
              _Section(
                open: _open,
                id: 'date',
                title: 'Date de capture',
                extraCount: _filled('age') + _filled('year'),
                onChanged: () => setState(() {}),
                children: <Widget>[
                  Text(
                    'Capturé il y a (jours ; 0 = dernières 24 h)',
                    style: theme.textTheme.labelLarge,
                  ),
                  _NumberRow(
                    minKey: 'age-min',
                    maxKey: 'age-max',
                    unit: 'jours',
                    controllers: _numbers,
                    onChanged: () => setState(() {}),
                  ),
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      for (final (label, max) in const <(String, int)>[
                        ('Aujourd\'hui', 0),
                        ('7 jours', 6),
                        ('30 jours', 29),
                      ])
                        ActionChip(
                          key: ValueKey<String>('adv-age-$max'),
                          label: Text(label),
                          onPressed: () => setState(() {
                            _numbers['age-min']!.text = '0';
                            _numbers['age-max']!.text = '$max';
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Année de capture', style: theme.textTheme.labelLarge),
                  _NumberRow(
                    minKey: 'year-min',
                    maxKey: 'year-max',
                    unit: 'année',
                    controllers: _numbers,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ],
          ),
        ),
        _ResultBar(
          text: result,
          onCopy: () => widget.onCopy(result),
          onClear: _clearAll,
        ),
      ],
    );
  }

  int _filled(String prefix) => (_number('$prefix-min') != null ||
          _number('$prefix-max') != null)
      ? 1
      : 0;

  List<Move> _moveMatches() {
    final q = normalizeName(_moveQuery);
    return <Move>[
      for (final m in widget.moves.all)
        if (normalizeName(m.nameFr).contains(q)) m,
    ].take(12).toList();
  }
}

/// Rubrique repliable : titre, nombre de cases cochées, bouton ET/OU quand
/// au moins deux cases sont ajoutées.
class _Section extends StatelessWidget {
  const _Section({
    required this.id,
    required this.title,
    required this.children,
    required this.onChanged,
    required this.open,
    this.group,
    this.extraCount = 0,
  });

  /// Rubriques ouvertes, mis à jour à l'ouverture et à la fermeture.
  final Set<String> open;

  final String id;
  final String title;
  final List<Widget> children;
  final VoidCallback onChanged;
  final PickGroup? group;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = group;
    final n = (g?.activeCount ?? 0) + extraCount;
    final name = id.split('-').first;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey<String>('adv-section-$name'),
        initiallyExpanded: open.contains(name),
        onExpansionChanged: (on) => on ? open.add(name) : open.remove(name),
        title: Text(
          n == 0 ? title : '$title ($n)',
          key: ValueKey<String>('adv-title-$name'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: n > 0 ? FontWeight.w800 : null,
          ),
        ),
        trailing: g != null && g.includedCount >= 2
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ActionChip(
                    key: ValueKey<String>('adv-op-$id'),
                    tooltip: g.all
                        ? 'Toutes les cases ajoutées (touche pour OU)'
                        : 'Une des cases ajoutées suffit (touche pour ET)',
                    label: Text(
                      g.all ? 'ET' : 'OU',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      g.all = !g.all;
                      onChanged();
                    },
                  ),
                  const Icon(Icons.expand_more),
                ],
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final c in children)
            Padding(padding: const EdgeInsets.only(top: 6), child: c),
        ],
      ),
    );
  }
}

/// Cases à trois états d'une rubrique.
class _PickWrap extends StatelessWidget {
  const _PickWrap({
    required this.section,
    required this.group,
    required this.onChanged,
    this.removable = false,
    this.typeOf,
  });

  final String section;
  final PickGroup group;
  final VoidCallback onChanged;
  final bool removable;
  final PokeType? Function(String id)? typeOf;

  @override
  Widget build(BuildContext context) {
    final terms = group.terms;
    if (terms.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final t in terms)
          _TriChip(
            key: ValueKey<String>('adv-$section-${t.id}'),
            term: t,
            pick: group.pickOf(t.id),
            type: typeOf?.call(t.id),
            onTap: () {
              group.cycle(t.id);
              onChanged();
            },
            onRemove: removable
                ? () {
                    group.remove(t.id);
                    onChanged();
                  }
                : null,
          ),
      ],
    );
  }
}

/// Case à trois états : vide, ajoutée (coche), exclue (« ! », rouge).
class _TriChip extends StatelessWidget {
  const _TriChip({
    required this.term,
    required this.pick,
    required this.onTap,
    super.key,
    this.type,
    this.onRemove,
  });

  final SearchTerm term;
  final Pick pick;
  final VoidCallback onTap;
  final PokeType? type;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon, state) = switch (pick) {
      Pick.off => (null, null, null, 'non cochée'),
      Pick.include => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.check,
          'ajoutée',
        ),
      Pick.exclude => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.block,
          'exclue',
        ),
    };
    final t = type;
    return InputChip(
        tooltip: '${term.label} : $state',
        backgroundColor: bg,
        avatar: t != null
            ? Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  TypeBadge(t, size: 22),
                  if (icon != null)
                    PositionedDirectional(
                      end: -4,
                      bottom: -4,
                      child: Icon(icon, size: 14, color: fg),
                    ),
                ],
              )
            : (icon == null ? null : Icon(icon, size: 18, color: fg)),
        label: Text(
          pick == Pick.exclude ? '!${term.label}' : term.label,
          style: TextStyle(
            color: fg,
            fontWeight: pick == Pick.off ? null : FontWeight.w700,
            decoration:
                pick == Pick.exclude ? TextDecoration.lineThrough : null,
          ),
        ),
        onPressed: onTap,
        onDeleted: onRemove,
        deleteButtonTooltipMessage: 'Retirer',
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Text('Aucun résultat.', style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(spacing: 6, runSpacing: 6, children: children);
  }
}

class _IvSlider extends StatelessWidget {
  const _IvSlider({
    required this.id,
    required this.label,
    required this.values,
    required this.onChanged,
  });

  final String id;
  final String label;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final lo = values.start.round();
    final hi = values.end.round();
    final text = lo == 0 && hi == 4
        ? 'tous'
        : lo == hi
            ? ivBucketLabel(lo)
            : '${ivBucketLabel(lo).split('-').first}-'
                '${ivBucketLabel(hi).split('-').last}';
    return Row(
      children: <Widget>[
        SizedBox(width: 64, child: Text(label)),
        Expanded(
          child: RangeSlider(
            key: ValueKey<String>('adv-iv-$id'),
            values: values,
            max: 4,
            divisions: 4,
            labels: RangeLabels(ivBucketLabel(lo), ivBucketLabel(hi)),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 48, child: Text(text, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.minKey,
    required this.maxKey,
    required this.unit,
    required this.controllers,
    required this.onChanged,
  });

  final String minKey;
  final String maxKey;
  final String unit;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label) => Expanded(
          child: TextField(
            key: ValueKey<String>('adv-$key'),
            controller: controllers[key],
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: label,
              suffixText: unit,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
          ),
        );
    return Row(
      children: <Widget>[
        field(minKey, 'Min'),
        const SizedBox(width: 8),
        field(maxKey, 'Max'),
      ],
    );
  }
}

/// Barre du bas : la chaîne, Copier et Tout effacer.
class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.text,
    required this.onCopy,
    required this.onClear,
  });

  final String text;
  final VoidCallback onCopy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = text.isEmpty;
    return Material(
      elevation: 6,
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  empty ? 'Coche des cases pour construire ta recherche.' : text,
                  key: const ValueKey<String>('adv-result'),
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                  style: empty
                      ? theme.textTheme.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic)
                      : theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
              IconButton(
                key: const ValueKey<String>('adv-clear'),
                tooltip: 'Tout effacer',
                icon: const Icon(Icons.delete_sweep),
                onPressed: empty ? null : onClear,
              ),
              IconButton.filled(
                key: const ValueKey<String>('adv-copy'),
                tooltip: 'Copier',
                icon: const Icon(Icons.copy),
                onPressed: empty ? null : onCopy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
