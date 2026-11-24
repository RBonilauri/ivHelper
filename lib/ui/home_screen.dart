import 'package:material_ui/material_ui.dart';

import '../core/species_repository.dart';
import '../core/stats.dart';
import '../settings/settings_controller.dart';
import '../state/lookup_controller.dart';
import 'iv_logo.dart';
import 'result_panel.dart';
import 'settings_drawer.dart';

/// Écran unique : saisie de l'espèce et des IV, résultats Super et Hyper.
class HomeScreen extends StatefulWidget {
  /// Crée l'écran à partir du [repository] d'espèces.
  const HomeScreen({
    super.key,
    required this.repository,
    required this.settings,
  });

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Réglages d'affichage, modifiables depuis la barre latérale.
  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LookupController _controller =
      LookupController(widget.repository);
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            IvLogo(size: 34),
            SizedBox(width: 10),
            Text('ivHelper', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Paramètres',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: SettingsDrawer(settings: widget.settings),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextField(
                controller: _text,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Pokémon (nom ou numéro)',
                  hintText: 'Flambusard ou 663',
                  border: OutlineInputBorder(),
                ),
                onChanged: _controller.setQuery,
              ),
              ..._suggestions(),
              const SizedBox(height: 12),
              _ivRow(),
              const SizedBox(height: 12),
              SegmentedButton<double>(
                segments: const <ButtonSegment<double>>[
                  ButtonSegment<double>(value: 50, label: Text('Max 50')),
                  ButtonSegment<double>(
                    value: 51,
                    label: Text('Max 51 (ami)'),
                  ),
                ],
                selected: <double>{_controller.maxLevel},
                onSelectionChanged: (selection) =>
                    _controller.setMaxLevel(selection.first),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 0, label: Text('Tous les IV')),
                  ButtonSegment<int>(
                    value: 10,
                    label: Text('Min 10/10/10'),
                  ),
                ],
                selected: <int>{_controller.minIv},
                onSelectionChanged: (selection) =>
                    _controller.setMinIv(selection.first),
              ),
              const SizedBox(height: 16),
              ..._results(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _suggestions() {
    if (_controller.species != null || !_controller.hasUnknownQuery) {
      return const <Widget>[];
    }
    final suggestions = _controller.suggestions;
    if (suggestions.isEmpty) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Espèce inconnue'),
        ),
      ];
    }
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: <Widget>[
            for (final s in suggestions)
              ActionChip(
                label: Text(s.nameFr),
                onPressed: () {
                  _controller.selectSpecies(s);
                  _text.text = s.nameFr;
                },
              ),
          ],
        ),
      ),
    ];
  }

  Widget _ivRow() {
    final iv = _controller.iv;
    return Row(
      children: <Widget>[
        Expanded(
          child: _IvStepper(
            label: 'Atk',
            value: iv.atk,
            min: _controller.minIv,
            onChanged: (v) => _controller.setIv(Iv(v, iv.def, iv.sta)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _IvStepper(
            label: 'Déf',
            value: iv.def,
            min: _controller.minIv,
            onChanged: (v) => _controller.setIv(Iv(iv.atk, v, iv.sta)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _IvStepper(
            label: 'PV',
            value: iv.sta,
            min: _controller.minIv,
            onChanged: (v) => _controller.setIv(Iv(iv.atk, iv.def, v)),
          ),
        ),
      ],
    );
  }

  List<Widget> _results(BuildContext context) {
    final species = _controller.species;
    final result = _controller.result;
    if (species == null || result == null) return const <Widget>[];
    return <Widget>[
      Text(
        '${species.nameFr} · n° ${species.dex}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      ResultPanel(species: species, result: result),
    ];
  }
}

class _IvStepper extends StatelessWidget {
  const _IvStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          Text(label, style: theme.textTheme.labelSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                tooltip: 'Diminuer $label',
                visualDensity: VisualDensity.compact,
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$value', style: theme.textTheme.titleMedium),
              IconButton(
                tooltip: 'Augmenter $label',
                visualDensity: VisualDensity.compact,
                onPressed: value < 15 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
