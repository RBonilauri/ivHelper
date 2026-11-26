import 'package:material_ui/material_ui.dart';

/// Petit « i » : un appui affiche [message] dans une bulle, qui se ferme au
/// prochain appui ailleurs. Remplace les phrases d'explication affichées en
/// permanence.
class InfoButton extends StatelessWidget {
  /// Crée le bouton d'information.
  const InfoButton(this.message, {super.key, this.size = 20});

  /// Texte de la bulle.
  final String message;

  /// Taille de l'icône.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 30),
      preferBelow: true,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onInverseSurface,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.info_outline,
          size: size,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
