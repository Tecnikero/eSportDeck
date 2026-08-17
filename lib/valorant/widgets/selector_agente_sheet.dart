import 'package:flutter/material.dart';
import '../core/tema_juego.dart';
import '../core/catalogos_juego.dart';

/// Bottom sheet para elegir el agente de un jugador según su rol, evitando
/// agentes ya asignados a otros jugadores del roster.
/// Antes duplicado en partida_rapida, partida_completa y torneo_partido.
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
