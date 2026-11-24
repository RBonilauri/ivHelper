import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/moves.dart';
import '../core/rank_table.dart';
import '../core/species_repository.dart';
import '../core/stats.dart';
import '../state/collection_controller.dart';
import 'format.dart';
import 'type_badge.dart';

/// Ouvre [sheet] en feuille du bas.
Future<void> showSaveSheet(BuildContext context, SavePokemonSheet sheet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => sheet,
  );
}

/// Menu d'enregistrement : ligue, attaques, obscur ou purifié, taille,
/// chanceux, chromatique. Tout est facultatif sauf la ligue.
class SavePokemonSheet extends StatefulWidget {
  /// Crée le menu.
  const SavePokemonSheet({
    super.key,
    required this.species,
    required this.iv,
    required this.moves,
    required this.initialLeague,
    required this.rankFor,
    required this.onSave,
    this.initial,
    this.saveLabel = 'Enregistrer dans la collection',
  });

  /// Espèce enregistrée.
  final Species species;

  /// IV enregistrés.
  final Iv iv;

  /// Attaques connues.
  final MoveBook moves;

  /// Ligue proposée par défaut.
  final League initialLeague;

  /// Classement des IV dans une ligue (aperçu du rang).
  final RankEntry Function(League league) rankFor;

  /// Valeurs de départ (modification d'une entrée).
  final CollectionEntry? initial;

  /// Texte du bouton de validation.
  final String saveLabel;

  /// Appelé avec les choix de l'utilisateur.
  final ValueChanged<SaveOptions> onSave;

  @override
  State<SavePokemonSheet> createState() => _SavePokemonSheetState();
}

class _SavePokemonSheetState extends State<SavePokemonSheet> {
  late League _league = widget.initial?.league ?? widget.initialLeague;
  late String? _fast = widget.initial?.fastMove;
  late String? _charged1 = widget.initial?.chargedMove1;
  late String? _charged2 = widget.initial?.chargedMove2;
  late ShadowState _shadow = widget.initial?.shadow ?? ShadowState.none;
  late PokeSize _size = widget.initial?.size ?? PokeSize.none;
  late bool _lucky = widget.initial?.lucky ?? false;
  late bool _shiny = widget.initial?.shiny ?? false;
  late bool _costume = widget.initial?.costume ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iv = widget.iv;
    final rank = widget.rankFor(_league);
    final fastOptions = widget.moves.resolve(widget.species.fastMoves);
    final chargedOptions = widget.moves.resolve(widget.species.chargedMoves);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final t in widget.species.types)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: TypeBadge(t, size: 30),
                ),
              Expanded(
                child: Text(
                  '${widget.species.nameFr} · ${iv.atk}/${iv.def}/${iv.sta}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Label('Ligue'),
          SegmentedButton<League>(
            showSelectedIcon: false,
            segments: <ButtonSegment<League>>[
              for (final l in League.values)
                ButtonSegment<League>(value: l, label: Text(l.label)),
            ],
            selected: <League>{_league},
            onSelectionChanged: (s) => setState(() => _league = s.first),
          ),
          const SizedBox(height: 6),
          Text(
            'Rang ${formatGrouped(rank.rank)} · ${formatPercent(rank.percent)}'
            ' · PC ${formatGrouped(rank.cp)} · niveau ${formatLevel(rank.level)}',
            key: const ValueKey<String>('save-rank'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _Label('Attaques (facultatif)'),
          _MoveField(
            label: 'Attaque immédiate',
            value: _fast,
            options: fastOptions,
            onChanged: (v) => setState(() => _fast = v),
          ),
          const SizedBox(height: 8),
          _MoveField(
            label: 'Attaque chargée',
            value: _charged1,
            options: <Move>[
              for (final m in chargedOptions)
                if (m.id != _charged2) m,
            ],
            onChanged: (v) => setState(() => _charged1 = v),
          ),
          const SizedBox(height: 8),
          _MoveField(
            label: 'Seconde attaque chargée',
            value: _charged2,
            options: <Move>[
              for (final m in chargedOptions)
                if (m.id != _charged1) m,
            ],
            onChanged: (v) => setState(() => _charged2 = v),
          ),
          const SizedBox(height: 16),
          _Label('Forme (facultatif)'),
          Wrap(
            spacing: 6,
            children: <Widget>[
              for (final s in <ShadowState>[
                ShadowState.shadow,
                ShadowState.purified,
              ])
                ChoiceChip(
                  label: Text(s.label),
                  selected: _shadow == s,
                  onSelected: (on) =>
                      setState(() => _shadow = on ? s : ShadowState.none),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Label('Taille (facultatif)'),
          Wrap(
            spacing: 6,
            children: <Widget>[
              for (final s in <PokeSize>[
                PokeSize.xxs,
                PokeSize.xs,
                PokeSize.xl,
                PokeSize.xxl,
              ])
                ChoiceChip(
                  label: Text(s.label),
                  selected: _size == s,
                  onSelected: (on) =>
                      setState(() => _size = on ? s : PokeSize.none),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Label('Particularités (facultatif)'),
          Wrap(
            spacing: 6,
            children: <Widget>[
              FilterChip(
                avatar: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Shiny'),
                selected: _shiny,
                showCheckmark: false,
                onSelected: (v) => setState(() => _shiny = v),
              ),
              FilterChip(
                avatar: const Icon(Icons.stars, size: 18),
                label: const Text('Chanceux'),
                selected: _lucky,
                showCheckmark: false,
                onSelected: (v) => setState(() => _lucky = v),
              ),
              FilterChip(
                avatar: const Icon(Icons.checkroom, size: 18),
                label: const Text('Costume'),
                selected: _costume,
                showCheckmark: false,
                onSelected: (v) => setState(() => _costume = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              widget.onSave(
                SaveOptions(
                  league: _league,
                  fastMove: _fast,
                  chargedMove1: _charged1,
                  chargedMove2: _charged2,
                  shadow: _shadow,
                  size: _size,
                  lucky: _lucky,
                  shiny: _shiny,
                  costume: _costume,
                ),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.bookmark_added),
            label: Text(widget.saveLabel),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _MoveField extends StatelessWidget {
  const _MoveField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<Move> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = options.any((m) => m.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('$label-$current'),
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(child: Text('Aucune')),
        for (final m in options)
          DropdownMenuItem<String>(
            value: m.id,
            child: Row(
              children: <Widget>[
                TypeBadge(m.type, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.nameFr, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
