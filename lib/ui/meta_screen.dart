import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/meta.dart';
import '../state/meta_controller.dart';
import 'format.dart';
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
  });

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
            final query = _normalize(_filter);
            final entries = <MetaEntry>[
              for (final e in data.leagues[_league] ?? const <MetaEntry>[])
                if (query.isEmpty || _normalize(e.name).contains(query)) e,
            ];
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: entries.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) return _header(theme, data);
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

  Widget _header(ThemeData theme, MetaSnapshot data) {
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
        TextField(
          decoration: const InputDecoration(
            labelText: 'Filtrer par nom',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

String _normalize(String s) {
  const from = 'àâäáãéèêëíìîïóòôöõúùûüçñœ';
  const to = 'aaaaaeeeeiiiiooooouuuucno';
  final lower = s.toLowerCase();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString().trim();
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
                        entry.fast.nameFr,
                        for (final c in entry.charged) c.nameFr,
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
            _MoveRow(label: 'Immédiate', move: entry.fast),
            for (final c in entry.charged)
              _MoveRow(label: 'Chargée', move: c),
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

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.label, required this.move});

  final String label;
  final MetaMove move;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          TypeBadge(move.type, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(move.nameFr, style: theme.textTheme.bodyLarge)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
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
