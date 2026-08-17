import 'jugador_helpers.dart';

/// Cálculo de química de un roster.
///
/// ⚠️ Antes del refactor existían DOS fórmulas distintas:
/// - partida_rapida_screenv.dart usaba un match simple de país/región/equipo
///   (máximo 3 puntos, sin bono de Héroe ni de balance de roles).
/// - partida_completa_screenv.dart y torneo_partido_screenv.dart usaban este
///   sistema de "objetivos" (con bono extra para Héroe y bono de balance).
///
/// Se unificó todo bajo esta versión (la más completa) para que la química
/// signifique lo mismo en todos los modos de juego.
int quimicaDeCarta(Jugador carta, List<Jugador> roster) {
  if (esIcono(carta)) return 3;

  var objetivos = 0;

  final rolesPresentes = roster.map(rolDe).toSet();
  final balance = roster.length >= 4 &&
      kRolesPrincipales.every(rolesPresentes.contains);
  if (balance) objetivos += 1;

  final region = regionDe(carta);
  final soyHeroe = esHeroe(carta);

  bool companerosDeRegion(Jugador j) {
    if (identical(j, carta)) return false;
    if (soyHeroe) return regionDe(j) == region;
    return regionDe(j) == region || (esHeroe(j) && regionDe(j) == region);
  }

  if (region.isNotEmpty && roster.any(companerosDeRegion)) {
    objetivos += 1;
    if (soyHeroe) objetivos += 1;
  }

  if (!soyHeroe) {
    final equipo = equipoDe(carta);
    bool companerosDeEquipo(Jugador j) {
      if (identical(j, carta)) return false;
      if (esHeroe(j)) return regionDe(j) == region;
      return equipoDe(j) == equipo;
    }
    if (equipo.isNotEmpty && roster.any(companerosDeEquipo)) objetivos += 1;
  }

  final pais = paisDe(carta);
  bool companerosDePais(Jugador j) {
    if (identical(j, carta)) return false;
    return paisDe(j) == pais;
  }
  if (pais.isNotEmpty && roster.any(companerosDePais)) objetivos += 1;

  return objetivos;
}

/// Química total sumando cada carta del roster contra el resto del roster.
int quimicaTotalEquipo(List<Jugador> roster) {
  if (roster.isEmpty) return 0;
  return roster.fold<int>(0, (s, j) => s + quimicaDeCarta(j, roster));
}

/// Química que tendría una carta si se agregara al roster actual (para
/// mostrar el "preview" en el selector de cartas antes de confirmar).
int quimicaSiSeElige(Jugador carta, List<Jugador> rosterActual) =>
    quimicaDeCarta(carta, [...rosterActual, carta]);