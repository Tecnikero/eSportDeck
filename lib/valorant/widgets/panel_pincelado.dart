import 'dart:math';
import 'package:flutter/material.dart';

class CortesDiagonalesClipper extends CustomClipper<Path> {
  final double corte;

  const CortesDiagonalesClipper({this.corte = 16});

  @override
  Path getClip(Size size) {
    final c = min(corte, min(size.width, size.height) / 2.2);
    final path = Path();
    path.moveTo(c, 0);
    path.lineTo(size.width - c * 0.55, 0);
    path.lineTo(size.width, c);
    path.lineTo(size.width, size.height - c * 0.55);
    path.lineTo(size.width - c, size.height);
    path.lineTo(c * 0.55, size.height);
    path.lineTo(0, size.height - c);
    path.lineTo(0, c * 0.55);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PinceladaBorderPainter extends CustomPainter {
  final double corte;
  final Color color;
  final double grosor;
  final int seed;

  _PinceladaBorderPainter({
    required this.corte,
    required this.color,
    required this.grosor,
    this.seed = 7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = min(corte, min(size.width, size.height) / 2.2);
    final base = Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c * 0.55, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c * 0.55)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c * 0.55, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c * 0.55)
      ..close();

    final rnd = Random(seed);

    final paintPrincipal = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(base, paintPrincipal);

    final paintTextura = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor * 0.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final metrics = base.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      double dist = 0;
      final segPath = Path();
      bool moved = false;
      while (dist < length) {
        final segLen = 6 + rnd.nextDouble() * 10;
        final tang = metric.getTangentForOffset(dist);
        if (tang != null) {
          final jitter = (rnd.nextDouble() - 0.5) * grosor * 0.9;
          final nx = -tang.vector.dy;
          final ny = tang.vector.dx;
          final len = sqrt(nx * nx + ny * ny);
          final off = len == 0
              ? Offset.zero
              : Offset(nx / len * jitter, ny / len * jitter);
          final p = tang.position + off;
          if (!moved) {
            segPath.moveTo(p.dx, p.dy);
            moved = true;
          } else {
            segPath.lineTo(p.dx, p.dy);
          }
        }
        dist += segLen;
        if (rnd.nextDouble() < 0.18) {
          dist += 4 + rnd.nextDouble() * 6;
          moved = false;
        }
      }
      canvas.drawPath(segPath, paintTextura);
    }
  }

  @override
  bool shouldRepaint(covariant _PinceladaBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.grosor != grosor;
}

class PanelPincelado extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color colorBase;
  final Color colorAcento;
  final double corte;
  final double grosorBorde;
  final Gradient? gradiente;
  final EdgeInsetsGeometry? padding;
  final int seed;

  const PanelPincelado({
    super.key,
    required this.child,
    this.onTap,
    this.colorBase = const Color(0xFF1C1E22),
    this.colorAcento = const Color(0xFFC7CBD1),
    this.corte = 16,
    this.grosorBorde = 2.4,
    this.gradiente,
    this.padding,
    this.seed = 7,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CortesDiagonalesClipper(corte: corte),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: gradiente ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorBase.withOpacity(0.95),
                      colorBase.withOpacity(0.75),
                    ],
                  ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: colorAcento.withOpacity(0.10),
                highlightColor: Colors.white.withOpacity(0.04),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PinceladaBorderPainter(
                  corte: corte,
                  color: colorAcento,
                  grosor: grosorBorde,
                  seed: seed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
