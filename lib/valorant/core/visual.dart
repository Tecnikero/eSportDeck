import 'package:flutter/material.dart';

import 'jugadores.dart';

// ============================================================================
// TEMA
// ============================================================================

class TemaJuego {
  static const Color fondo = Color(0xFF0A0A0A);
  static const Color fondoPanel = Color(0xFF1A0E0E);
  static const Color rojo = Color(0xFFE30425);
  static const Color rojoOscuro = Color(0xFF7A0000);
  static const Color dorado = Color(0xFFFFD700);
  static const Color textoSuave = Color(0xFFB9B4B4);
  static const Color borde = Color(0x33FFFFFF);
  static const Color cian = Color(0xFF29E0E0);
  static const Color ataque = Color(0xFFFF4B4B);
  static const Color defensa = Color(0xFF4B9CFF);
}

// ============================================================================
// CARTAS
// ============================================================================

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
  'tos1': 'assets/valorant/cartas/carta_tos_mini.png',
  'tos2': 'assets/valorant/cartas/carta_tos_mini.png',
  'flashback': 'assets/valorant/cartas/carta_flashback_mini.png',
  'promesa': 'assets/valorant/cartas/carta_promesa_mini.png',
};

const String _normalOroGrande = 'assets/valorant/cartas/carta_normal_oro.png';
const String _normalPlataGrande = 'assets/valorant/cartas/carta_normal_plata.png';
const String _normalOroMini = 'assets/valorant/cartas/carta_normal_oro_mini.png';
const String _normalPlataMini = 'assets/valorant/cartas/carta_normal_plata_mini.png';

/// Ruta al fondo de la carta grande.
String rutaFondoCarta(Jugador j) {
  final rareza = rarezaDe(j);
  if (rareza == 'normal') {
    return ovrDe(j) >= kUmbralOvrOro ? _normalOroGrande : _normalPlataGrande;
  }
  return _fondosGrandePorRareza[rareza] ?? _normalPlataGrande;
}

/// Ruta al fondo de la mini-carta.
String rutaFondoCartaMini(Jugador j) {
  final rareza = rarezaDe(j);
  if (rareza == 'normal') {
    return ovrDe(j) >= kUmbralOvrOro ? _normalOroMini : _normalPlataMini;
  }
  return _fondosMiniPorRareza[rareza] ?? _normalPlataMini;
}