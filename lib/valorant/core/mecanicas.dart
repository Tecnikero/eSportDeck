import 'jugadores.dart';

// ============================================================================
// CATÁLOGOS ESTÁTICOS DEL JUEGO
// ============================================================================

const Map<String, List<String>> agentesPorRol = {
  'DUE': ['Jett', 'Reyna', 'Phoenix', 'Raze', 'Yoru', 'Neon', 'Iso'],
  'INI': ['Sova', 'Breach', 'Skye', 'KAY/O', 'Fade', 'Gekko'],
  'CON': ['Omen', 'Brimstone', 'Viper', 'Astra', 'Harbor', 'Clove'],
  'CEN': ['Killjoy', 'Cypher', 'Sage', 'Chamber', 'Deadlock', 'Vyse'],
};

const List<Map<String, dynamic>> identidadesComposicion = [
  {
    'nombre': 'Doble Controlador',
    'rol': 'CON',
    'cantidad': 2,
    'bonoAtaque': 1.0,
    'bonoDefensa': 1.5,
    'descripcion': 'Doble humo: control total del sitio y visión. Mejor en defensa.',
  },
  {
    'nombre': 'Doble Centinela',
    'rol': 'CEN',
    'cantidad': 2,
    'bonoAtaque': -1.0,
    'bonoDefensa': 3.0,
    'descripcion': 'Doble anti-flanco: sitio inexpugnable, lentos para entrar.',
  },
  {
    'nombre': 'Doble Duelista',
    'rol': 'DUE',
    'cantidad': 2,
    'bonoAtaque': 3.0,
    'bonoDefensa': -1.0,
    'descripcion': 'Doble entry: presión constante, pero débiles para holdear.',
  },
  {
    'nombre': 'Doble Iniciador',
    'rol': 'INI',
    'cantidad': 2,
    'bonoAtaque': 2.0,
    'bonoDefensa': 0.5,
    'descripcion': 'Mucha información para ejecuciones organizadas.',
  },
];

const List<Map<String, dynamic>> sinergiasAgentes = [
  {
    'par': ['Fade', 'Raze'],
    'nombre': 'Fade + Raze',
    'descripcion': 'Fade marca al enemigo y Raze remata con su utilidad explosiva.',
  },
  {
    'par': ['Sova', 'Breach'],
    'nombre': 'Sova + Breach',
    'descripcion': 'Recon perfecto: información y aturdimiento para iniciar el sitio.',
  },
  {
    'par': ['Omen', 'Jett'],
    'nombre': 'Omen + Jett',
    'descripcion': 'Humo ciega la línea y Jett entra a máxima velocidad.',
  },
  {
    'par': ['Killjoy', 'Cypher'],
    'nombre': 'Killjoy + Cypher',
    'descripcion': 'Doble red de información: el sitio queda imposible de retomar.',
  },
  {
    'par': ['Breach', 'Raze'],
    'nombre': 'Breach + Raze',
    'descripcion': 'Aturdimiento más explosivos: limpieza total antes de entrar.',
  },
  {
    'par': ['Viper', 'Killjoy'],
    'nombre': 'Viper + Killjoy',
    'descripcion': 'Veneno más trampas: la zona se vuelve territorio hostil.',
  },
];

const List<Map<String, String>> mapasValorant = [
  {'nombre': 'Abyss', 'imagen': 'assets/valorant/mapas/abyss.png'},
  {'nombre': 'Ascent', 'imagen': 'assets/valorant/mapas/ascent.png'},
  {'nombre': 'Bind', 'imagen': 'assets/valorant/mapas/bind.png'},
  {'nombre': 'Breeze', 'imagen': 'assets/valorant/mapas/breeze.png'},
  {'nombre': 'Corrode', 'imagen': 'assets/valorant/mapas/corrode.png'},
  {'nombre': 'Fracture', 'imagen': 'assets/valorant/mapas/fracture.png'},
  {'nombre': 'Haven', 'imagen': 'assets/valorant/mapas/haven.png'},
  {'nombre': 'Icebox', 'imagen': 'assets/valorant/mapas/icebox.png'},
  {'nombre': 'Lotus', 'imagen': 'assets/valorant/mapas/lotus.png'},
  {'nombre': 'Pearl', 'imagen': 'assets/valorant/mapas/pearl.png'},
  {'nombre': 'Split', 'imagen': 'assets/valorant/mapas/split.png'},
  {'nombre': 'Summit', 'imagen': 'assets/valorant/mapas/summit.png'},
  {'nombre': 'Sunset', 'imagen': 'assets/valorant/mapas/sunset.png'},
];

String rutaAgente(String agente) {
  final archivo = agente.toLowerCase().replaceAll('/', '').replaceAll(' ', '_');
  return 'assets/valorant/agentes/$archivo.png';
}

// ============================================================================
// COMBOS TÁCTICOS
// ============================================================================

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

double bonoIdentidad(List<Jugador> roster, bool atacando) {
  final activas = identidadesActivas(roster);
  return activas.fold<double>(
      0.0, (s, id) => s + (atacando ? id['bonoAtaque'] : id['bonoDefensa']));
}

List<Map<String, dynamic>> sinergiasActivas(List<String?> agentesAsignados) {
  final agentesElegidos = agentesAsignados.whereType<String>().toSet();
  return sinergiasAgentes.where((sinergia) {
    final par = (sinergia['par'] as List).cast<String>();
    return par.every(agentesElegidos.contains);
  }).toList();
}

double bonoSinergiaAgentes(List<String?> agentesAsignados) =>
    sinergiasActivas(agentesAsignados).length * 0.5;

String formatoBono(double valor) =>
    valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toStringAsFixed(1);

// ============================================================================
// QUÍMICA
// ============================================================================

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

int quimicaTotalEquipo(List<Jugador> roster) {
  if (roster.isEmpty) return 0;
  return roster.fold<int>(0, (s, j) => s + quimicaDeCarta(j, roster));
}

int quimicaSiSeElige(Jugador carta, List<Jugador> rosterActual) =>
    quimicaDeCarta(carta, [...rosterActual, carta]);

// ============================================================================
// RATING
// ============================================================================

double ratingEfectivo(List<Jugador> roster, {bool conQuimica = true}) {
  if (roster.isEmpty) return 0;
  final sumaOvr = roster.fold<double>(0, (s, j) => s + ovrDe(j));
  final basePromedio = sumaOvr / roster.length;
  if (!conQuimica) return basePromedio;
  final quimicaTotal = quimicaTotalEquipo(roster);
  return basePromedio + quimicaTotal;
}