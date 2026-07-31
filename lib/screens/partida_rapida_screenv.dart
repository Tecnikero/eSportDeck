import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/carta_widget.dart';

const List<String> _rolesPrincipales = ['DUE', 'INI', 'CON', 'CEN'];

const Color _kFondo = Color(0xFF0A0A0A);
const Color _kFondoPanel = Color(0xFF1A0E0E);
const Color _kRojo = Color(0xFFE30425);
const Color _kRojoOscuro = Color(0xFF7A0000);
const Color _kDorado = Color(0xFFFFD700);
const Color _kTextoSuave = Color(0xFFB9B4B4);
const Color _kBorde = Color(0x33FFFFFF);

/// Contenedor base reutilizado por todas las tarjetas de esta pantalla,
/// para que la interfaz se vea consistente y simple.
class _Tarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borde;

  const _Tarjeta({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borde = _kBorde,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _kFondoPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borde),
      ),
      child: child,
    );
  }
}

/// Encabezado simple y reutilizable: ícono + título + subtítulo opcional.
class _Encabezado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Color color;

  const _Encabezado({
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.color = _kRojo,
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
            style: const TextStyle(color: _kTextoSuave, fontSize: 12.5, height: 1.3),
          ),
        ],
      ],
    );
  }
}

/// Botón principal reutilizado por las tres pantallas de esta vista.
class _BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;

  const _BotonPrincipal({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kRojo,
          disabledBackgroundColor: Colors.white12,
          elevation: activo ? 4 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(
          texto,
          style: TextStyle(
            color: activo ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

const List<String> _eventosPositivos = [
  '{jugador} consiguió un 3K',
  '{jugador} clucheó la ronda en 1v2',
  '{jugador} plantó la spike bajo presión',
  '{jugador} abrió el sitio con el primer pick',
  '{jugador} rotó a tiempo y ganó el retake',
  '{jugador} hizo un ace',
  '{jugador} defusó justo a tiempo',
  '{jugador} leyó la utilidad rival a la perfección',
];
const List<String> _eventosNegativos = [
  '{jugador} no alcanzó a defusar',
  '{jugador} cayó en el primer contacto',
  '{jugador} gastó la utilidad muy pronto',
  '{jugador} perdió el duelo clave',
  '{jugador} no pudo cerrar el retake',
  '{jugador} quedó atrapado fuera de posición',
  '{jugador} falló el último disparo del round',
  '{jugador} no llegó a tiempo al sitio',
];

enum _FaseJuego { draft, agentes, simulando, resultado }

const Map<String, List<String>> _agentesPorRol = {
  'DUE': ['Jett', 'Reyna', 'Phoenix', 'Raze', 'Yoru', 'Neon', 'Iso'],
  'INI': ['Sova', 'Breach', 'Skye', 'KAY/O', 'Fade', 'Gekko'],
  'CON': ['Omen', 'Brimstone', 'Viper', 'Astra', 'Harbor', 'Clove'],
  'CEN': ['Killjoy', 'Cypher', 'Sage', 'Chamber', 'Deadlock', 'Vyse'],
};

const Map<String, List<String>> _agentesFuertesPorMapa = {
  'Abyss': ['Gekko', 'Omen', 'Killjoy', 'Sova'],
  'Ascent': ['Jett', 'Omen', 'Killjoy', 'Fade'],
  'Bind': ['Raze', 'Brimstone', 'Cypher', 'Skye'],
  'Breeze': ['Viper', 'Sova', 'Jett', 'Chamber'],
  'Corrode': ['Vyse', 'Sova', 'Omen', 'Breach'],
  'Fracture': ['Raze', 'Breach', 'KAY/O', 'Cypher'],
  'Haven': ['Breach', 'Astra', 'KAY/O', 'Sova'],
  'Lotus': ['Viper', 'Killjoy', 'Neon', 'Gekko'],
  'Pearl': ['Viper', 'Astra', 'Cypher', 'Fade'],
  'Split': ['Raze', 'Cypher', 'Breach', 'Omen'],
  'Summit': ['Omen', 'Sova', 'Jett', 'Killjoy'],
  'Sunset': ['Jett', 'Astra', 'Killjoy', 'Fade'],
  'Icebox': ['Sova', 'Viper', 'Chamber', 'Skye'],
};

const List<Map<String, String>> _mapasValorant = [
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

class PartidaRapidaScreen extends StatefulWidget {
  const PartidaRapidaScreen({super.key});

  @override
  State<PartidaRapidaScreen> createState() => _PartidaRapidaScreenState();
}

class _PartidaRapidaScreenState extends State<PartidaRapidaScreen> {
  final supabase = Supabase.instance.client;
  final _random = Random();

  _FaseJuego _fase = _FaseJuego.draft;
  String? _error;

  final List<Map<String, dynamic>?> _casillas =
      List<Map<String, dynamic>?>.filled(5, null);
  bool _revelando = false;
  int? _casillaEnRevelacion;
  List<Map<String, dynamic>> _opcionesActuales = [];

  List<Map<String, dynamic>> get _seleccionados =>
      _casillas.whereType<Map<String, dynamic>>().toList();

  List<Map<String, dynamic>> _rosterRival = [];
  Map<String, String>? _mapaActual;

  final List<String?> _agentesAsignados = List<String?>.filled(5, null);
  int _bonoSinergia = 0;

  static const int _rondasParaGanar = 5;
  int _rondasJugador = 0;
  int _rondasIA = 0;
  int _rondaActual = 0;
  final List<bool> _historialRondas = [];
  final List<Map<String, dynamic>> _timelineEventos = [];
  bool _resolviendoRonda = false;

  Map<String, dynamic>? _rondaEnVivo;

  bool _victoria = false;
  int _monedasGanadas = 0;
  Map<String, dynamic>? _mvp;

  Future<void> _abrirCasilla(int index) async {
    if (_casillas[index] != null || _revelando) return;

    setState(() {
      _revelando = true;
      _casillaEnRevelacion = index;
      _error = null;
    });

    try {
      final catalogo = await supabase.from('jugadores').select();
      var pool = List<Map<String, dynamic>>.from(catalogo as List);

      final idsEnEquipo = _seleccionados.map((j) => j['id']).toSet();
      pool.removeWhere((j) => idsEnEquipo.contains(j['id']));

      if (pool.length < 4) {
        throw Exception('No hay suficientes jugadores en el catálogo.');
      }

      pool.shuffle(_random);
      final opciones = pool.take(4).toList();

      if (!mounted) return;
      setState(() {
        _opcionesActuales = opciones;
        _revelando = false;
      });

      if (!mounted) return;
      await _mostrarSelectorCartas(index);
    } catch (e) {
      debugPrint('ERROR AL REVELAR CASILLA: $e');
      if (!mounted) return;
      setState(() {
        _revelando = false;
        _casillaEnRevelacion = null;
        _error = 'No se pudieron cargar jugadores del catálogo.';
      });
    }
  }

  Future<void> _mostrarSelectorCartas(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return _SelectorCartasSheet(
          opciones: _opcionesActuales,
          onElegir: (carta) => _elegirCarta(index, carta),
          quimicaPreview: _quimicaSiSeElige,
        );
      },
    );
  }

  void _elegirCarta(int index, Map<String, dynamic> carta) {
    setState(() {
      _casillas[index] = carta;
      _casillaEnRevelacion = null;
      _opcionesActuales = [];
    });
    Navigator.of(context).pop();
  }

  void _reiniciarDraft() {
    setState(() {
      for (var i = 0; i < _casillas.length; i++) {
        _casillas[i] = null;
      }
      _error = null;
    });
  }

  // ---------- QUÍMICA ----------

  String _rol(Map<String, dynamic> j) => '${j['posicion'] ?? ''}'.trim().toUpperCase();
  String _region(Map<String, dynamic> j) => '${j['region'] ?? ''}'.trim().toLowerCase();
  String _equipo(Map<String, dynamic> j) => '${j['equipo'] ?? ''}'.trim().toLowerCase();

  bool get _balanceDeRoles {
    if (_seleccionados.length < 4) return false;
    final rolesPresentes = _seleccionados.map(_rol).toSet();
    return _rolesPrincipales.every(rolesPresentes.contains);
  }

  int _quimicaEnRoster(Map<String, dynamic> carta, List<Map<String, dynamic>> roster) {
    var puntos = 0;

    final rolesPresentes = roster.map(_rol).toSet();
    final balance = roster.length >= 4 && _rolesPrincipales.every(rolesPresentes.contains);
    if (balance) puntos += 1;

    final region = _region(carta);
    if (region.isNotEmpty && roster.where((j) => _region(j) == region).length > 1) {
      puntos += 1;
    }

    final equipo = _equipo(carta);
    if (equipo.isNotEmpty && roster.where((j) => _equipo(j) == equipo).length > 1) {
      puntos += 1;
    }

    return puntos;
  }

  int _quimicaDeCarta(Map<String, dynamic> carta) => _quimicaEnRoster(carta, _seleccionados);

  int _quimicaSiSeElige(Map<String, dynamic> carta) =>
      _quimicaEnRoster(carta, [..._seleccionados, carta]);

  int get _quimicaTotalPromedio {
    if (_seleccionados.isEmpty) return 0;
    final suma = _seleccionados.fold<int>(0, (s, j) => s + _quimicaDeCarta(j));
    return (suma / _seleccionados.length).round();
  }

  double _ratingEfectivo(List<Map<String, dynamic>> roster, {bool conQuimica = true}) {
    if (roster.isEmpty) return 0;
    final suma = roster.fold<double>(0, (s, j) {
      final ovr = (j['ovr'] ?? 0) as num;
      final quimica = conQuimica ? _quimicaDeCarta(j) : 0;
      return s + ovr + quimica;
    });
    return suma / roster.length;
  }

  int _rachaActual(bool paraJugador) {
    var racha = 0;
    for (var i = _historialRondas.length - 1; i >= 0; i--) {
      final ganoJugador = _historialRondas[i];
      if (paraJugador ? ganoJugador : !ganoJugador) {
        racha++;
      } else {
        break;
      }
    }
    return racha;
  }

  int _bonificacionSinergia() {
    final mapa = _mapaActual;
    if (mapa == null) return 0;
    final buenos = _agentesFuertesPorMapa[mapa['nombre']] ?? const <String>[];
    var puntos = 0;
    for (final agente in _agentesAsignados) {
      if (agente != null && buenos.contains(agente)) puntos += 1;
    }
    return puntos;
  }

  bool _esBuenPick(String? agente) {
    final mapa = _mapaActual;
    if (agente == null || mapa == null) return false;
    return (_agentesFuertesPorMapa[mapa['nombre']] ?? const <String>[]).contains(agente);
  }

  String _rutaAgente(String agente) {
    final archivo = agente.toLowerCase().replaceAll('/', '').replaceAll(' ', '_');
    return 'assets/valorant/agentes/$archivo.png';
  }

  Future<List<Map<String, dynamic>>> _generarRivalIA() async {
    final catalogo = await supabase.from('jugadores').select();
    var pool = List<Map<String, dynamic>>.from(catalogo as List);
    pool.shuffle(_random);
    if (pool.length < 5) {
      throw Exception('El catálogo no tiene suficientes jugadores para generar un rival.');
    }
    return pool.take(5).toList();
  }

  Future<void> _jugarPartida() async {
    if (_seleccionados.length != 5) return;
    if (_agentesAsignados.any((a) => a == null)) return;

    setState(() {
      _error = null;
      _fase = _FaseJuego.simulando;
      _rondasJugador = 0;
      _rondasIA = 0;
      _rondaActual = 0;
      _historialRondas.clear();
      _timelineEventos.clear();
      _rondaEnVivo = null;
      _bonoSinergia = _bonificacionSinergia();
    });

    try {
      _rosterRival = await _generarRivalIA();

      // La IA ahora "compensa" parte de la ventaja de química/sinergia del
      // jugador (simula que el rival también tiene coordinación de equipo),
      // y el azar por ronda tiene más peso. Esto baja el % de victoria del
      // jugador sin tocar el draft, la química ni la asignación de agentes.
      final quimicaJugador = _ratingEfectivo(_seleccionados, conQuimica: true) -
          _ratingEfectivo(_seleccionados, conQuimica: false);
      final ratingPropio = _ratingEfectivo(_seleccionados, conQuimica: true) + _bonoSinergia;
      final ratingRival = _ratingEfectivo(_rosterRival, conQuimica: false) +
          (quimicaJugador * 0.45) +
          (_bonoSinergia * 0.35);

      while (_rondasJugador < _rondasParaGanar && _rondasIA < _rondasParaGanar) {
        final numeroRonda = _rondaActual + 1;

        setState(() {
          _rondaActual = numeroRonda;
          _resolviendoRonda = true;
          _rondaEnVivo = {'ronda': numeroRonda, 'lineas': <String>[]};
        });

        final rachaJugador = _rachaActual(true);
        final rachaRival = _rachaActual(false);
        final momentumJugador = rachaJugador >= 3 ? 1 : (rachaRival >= 3 ? -1 : 0);
        final momentumRival = rachaRival >= 3 ? 1 : (rachaJugador >= 3 ? -1 : 0);

        final miPuntaje = ratingPropio + momentumJugador + (_random.nextInt(19) - 9);
        final rivalPuntaje = ratingRival + momentumRival + (_random.nextInt(19) - 9);

        bool ganeLaRonda;
        if (miPuntaje == rivalPuntaje) {
          ganeLaRonda = _random.nextBool();
        } else {
          ganeLaRonda = miPuntaje > rivalPuntaje;
        }

        final equipoGanador = ganeLaRonda ? _seleccionados : _rosterRival;
        final equipoPerdedor = ganeLaRonda ? _rosterRival : _seleccionados;
        final heroe = '${equipoGanador[_random.nextInt(equipoGanador.length)]['nombre'] ?? 'Jugador'}';
        final caido = '${equipoPerdedor[_random.nextInt(equipoPerdedor.length)]['nombre'] ?? 'Rival'}';
        final lineaHeroe =
            _eventosPositivos[_random.nextInt(_eventosPositivos.length)].replaceAll('{jugador}', heroe);
        final lineaCaido =
            _eventosNegativos[_random.nextInt(_eventosNegativos.length)].replaceAll('{jugador}', caido);

        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() {
          _rondaEnVivo = {'ronda': numeroRonda, 'lineas': [lineaHeroe]};
        });

        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() {
          _rondaEnVivo = {'ronda': numeroRonda, 'lineas': [lineaHeroe, lineaCaido]};
        });

        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        setState(() {
          _resolviendoRonda = false;
          _rondaEnVivo = null;
          _historialRondas.add(ganeLaRonda);
          _timelineEventos.add({
            'ronda': numeroRonda,
            'gano': ganeLaRonda,
            'lineas': [lineaHeroe, lineaCaido],
          });
          if (ganeLaRonda) {
            _rondasJugador += 1;
          } else {
            _rondasIA += 1;
          }
        });

        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
      }

      final victoria = _rondasJugador > _rondasIA;

      final mvp = List<Map<String, dynamic>>.from(_seleccionados)
        ..sort((a, b) {
          final ratingA = ((a['ovr'] ?? 0) as num) + _quimicaDeCarta(a);
          final ratingB = ((b['ovr'] ?? 0) as num) + _quimicaDeCarta(b);
          return ratingB.compareTo(ratingA);
        });

      final monedas = victoria ? 150 : 50;
      await _pagarMonedas(monedas);

      if (!mounted) return;
      setState(() {
        _victoria = victoria;
        _monedasGanadas = monedas;
        _mvp = mvp.first;
        _fase = _FaseJuego.resultado;
      });
    } catch (e) {
      debugPrint('ERROR EN PARTIDA RÁPIDA: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo completar la partida.';
        _fase = _FaseJuego.draft;
      });
    }
  }

  Future<void> _pagarMonedas(int cantidad) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;
  try {
    await supabase.rpc('fn_pagar_monedas_partida', params: {'p_cantidad': cantidad});
  } catch (e) {
    debugPrint('ERROR AL PAGAR MONEDAS DE PARTIDA: $e');
  }
}

  void _irAAsignarAgentes() {
    if (_seleccionados.length != 5) return;
    setState(() {
      _mapaActual = _mapasValorant[_random.nextInt(_mapasValorant.length)];
      for (var i = 0; i < _agentesAsignados.length; i++) {
        _agentesAsignados[i] = null;
      }
      _fase = _FaseJuego.agentes;
    });
  }

  Future<void> _mostrarSelectorAgente(int index) async {
    final carta = _casillas[index];
    if (carta == null) return;
    final rol = _rol(carta);
    final agentesDelRol = _agentesPorRol[rol] ??
        _agentesPorRol.values.expand((lista) => lista).toList();

    final usadosPorOtros = <String>{
      for (var i = 0; i < _agentesAsignados.length; i++)
        if (i != index && _agentesAsignados[i] != null) _agentesAsignados[i]!
    };
    final agentes = agentesDelRol.where((a) => !usadosPorOtros.contains(a)).toList();

    final nombreMapa = _mapaActual?['nombre'] ?? '';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          decoration: BoxDecoration(
            color: _kFondoPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _kRojo, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_pin_circle, color: _kRojo, size: 26),
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
              const SizedBox(height: 6),
              const Text(
                '⭐ = comfort pick para este mapa (+1 táctico oculto)',
                style: TextStyle(color: _kDorado, fontSize: 11),
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
                  final esBueno = _esBuenPick(agente);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _agentesAsignados[index] = agente);
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
                              color: _kFondo,
                              border: Border.all(
                                color: esBueno ? _kDorado : Colors.white24,
                                width: esBueno ? 2.5 : 1.5,
                              ),
                              boxShadow: esBueno
                                  ? [BoxShadow(color: _kDorado.withOpacity(0.5), blurRadius: 8)]
                                  : null,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _rutaAgente(agente),
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
                          if (esBueno)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 2.0),
                              child: Icon(Icons.star, color: _kDorado, size: 12),
                            ),
                          Text(
                            agente,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: esBueno ? _kDorado : Colors.white,
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

  void _jugarDeNuevo() {
    setState(() {
      for (var i = 0; i < _casillas.length; i++) {
        _casillas[i] = null;
      }
      for (var i = 0; i < _agentesAsignados.length; i++) {
        _agentesAsignados[i] = null;
      }
      _rosterRival = [];
      _bonoSinergia = 0;
      _timelineEventos.clear();
      _rondaEnVivo = null;
      _fase = _FaseJuego.draft;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text('PARTIDA RÁPIDA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: _kRojo),
        ),
      ),
      body: SafeArea(
        child: switch (_fase) {
          _FaseJuego.draft => _buildDraft(),
          _FaseJuego.agentes => _buildAgentes(),
          _FaseJuego.simulando => _buildSimulando(),
          _FaseJuego.resultado => _buildResultado(),
        },
      ),
    );
  }

  Widget _buildDraft() {
    final equipoCompleto = _seleccionados.length == 5;
    return Column(
      children: [
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: _Encabezado(
            icono: Icons.local_fire_department,
            titulo: 'ARMA TU EQUIPO',
            subtitulo: 'Toca una casilla, aparecerán 4 jugadores y eliges uno.',
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(_error!, style: const TextStyle(color: _kRojo), textAlign: TextAlign.center),
          ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildPanelQuimica(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: List.generate(5, _buildCasilla),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _BotonPrincipal(
            texto: equipoCompleto
                ? 'ASIGNAR AGENTES'
                : '${_seleccionados.length}/5 jugadores elegidos',
            onPressed: equipoCompleto ? _irAAsignarAgentes : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCasilla(int index) {
    final carta = _casillas[index];
    final estaRevelando = _revelando && _casillaEnRevelacion == index;

    return SizedBox(
      width: 100,
      child: GestureDetector(
        onTap: carta == null ? () => _abrirCasilla(index) : null,
        child: carta != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _kDorado.withOpacity(0.35), blurRadius: 8)],
                    ),
                    child: CartaWidget(jugador: carta, width: 100),
                  ),
                  const SizedBox(height: 5),
                  _puntitosQuimica(_quimicaDeCarta(carta)),
                ],
              )
            : AspectRatio(
                aspectRatio: 626 / 794,
                child: Container(
                  decoration: BoxDecoration(
                    color: _kFondoPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorde, width: 1.5),
                  ),
                  child: Center(
                    child: estaRevelando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: _kRojo, strokeWidth: 2),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kRojo.withOpacity(0.12),
                                  border: Border.all(color: _kRojo.withOpacity(0.5)),
                                ),
                                child: Icon(Icons.add, color: _kRojo.withOpacity(0.9), size: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Jugador ${index + 1}',
                                style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 10.5),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAgentes() {
    final nombreMapa = _mapaActual?['nombre'] ?? '';
    final todosAsignados = _agentesAsignados.every((a) => a != null);
    final asignados = _agentesAsignados.where((a) => a != null).length;

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _Encabezado(
            icono: Icons.map_outlined,
            titulo: 'MAPA: ${nombreMapa.toUpperCase()}',
            color: _kDorado,
            subtitulo: 'Elige un agente por jugador. La ⭐ marca un buen pick para este mapa.',
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: List.generate(5, _buildCasillaAgente),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _BotonPrincipal(
            texto: todosAsignados ? 'JUGAR' : 'Agentes asignados: $asignados/5',
            onPressed: todosAsignados ? _jugarPartida : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCasillaAgente(int index) {
    final carta = _casillas[index]!;
    final agenteActual = _agentesAsignados[index];
    final esBuenPick = _esBuenPick(agenteActual);

    return SizedBox(
      width: 100,
      child: GestureDetector(
        onTap: () => _mostrarSelectorAgente(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: _kDorado.withOpacity(0.4), blurRadius: 8)],
              ),
              child: CartaWidget(jugador: carta, width: 100),
            ),
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kFondo,
                    border: Border.all(
                      color: agenteActual == null
                          ? Colors.white24
                          : (esBuenPick ? _kDorado : _kRojoOscuro),
                      width: esBuenPick ? 2.5 : 1.5,
                    ),
                    boxShadow: esBuenPick
                        ? [BoxShadow(color: _kDorado.withOpacity(0.5), blurRadius: 6)]
                        : null,
                  ),
                  child: agenteActual == null
                      ? const Icon(Icons.add, color: Colors.white38, size: 20)
                      : ClipOval(
                          child: Image.asset(
                            _rutaAgente(agenteActual),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              color: Colors.white38,
                              size: 20,
                            ),
                          ),
                        ),
                ),
                if (esBuenPick)
                  const Positioned(
                    top: -3,
                    right: -3,
                    child: Icon(Icons.star, color: _kDorado, size: 15),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              agenteActual ?? 'Elegir agente',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: agenteActual == null ? Colors.white54 : Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelQuimica() {
    final rolesPresentes = _seleccionados.map(_rol).toSet();
    final rolesOk = _rolesPrincipales.where(rolesPresentes.contains).length;
    final regionOk = _seleccionados.any(
        (j) => _region(j).isNotEmpty && _seleccionados.where((k) => _region(k) == _region(j)).length > 1);
    final equipoOk = _seleccionados.any(
        (j) => _equipo(j).isNotEmpty && _seleccionados.where((k) => _equipo(k) == _equipo(j)).length > 1);

    return _Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: _kDorado, size: 18),
              const SizedBox(width: 6),
              const Text('Química del equipo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('$_quimicaTotalPromedio/3', style: const TextStyle(color: _kDorado, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_quimicaTotalPromedio / 3).clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(_kDorado),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniIndicador(Icons.groups, 'Roles', '$rolesOk/4', rolesOk == 4),
              _miniIndicador(Icons.public, 'Región', regionOk ? 'Sí' : 'No', regionOk),
              _miniIndicador(Icons.shield, 'Equipo', equipoOk ? 'Sí' : 'No', equipoOk),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniIndicador(IconData icono, String label, String valor, bool activo) {
    final color = activo ? _kDorado : Colors.white38;
    return Column(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
        Text(valor, style: TextStyle(color: activo ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Los "3 puntitos" de química de una carta: dorado = ganado, vacío = no ganado.
  Widget _puntitosQuimica(int valor) {
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
              color: activo ? _kDorado : Colors.transparent,
              border: Border.all(color: activo ? _kDorado : Colors.white30, width: 1),
              boxShadow: activo ? [BoxShadow(color: _kDorado.withOpacity(0.6), blurRadius: 4)] : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSimulando() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: _kFondo),
        if (_mapaActual != null)
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.94,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.1, 0.9, 1.0],
                    ).createShader(rect);
                  },
                  child: Image.asset(
                    _mapaActual!['imagen']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _kFondo.withOpacity(0.35),
                _kFondo.withOpacity(0.55),
                _kFondo.withOpacity(0.35),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Tarjeta(
                    borde: _kRojoOscuro,
                    child: Column(
                      children: [
                        if (_mapaActual != null)
                          Text(
                            _mapaActual!['nombre']!.toUpperCase(),
                            style: const TextStyle(color: Colors.white38, fontSize: 11.5, letterSpacing: 1.5),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          '$_rondasJugador — $_rondasIA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gana quien llegue primero a $_rondasParaGanar rondas',
                          style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _rondaActual == 0 ? 'Preparando la partida...' : 'Ronda $_rondaActual',
                          style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        if (_bonoSinergia > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '🎯 Sinergia de agentes: +$_bonoSinergia',
                              style: const TextStyle(color: _kDorado, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        _buildIndicadorMomentum(),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_historialRondas.length + (_resolviendoRonda ? 1 : 0), (i) {
                            Color color = Colors.white38;
                            IconData icono = Icons.hourglass_bottom;
                            if (i < _historialRondas.length) {
                              final gane = _historialRondas[i];
                              color = gane ? _kDorado : _kRojo;
                              icono = gane ? Icons.check_circle : Icons.cancel;
                            }
                            return Icon(icono, color: color, size: 20);
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildTimeline(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicadorMomentum() {
    final rachaJugador = _rachaActual(true);
    final rachaRival = _rachaActual(false);
    if (rachaJugador >= 3) {
      return const Padding(
        padding: EdgeInsets.only(top: 6.0),
        child: Text('¡EN RACHA! +1 de impulso', style: TextStyle(color: _kDorado, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    if (rachaRival >= 3) {
      return const Padding(
        padding: EdgeInsets.only(top: 6.0),
        child: Text('La IA está en racha, -1 a tu equipo', style: TextStyle(color: _kRojo, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTimeline() {
    final rondaEnVivo = _rondaEnVivo;

    if (_timelineEventos.isEmpty && rondaEnVivo == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Text(
            'La partida está por comenzar...',
            style: TextStyle(color: Colors.white38, fontSize: 12.5),
          ),
        ),
      );
    }

    final entradas = _timelineEventos.reversed.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          if (rondaEnVivo != null) ...[
            _buildEntradaEnVivo(rondaEnVivo),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, color: Colors.white12),
            ),
          ],
          for (var i = 0; i < entradas.length; i++) ...[
            _buildEntradaResuelta(entradas[i]),
            if (i != entradas.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, color: Colors.white12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntradaEnVivo(Map<String, dynamic> evento) {
    final ronda = evento['ronda'] as int;
    final lineas = (evento['lineas'] as List).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(color: _kDorado, strokeWidth: 1.6),
            ),
            const SizedBox(width: 8),
            Text(
              'RONDA $ronda · EN JUEGO',
              style: const TextStyle(
                color: _kDorado,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        if (lineas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 2),
            child: Text('•  ...', style: TextStyle(color: Colors.white38, fontSize: 12.5)),
          )
        else
          for (final linea in lineas) _lineaAnimada(linea, key: ValueKey('$ronda-$linea')),
      ],
    );
  }

  Widget _lineaAnimada(String texto, {Key? key}) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, valor, child) {
        return Opacity(
          opacity: valor,
          child: Transform.translate(
            offset: Offset(0, (1 - valor) * 6),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 2),
        child: Text(
          '•  $texto',
          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
      ),
    );
  }

  Widget _buildEntradaResuelta(Map<String, dynamic> evento) {
    final gano = evento['gano'] as bool;
    final ronda = evento['ronda'] as int;
    final lineas = (evento['lineas'] as List).cast<String>();
    final color = gano ? _kDorado : _kRojo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(gano ? Icons.check_circle : Icons.cancel, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              'RONDA $ronda · ${gano ? 'GANADA' : 'PERDIDA'}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        for (final linea in lineas)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 2),
            child: Text(
              '•  $linea',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
      ],
    );
  }

  Widget _buildResultado() {
    final color = _victoria ? _kDorado : _kRojo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _Tarjeta(
            borde: color.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            child: Column(
              children: [
                Icon(_victoria ? Icons.emoji_events : Icons.local_fire_department, color: color, size: 60),
                const SizedBox(height: 10),
                Text(
                  _victoria ? '¡VICTORIA!' : 'DERROTA',
                  style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Marcador final: $_rondasJugador - $_rondasIA',
                  style: const TextStyle(color: _kTextoSuave, fontSize: 14.5),
                ),
                if (_bonoSinergia > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Ventaja táctica por sinergia: +$_bonoSinergia',
                      style: const TextStyle(color: _kDorado, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kDorado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _kDorado.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: _kDorado, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '+$_monedasGanadas monedas',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_mvp != null) ...[
            const SizedBox(height: 20),
            _Tarjeta(
              child: Column(
                children: [
                  const Text('MVP DEL PARTIDO',
                      style: TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 14),
                  CartaWidget(jugador: _mvp!, width: 200),
                  const SizedBox(height: 8),
                  _puntitosQuimica(_quimicaDeCarta(_mvp!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          _BotonPrincipal(texto: 'JUGAR DE NUEVO', onPressed: _jugarDeNuevo),
        ],
      ),
    );
  }
}

class _SelectorCartasSheet extends StatelessWidget {
  final List<Map<String, dynamic>> opciones;
  final void Function(Map<String, dynamic>) onElegir;
  final int Function(Map<String, dynamic>) quimicaPreview;

  const _SelectorCartasSheet({
    required this.opciones,
    required this.onElegir,
    required this.quimicaPreview,
  });

  Widget _puntitos(int valor) {
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
              color: activo ? _kDorado : Colors.transparent,
              border: Border.all(color: activo ? _kDorado : Colors.white30, width: 1),
              boxShadow: activo ? [BoxShadow(color: _kDorado.withOpacity(0.6), blurRadius: 4)] : null,
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      decoration: BoxDecoration(
        color: _kFondoPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _kRojo, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: _kRojo, size: 28),
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
              _opcionCarta(opciones[0], anchoTarjeta),
              _opcionCarta(opciones[1], anchoTarjeta),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _opcionCarta(opciones[2], anchoTarjeta),
              _opcionCarta(opciones[3], anchoTarjeta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcionCarta(Map<String, dynamic> carta, double ancho) {
    return GestureDetector(
      onTap: () => onElegir(carta),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _kRojo.withOpacity(0.35), blurRadius: 10)],
            ),
            child: CartaWidget(jugador: carta, width: ancho),
          ),
          const SizedBox(height: 6),
          _puntitos(quimicaPreview(carta)),
        ],
      ),
    );
  }
}