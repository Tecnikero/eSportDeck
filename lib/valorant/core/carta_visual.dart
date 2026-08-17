import 'jugador_helpers.dart';

const int kUmbralOvrOro = 79;

const Map<String, String> _fondosGrandePorRareza = {
  'icono': 'assets/valorant/cartas/carta_icono.png',
  'heroe': 'assets/valorant/cartas/carta_heroe.png',
  'tos1': 'assets/valorant/cartas/carta_tos1.png',
  'tos2': 'assets/valorant/cartas/carta_tos2.png',
  'flashback': 'assets/valorant/cartas/carta_flashback.png',
  'promesa': 'assets/valorant/cartas/carta_promesa.png',
};

const Map<String, String> _fondosMiniPorRareza = {
  'icono': 'assets/valorant/cartas/carta_icono_mini.png',
  'heroe': 'assets/valorant/cartas/carta_heroe_mini.png',
  // Nota: en la version mini, tos1 y tos2 comparten el mismo asset.
  'tos1': 'assets/valorant/cartas/carta_tos_mini.png',
  'tos2': 'assets/valorant/cartas/carta_tos_mini.png',
  'flashback': 'assets/valorant/cartas/carta_flashback_mini.png',
  'promesa': 'assets/valorant/cartas/carta_promesa_mini.png',
};

const String _normalOroGrande = 'assets/valorant/cartas/carta_normal_oro.png';
const String _normalPlataGrande = 'assets/valorant/cartas/carta_normal_plata.png';
const String _normalOroMini = 'assets/valorant/cartas/carta_normal_oro_mini.png';
const String _normalPlataMini = 'assets/valorant/cartas/carta_normal_plata_mini.png';

/// Ruta al fondo de la carta grande (carta_widget.dart).
String rutaFondoCarta(Jugador j) {
  final rareza = rarezaDe(j);
  if (rareza == 'normal') {
    return ovrDe(j) >= kUmbralOvrOro ? _normalOroGrande : _normalPlataGrande;
  }
  return _fondosGrandePorRareza[rareza] ?? _normalPlataGrande;
}

/// Ruta al fondo de la mini-carta (carta_mini_widget.dart / galeria).
String rutaFondoCartaMini(Jugador j) {
  final rareza = rarezaDe(j);
  if (rareza == 'normal') {
    return ovrDe(j) >= kUmbralOvrOro ? _normalOroMini : _normalPlataMini;
  }
  return _fondosMiniPorRareza[rareza] ?? _normalPlataMini;
}