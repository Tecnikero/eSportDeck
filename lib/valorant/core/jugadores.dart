/// Helpers puros para leer atributos de un jugador (Map desde Supabase)

typedef Jugador = Map<String, dynamic>;

const List<String> kRolesPrincipales = ['DUE', 'INI', 'CON', 'CEN'];

String rolDe(Jugador j) => '${j['posicion'] ?? ''}'.trim().toUpperCase();
String regionDe(Jugador j) => '${j['region'] ?? ''}'.trim().toLowerCase();
String equipoDe(Jugador j) => '${j['equipo'] ?? ''}'.trim().toLowerCase();
String paisDe(Jugador j) => '${j['pais'] ?? ''}'.trim().toLowerCase();

String rarezaDe(Jugador j) =>
    '${j['rareza'] ?? 'normal'}'.trim().toLowerCase().replaceAll(' ', '_');

bool esIcono(Jugador j) => rarezaDe(j) == 'icono' || rarezaDe(j) == 'icono_prime';
bool esHeroe(Jugador j) => rarezaDe(j) == 'heroe';

int ovrDe(Jugador j) => ((j['ovr'] ?? 0) as num).toInt();

/// Ruta al logo de equipo/héroe/icono
String rutaLogoEquipo(Jugador j) {
  if (esIcono(j)) return 'assets/valorant/equipos/logo/icono.png';
  if (esHeroe(j)) {
    final region = '${j['region'] ?? 'default'}'.toLowerCase();
    return 'assets/valorant/equipos/logo/heroe_$region.png';
  }
  final region = regionDe(j).isEmpty ? 'default' : regionDe(j);
  final equipo = equipoDe(j).isEmpty ? 'default' : equipoDe(j);
  return 'assets/valorant/equipos/$region/$equipo.png';
}

bool tieneBandera(Jugador j) => paisDe(j).isNotEmpty;
String rutaBandera(Jugador j) => 'assets/banderas/${paisDe(j)}.png';