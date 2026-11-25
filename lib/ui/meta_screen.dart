import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/meta.dart';
import '../core/moves.dart';
import '../core/poke_type.dart';
import '../state/meta_controller.dart';
import 'format.dart';
import 'move_line.dart';
import 'search_field.dart';
import 'type_badge.dart';

const Color _owned = Color(0xFFFFCB05);
const Color _ownedText = Color(0xFF1D2A5B);

/// Actions proposées depuis la fiche d'un Pokémon de la méta.
class MetaActions {
  /// Crée les actions.
  const MetaActions({
    required this.checkIvs,
    required this.addToTeam,
    required this.isOwned,
    required this.ownedRank,
    this.moves,
  });

  /// Recueil des attaques (énergie et effets), s'il est connu.
  final MoveBook? moves;

  /// Meilleur rang d'un Pokémon de la collection correspondant à [entry]
  /// (même espèce, obscur ou non, tag de [league]), ou `null`.
  final int? Function(MetaEntry entry, MetaLeague league) ownedRank;

  /// Vrai si l'espèce nommée [name] est dans la collection.
  final bool Function(String name) isOwned;

  /// Ouvre le calcul du rang des IV pour cette entrée.
  final void Function(BuildContext context, MetaEntry entry) checkIvs;

  /// Ajoute cette entrée au team builder.
  final void Function(BuildContext context, MetaEntry entry) addToTeam;
}

/// Onglet Méta : classement PvPoke en Super, Hyper et Master.
class MetaScreen extends StatefulWidget {
  /// Crée l'onglet.
  const MetaScreen({
    super.key,
    required this.meta,
    required this.actions,
    this.collectionChanges,
  });

  /// Notifié quand la collection change (mise à jour des Pokémon possédés).
  final Listenable? collectionChanges;

  /// État de la méta.
  final MetaController meta;

  /// Actions de la fiche détaillée.
  final MetaActions actions;

  @override
  State<MetaScreen> createState() => _MetaScreenState();
}

class _MetaScreenState extends State<MetaScreen> {
  MetaLeague _league = MetaLeague.great;
  String _filter = '';
  Set<PokeType> _types = const <PokeType>{};
  Set<PokeType> _moveTypes = const <PokeType>{};
  bool _ownedOnly = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.meta.ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Méta'),
        actions: <Widget>[
          ListenableBuilder(
            listenable: widget.meta,
            builder: (context, _) => widget.meta.refreshing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Vérifier les mises à jour',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => unawaited(widget.meta.refresh()),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable?>[
            widget.meta,
            widget.collectionChanges,
          ]),
          builder: (context, _) {
            final data = widget.meta.data;
            if (data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: widget.meta.message == null
                      ? const CircularProgressIndicator()
                      : Text(widget.meta.message!, textAlign: TextAlign.center),
                ),
              );
            }
            final league = data.leagues[_league] ?? const <MetaEntry>[];
            final entries = filterMeta(
              league,
              query: _filter,
              types: _types,
              moveTypes: _moveTypes,
              keep: _ownedOnly
                  ? (e) => widget.actions.ownedRank(e, _league) != null
                  : null,
            );
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: entries.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _header(
                    theme,
                    data,
                    league,
                    empty: entries.isEmpty,
                  );
                }
                final e = entries[i - 1];
                return _MetaTile(
                  entry: e,
                  ownedRank: widget.actions.ownedRank(e, _league),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MetaDetailScreen(
                        entry: e,
                        league: _league,
                        actions: widget.actions,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(
    ThemeData theme,
    MetaSnapshot data,
    List<MetaEntry> league, {
    required bool empty,
  }) {
    final typeCounts = <PokeType, int>{};
    final moveCounts = <PokeType, int>{};
    for (final e in league) {
      for (final t in e.types) {
        typeCounts[t] = (typeCounts[t] ?? 0) + 1;
      }
      for (final t in <PokeType>{e.fast.type, for (final c in e.charged) c.type}) {
        moveCounts[t] = (moveCounts[t] ?? 0) + 1;
      }
    }
    final active = _types.length + _moveTypes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<MetaLeague>(
          showSelectedIcon: false,
          segments: <ButtonSegment<MetaLeague>>[
            for (final l in MetaLeague.values)
              ButtonSegment<MetaLeague>(
                value: l,
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l.label),
                    Text(l.cap, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
          ],
          selected: <MetaLeague>{_league},
          onSelectionChanged: (s) => setState(() => _league = s.first),
        ),
        const SizedBox(height: 8),
        Text(
          'Classement PvPoke · mis à jour le ${data.updatedFr}',
          style: theme.textTheme.bodySmall,
        ),
        if (widget.meta.message != null)
          Text(
            widget.meta.message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        const SizedBox(height: 8),
        SearchField(
          label: 'Filtrer par nom',
          dense: true,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 8),
        FilterChip(
          key: const ValueKey<String>('meta-owned'),
          avatar: const Icon(Icons.check_circle_outline, size: 18),
          label: Text('Possédés en ${_league.label}'),
          selected: _ownedOnly,
          onSelected: (on) => setState(() => _ownedOnly = on),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.filter_list),
            title: Text(active == 0 ? 'Filtres' : 'Filtres ($active)'),
            subtitle: const Text('Types du Pokémon et des attaques'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TypeChips(
                title: 'Type du Pokémon',
                keyPrefix: 'meta-type',
                counts: typeCounts,
                selected: _types,
                onChanged: (s) => setState(() => _types = s),
              ),
              const SizedBox(height: 12),
              _TypeChips(
                title: "Type d'attaque (jeu recommandé)",
                keyPrefix: 'meta-move',
                counts: moveCounts,
                selected: _moveTypes,
                onChanged: (s) => setState(() => _moveTypes = s),
              ),
              if (active > 0)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _types = const <PokeType>{};
                      _moveTypes = const <PokeType>{};
                    }),
                    child: const Text('Effacer les filtres'),
                  ),
                ),
            ],
          ),
        ),
        if (empty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucun Pokémon ne correspond à ces filtres.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// Puces de types à cocher, avec le nombre de Pokémon de la ligue concernés.
class _TypeChips extends StatelessWidget {
  const _TypeChips({
    required this.title,
    required this.keyPrefix,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String keyPrefix;
  final Map<PokeType, int> counts;
  final Set<PokeType> selected;
  final ValueChanged<Set<PokeType>> onChanged;

  @override
  Widget build(BuildContext context) {
    final types = <PokeType>[
      for (final t in PokeType.values)
        if (counts.containsKey(t) || selected.contains(t)) t,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final t in types)
              FilterChip(
                key: ValueKey<String>('$keyPrefix-${t.id}'),
                avatar: ExcludeSemantics(child: TypeBadge(t, size: 20)),
                label: Text('${t.nameFr} (${counts[t] ?? 0})'),
                selected: selected.contains(t),
                showCheckmark: false,
                selectedColor: typeColors[t]!.withValues(alpha: 0.35),
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

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.entry,
    required this.ownedRank,
    required this.onTap,
  });

  final MetaEntry entry;
  final int? ownedRank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = entry.score;
    final owned = ownedRank;
    final tint = entry.types.isEmpty
        ? theme.colorScheme.outlineVariant
        : typeColors[entry.types.first]!.withValues(alpha: 0.6);
    return Card(
      key: ValueKey<String>('meta-${entry.rank}'),
      margin: const EdgeInsets.only(bottom: 8),
      color: typeTint(context, entry.types),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: owned != null
            ? const BorderSide(color: _owned, width: 3)
            : BorderSide(color: tint),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 36,
                child: Text(
                  '${entry.rank}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            entry.name,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        for (final t in entry.types)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: TypeBadge(t, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      <String>[
                        entry.fast.label,
                        for (final c in entry.charged) c.label,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (owned != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _owned,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: _ownedText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Dans ta collection · rang ${formatGrouped(owned)}',
                              style: const TextStyle(
                                color: _ownedText,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (score != null)
                Text(
                  score.toStringAsFixed(1).replaceAll('.', ','),
                  style: theme.textTheme.titleSmall,
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fiche d'un Pokémon de la méta.
class MetaDetailScreen extends StatelessWidget {
  /// Crée la fiche de [entry] dans [league].
  const MetaDetailScreen({
    super.key,
    required this.entry,
    required this.league,
    required this.actions,
  });

  /// Pokémon affiché.
  final MetaEntry entry;

  /// Ligue du classement.
  final MetaLeague league;

  /// Actions proposées.
  final MetaActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = entry.score;
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                for (final t in entry.types)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: TypeBadge(t, size: 40),
                  ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '${league.label} · rang ${entry.rank}',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (score != null)
                      Text(
                        'Note ${score.toStringAsFixed(1).replaceAll('.', ',')} / 100',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Attaques recommandées', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _MoveGroup(
              label: 'Immédiate',
              moves: <MetaMove>[entry.fast],
              book: actions.moves,
            ),
            _MoveGroup(
              label: 'Chargée(s)',
              moves: entry.charged,
              book: actions.moves,
            ),
            if (<MetaMove>[entry.fast, ...entry.charged].any((m) => m.elite))
              Text(
                '* attaque d\'événement (Élite)',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            _NameList(
              title: 'Meilleurs matchs',
              icon: Icons.thumb_up_alt_outlined,
              color: const Color(0xFF2EAD74),
              names: entry.bestMatchups,
              isOwned: actions.isOwned,
            ),
            _NameList(
              title: 'Pires adversaires',
              icon: Icons.thumb_down_alt_outlined,
              color: const Color(0xFFE5484D),
              names: entry.worstMatchups,
              isOwned: actions.isOwned,
            ),
            if (<String>[...entry.bestMatchups, ...entry.worstMatchups]
                .any(actions.isOwned))
              Row(
                children: <Widget>[
                  const Icon(Icons.check_circle, size: 16, color: _owned),
                  const SizedBox(width: 6),
                  Text(
                    'En jaune : tu l\'as dans ta collection',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: entry.species == null
                  ? null
                  : () => actions.checkIvs(context, entry),
              icon: const Icon(Icons.leaderboard),
              label: const Text('Voir le rang de mes IV'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: entry.species == null
                  ? null
                  : () => actions.addToTeam(context, entry),
              icon: const Icon(Icons.group_add),
              label: const Text('Ajouter à mon équipe'),
            ),
            const SizedBox(height: 16),
            Text(
              'Source : classement général PvPoke (pvpoke.com).',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveGroup extends StatelessWidget {
  const _MoveGroup({
    required this.label,
    required this.moves,
    required this.book,
  });

  final String label;
  final List<MetaMove> moves;
  final MoveBook? book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (moves.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final m in moves)
          MoveLine(
            move: book?[m.id] ??
                Move(
                  id: m.id,
                  nameFr: m.nameFr,
                  type: m.type,
                  isFast: label == 'Immédiate',
                  power: m.power,
                ),
            label: m.label,
          ),
      ],
    );
  }
}

class _NameList extends StatelessWidget {
  const _NameList({
    required this.title,
    required this.icon,
    required this.color,
    required this.names,
    required this.isOwned,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> names;
  final bool Function(String name) isOwned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final n in names)
                if (isOwned(n))
                  Chip(
                    key: ValueKey<String>('owned-$n'),
                    avatar: const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: _ownedText,
                    ),
                    label: Text(
                      n,
                      style: const TextStyle(
                        color: _ownedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: _owned,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: color),
                  )
                else
                  Chip(
                    label: Text(n),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
