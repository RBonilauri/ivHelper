import 'package:material_ui/material_ui.dart';

/// Logo « iv » dont le point du i est une pokéball.
///
/// Dessin sur une grille de 100 × 100, identique à celui de l'icône Android
/// générée par `tool/build_icon.py`.
class IvLogo extends StatelessWidget {
  /// Crée le logo à la taille [size].
  const IvLogo({super.key, this.size = 32, this.withBackground = true});

  /// Côté du logo en pixels logiques.
  final double size;

  /// Vrai pour dessiner le carré jaune arrondi derrière les lettres.
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _IvLogoPainter(withBackground: withBackground),
      ),
    );
  }
}

class _IvLogoPainter extends CustomPainter {
  const _IvLogoPainter({required this.withBackground});

  final bool withBackground;

  static const Color _yellow = Color(0xFFFFCB05);
  static const Color _navy = Color(0xFF1D2A5B);
  static const Color _red = Color(0xFFE53935);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    if (withBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 100),
          const Radius.circular(22),
        ),
        Paint()..color = _yellow,
      );
    }
    final letters = Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Hampe du i.
    canvas.drawLine(const Offset(28, 52), const Offset(28, 80), letters);
    // V.
    final v = Path()
      ..moveTo(46, 50)
      ..lineTo(62, 80)
      ..lineTo(78, 50);
    canvas.drawPath(v, letters);
    _pokeball(canvas, const Offset(28, 27), 14);
    canvas.restore();
  }

  void _pokeball(Canvas canvas, Offset c, double r) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, 3.14159265, 3.14159265, true, Paint()..color = _red);
    canvas.drawArc(rect, 0, 3.14159265, true, Paint()..color = Colors.white);
    final line = Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, line);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), line);
    canvas.drawCircle(c, r * 0.36, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.36, line..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_IvLogoPainter oldDelegate) =>
      oldDelegate.withBackground != withBackground;
}
