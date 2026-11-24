import 'package:material_ui/material_ui.dart';

/// Champ de recherche avec une croix pour effacer le texte.
///
/// La croix n'apparaît que s'il y a du texte ; l'effacement appelle
/// [onChanged] avec une chaîne vide, comme si l'utilisateur avait tout
/// supprimé. Le texte indicatif (gris, italique) vient du thème.
class SearchField extends StatefulWidget {
  /// Crée le champ ; [controller] et [focusNode] sont facultatifs.
  const SearchField({
    required this.label,
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.dense = false,
  });

  /// Étiquette, affichée en indication quand le champ est vide.
  final String label;

  /// Exemple affiché pendant la saisie.
  final String? hint;

  /// Contrôleur du texte (sinon le champ crée le sien).
  final TextEditingController? controller;

  /// Focus du champ.
  final FocusNode? focusNode;

  /// Texte de départ, si le champ crée son contrôleur.
  final String? initialValue;

  /// Appelé à chaque changement, y compris l'effacement par la croix.
  final ValueChanged<String>? onChanged;

  /// Appelé à la validation au clavier.
  final ValueChanged<String>? onSubmitted;

  /// Champ compact.
  final bool dense;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ??
      (_own ??= TextEditingController(text: widget.initialValue));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextField(
        controller: controller,
        focusNode: widget.focusNode,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search),
          isDense: widget.dense,
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey<String>('clear-search'),
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.close),
                  onPressed: _clear,
                ),
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
