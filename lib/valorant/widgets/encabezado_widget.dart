import 'package:flutter/material.dart';
import '../core/tema_juego.dart';

/// Encabezado estándar de los bottom sheets de juego (icono + título +
/// subtítulo opcional). Antes duplicado como clase privada en cada pantalla.
class EncabezadoSheet extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Color color;

  const EncabezadoSheet({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.color = TemaJuego.rojo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitulo!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TemaJuego.textoSuave, fontSize: 12.5, height: 1.3),
          ),
        ],
      ],
    );
  }
}
