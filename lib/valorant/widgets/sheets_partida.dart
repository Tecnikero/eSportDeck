import 'package:flutter/material.dart';
import '../core/visual.dart';
import '../core/mecanicas.dart';
import 'cartas_widgets.dart';

// ============================================================================
// ENCABEZADO
// ============================================================================

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

// ============================================================================
// COMBOS TÁCTICOS
// ============================================================================

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

// ============================================================================
// SELECTOR DE AGENTE
// ============================================================================

Future<void> mostrarSelectorAgente({
  required BuildContext context,
  required Map<String, dynamic> carta,
  required String rol,
  required String nombreMapa,
  required List<String?> agentesAsignados,
  required int indiceJugador,
  required void Function(String agente) onElegir,
}) async {
  final agentesDelRol = agentesPorRol[rol] ??
      agentesPorRol.values.expand((lista) => lista).toList();
  final usadosPorOtros = <String>{
    for (var i = 0; i < agentesAsignados.length; i++)
      if (i != indiceJugador && agentesAsignados[i] != null) agentesAsignados[i]!,
  };
  final agentes = agentesDelRol.where((a) => !usadosPorOtros.contains(a)).toList();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16, 20, 16, 30 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: TemaJuego.fondoPanel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: TemaJuego.rojo, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_pin_circle, color: TemaJuego.rojo, size: 26),
            const SizedBox(height: 6),
            Text(
              'AGENTE PARA ${'${carta['nombre'] ?? ''}'.toUpperCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rol: $rol  ·  Mapa: $nombreMapa',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (agentes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No quedan agentes de este rol disponibles: ya están asignados a otros jugadores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: agentes.map((agente) {
                  return GestureDetector(
                    onTap: () {
                      onElegir(agente);
                      Navigator.of(context).pop();
                    },
                    child: SizedBox(
                      width: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: TemaJuego.fondo,
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                rutaAgente(agente),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  color: Colors.white38,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            agente,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    },
  );
}

// ============================================================================
// SELECTOR DE CARTAS
// ============================================================================
class SelectorCartasSheet extends StatefulWidget {
  final List<Map<String, dynamic>> opciones;
  final void Function(Map<String, dynamic>) onElegir;
  final int Function(Map<String, dynamic>)? quimicaPreview;

  const SelectorCartasSheet({
    super.key,
    required this.opciones,
    required this.onElegir,
    this.quimicaPreview,
  });

  @override
  State<SelectorCartasSheet> createState() => _SelectorCartasSheetState();
}

class _SelectorCartasSheetState extends State<SelectorCartasSheet> {
  final List<bool> _visibles = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _visibles.length; i++) {
      Future.delayed(Duration(milliseconds: 160 * i), () {
        if (!mounted) return;
        setState(() => _visibles[i] = true);
      });
    }
  }

  Widget _puntitosPreview(int valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final activo = i < valor;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activo ? TemaJuego.dorado : Colors.transparent,
              border: Border.all(color: activo ? TemaJuego.dorado : Colors.white30, width: 1),
              boxShadow: activo ? [BoxShadow(color: TemaJuego.dorado.withOpacity(0.6), blurRadius: 4)] : null,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anchoDisponible = MediaQuery.of(context).size.width - 32;
    final anchoTarjeta = (anchoDisponible - 12) / 2;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 20, 16, 30 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: TemaJuego.fondoPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: TemaJuego.rojo, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: TemaJuego.rojo, size: 28),
          const SizedBox(height: 6),
          const Text(
            'ELIGE TU JUGADOR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca una carta para agregarla a tu equipo',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _opcionCarta(0, anchoTarjeta),
              _opcionCarta(1, anchoTarjeta),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _opcionCarta(2, anchoTarjeta),
              _opcionCarta(3, anchoTarjeta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcionCarta(int index, double ancho) {
    final carta = widget.opciones[index];
    final visible = _visibles[index];
    final preview = widget.quimicaPreview;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.18),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: visible ? () => widget.onElegir(carta) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TemaJuego.rojo.withOpacity(0.5), width: 1.5),
                ),
                child: SizedBox(
                  width: ancho,
                  child: AspectRatio(
                    aspectRatio: 626 / 794,
                    child: CartaMiniWidget(jugador: carta),
                  ),
                ),
              ),
              if (preview != null) ...[
                const SizedBox(height: 6),
                _puntitosPreview(preview(carta)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}