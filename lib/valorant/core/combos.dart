import 'catalogos_juego.dart';
import 'jugador_helpers.dart';

/// Lógica pura de "combos tácticos": identidades de composición de roster
/// (p.ej. Doble Controlador) y sinergias entre agentes elegidos.
/// Antes duplicado en partida_rapida, partida_completa y torneo_partido.

/// Identidades de composición activas para un roster dado.
List<Map<String, dynamic>> identidadesActivas(List<Jugador> roster) {
  if (roster.isEmpty) return const [];
  final conteoPorRol = <String, int>{};
  for (final j in roster) {
    final rol = rolDe(j);
    conteoPorRol[rol] = (conteoPorRol[rol] ?? 0) + 1;
  }
  return identidadesComposicion.where((identidad) {
    final rol = identidad['rol'] as String;
    final cantidad = identidad['cantidad'] as int;
    return (conteoPorRol[rol] ?? 0) >= cantidad;
  }).toList();
}

/// Bono total (ataque o defensa) que aportan las identidades activas.
double bonoIdentidad(List<Jugador> roster, bool atacando) {
  final activas = identidadesActivas(roster);
  return activas.fold<double>(
      0.0, (s, id) => s + (atacando ? id['bonoAtaque'] : id['bonoDefensa']));
}

/// Sinergias de agentes activas dado el set de agentes ya asignados.
List<Map<String, dynamic>> sinergiasActivas(List<String?> agentesAsignados) {
  final agentesElegidos = agentesAsignados.whereType<String>().toSet();
  return sinergiasAgentes.where((sinergia) {
    final par = (sinergia['par'] as List).cast<String>();
    return par.every(agentesElegidos.contains);
  }).toList();
}

/// Bono total que aportan las sinergias de agentes activas (0.5 c/u).
double bonoSinergiaAgentes(List<String?> agentesAsignados) =>
    sinergiasActivas(agentesAsignados).length * 0.5;

String formatoBono(double valor) =>
    valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toStringAsFixed(1);