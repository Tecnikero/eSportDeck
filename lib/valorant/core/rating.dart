import 'jugador_helpers.dart';
import 'quimica.dart';

/// Rating promedio de OVR de un roster, opcionalmente sumando la química.
/// Usado por partida_completa y torneo_partido para decidir el resultado
/// de las rondas.
double ratingEfectivo(List<Jugador> roster, {bool conQuimica = true}) {
  if (roster.isEmpty) return 0;
  final sumaOvr = roster.fold<double>(0, (s, j) => s + ovrDe(j));
  final basePromedio = sumaOvr / roster.length;
  if (!conQuimica) return basePromedio;
  final quimicaTotal = quimicaTotalEquipo(roster);
  return basePromedio + quimicaTotal;
}