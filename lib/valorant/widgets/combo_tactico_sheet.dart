import 'package:flutter/material.dart';
import '../core/tema_juego.dart';
import '../core/catalogos_juego.dart';
import '../core/combos.dart';
import 'encabezado_widget.dart';

/// Bottom sheet de "COMBOS TÁCTICOS" (identidades de composición + sinergias
/// de agentes). Antes duplicado casi al carácter en partida_rapida,
/// partida_completa y torneo_partido_screenv.dart.
Future<void> mostrarComboTactico(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: EdgeInsets.fromLTRB(
          16, 20, 16, 24 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: TemaJuego.fondoPanel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: TemaJuego.rojo, width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const EncabezadoSheet(
                icono: Icons.tips_and_updates,
                titulo: 'COMBOS TÁCTICOS',
                subtitulo: 'Estos combos suman puntos a tu OVR total según el lado.',
              ),
              const SizedBox(height: 16),
              const Text(
                'IDENTIDAD DE COMPOSICIÓN (ATK / DEF)',
                style: TextStyle(color: TemaJuego.dorado, fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              ...identidadesComposicion.map((c) => _filaComboDinamico(c)),
              const SizedBox(height: 18),
              const Text(
                'SINERGIAS DE AGENTES (GLOBAL)',
                style: TextStyle(color: TemaJuego.cian, fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              ...sinergiasAgentes.map((s) => _filaComboEstatico(s, cian: true)),
            ],
          ),
        ),
      );
    },
  );
}

Widget _filaComboDinamico(Map<String, dynamic> combo) {
  final atk = (combo['bonoAtaque'] as num).toDouble();
  final def = (combo['bonoDefensa'] as num).toDouble();
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.groups, color: TemaJuego.dorado, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${combo['nombre']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                '${combo['descripcion']}',
                style: const TextStyle(color: TemaJuego.textoSuave, fontSize: 11.5, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ATK ${atk >= 0 ? '+' : ''}${formatoBono(atk)}',
              style: TextStyle(color: atk >= 0 ? TemaJuego.ataque : TemaJuego.textoSuave, fontWeight: FontWeight.w900, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              'DEF ${def >= 0 ? '+' : ''}${formatoBono(def)}',
              style: TextStyle(color: def >= 0 ? TemaJuego.defensa : TemaJuego.textoSuave, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ],
        )
      ],
    ),
  );
}

Widget _filaComboEstatico(Map<String, dynamic> combo, {bool cian = false}) {
  final color = cian ? TemaJuego.cian : TemaJuego.dorado;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${combo['nombre']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                '${combo['descripcion']}',
                style: const TextStyle(color: TemaJuego.textoSuave, fontSize: 11.5, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '+0.5',
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12.5),
        ),
      ],
    ),
  );
}