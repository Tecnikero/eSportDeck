/// Catálogos estáticos del juego (agentes, identidades de composición,
/// sinergias y mapas). Antes estaban copiados y pegados en
/// partida_rapida, partida_completa y torneo_partido_screenv.dart.

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

/// Ruta a la imagen de un agente.
String rutaAgente(String agente) {
  final archivo = agente.toLowerCase().replaceAll('/', '').replaceAll(' ', '_');
  return 'assets/valorant/agentes/$archivo.png';
}