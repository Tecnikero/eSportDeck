import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/carta_widget.dart';
import '../widgets/carta_mini_widget.dart';

const List<String> _rolesPrincipales = ['DUE', 'INI', 'CON', 'CEN'];

const Color _kFondo = Color(0xFF0A0A0A);
const Color _kFondoPanel = Color(0xFF1A0E0E);
const Color _kRojo = Color(0xFFE30425);
const Color _kRojoOscuro = Color(0xFF7A0000);
const Color _kDorado = Color(0xFFFFD700);
const Color _kTextoSuave = Color(0xFFB9B4B4);
const Color _kBorde = Color(0x33FFFFFF);
const Color _kCian = Color(0xFF29E0E0);

const List<double> _kMatrizGrisEvento = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

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
  double _bonoSinergia = 0;

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

  String _rol(Map<String, dynamic> j) => '${j['posicion'] ?? ''}'.trim().toUpperCase();
  String _region(Map<String, dynamic> j) => '${j['region'] ?? ''}'.trim().toLowerCase();
  String _equipo(Map<String, dynamic> j) => '${j['equipo'] ?? ''}'.trim().toLowerCase();
  String _pais(Map<String, dynamic> j) => '${j['pais'] ?? ''}'.trim().toLowerCase();

  static const int _quimicaObjetivosMax = 4;
  static const double _quimicaPuntosPorObjetivo = 0.5;

  bool get _balanceDeRoles {
    if (_seleccionados.length < 4) return false;
    final rolesPresentes = _seleccionados.map(_rol).toSet();
    return _rolesPrincipales.every(rolesPresentes.contains);
  }

  int _quimicaEnRoster(Map<String, dynamic> carta, List<Map<String, dynamic>> roster) {
    var objetivos = 0;

    final rolesPresentes = roster.map(_rol).toSet();
    final balance = roster.length >= 4 && _rolesPrincipales.every(rolesPresentes.contains);
    if (balance) objetivos += 1;

    final region = _region(carta);
    if (region.isNotEmpty && roster.where((j) => _region(j) == region).length > 1) {
      objetivos += 1;
    }

    final equipo = _equipo(carta);
    if (equipo.isNotEmpty && roster.where((j) => _equipo(j) == equipo).length > 1) {
      objetivos += 1;
    }

    final pais = _pais(carta);
    if (pais.isNotEmpty && roster.where((j) => _pais(j) == pais).length > 1) {
      objetivos += 1;
    }

    return objetivos;
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
      final objetivos = conQuimica ? _quimicaEnRoster(j, roster) : 0;
      return s + ovr + (objetivos * _quimicaPuntosPorObjetivo);
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

  double _bonificacionSinergia() {
    final mapa = _mapaActual;
    if (mapa == null) return 0;
    final buenos = _agentesFuertesPorMapa[mapa['nombre']] ?? const <String>[];
    var puntos = 0.0;
    for (final agente in _agentesAsignados) {
      if (agente != null && buenos.contains(agente)) puntos += 0.5;
    }
    return puntos;
  }

  String _formatoBono(double valor) =>
      valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toStringAsFixed(1);

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

      final miMediaBase = _ratingEfectivo(_seleccionados, conQuimica: true) + _bonoSinergia;
      final rivalMediaBase = _ratingEfectivo(_rosterRival, conQuimica: true);

      final ruidoPartido = (_random.nextDouble() * 6) - 3;
      final ratingPropio = miMediaBase + (ruidoPartido / 2);
      final ratingRival = rivalMediaBase - (ruidoPartido / 2);

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

        var miPuntaje = ratingPropio + momentumJugador + (_random.nextInt(13) - 6);
        var rivalPuntaje = ratingRival + momentumRival + (_random.nextInt(13) - 6);

        if (_random.nextInt(100) < 8) {
          final golpe = 6 + _random.nextInt(7);
          if (_random.nextBool()) {
            miPuntaje += golpe;
          } else {
            rivalPuntaje += golpe;
          }
        }

        bool ganeLaRonda;
        if (miPuntaje == rivalPuntaje) {
          ganeLaRonda = _random.nextBool();
        } else {
          ganeLaRonda = miPuntaje > rivalPuntaje;
        }

        final equipoGanador = ganeLaRonda ? _seleccionados : _rosterRival;
        final equipoPerdedor = ganeLaRonda ? _rosterRival : _seleccionados;
        final heroeCarta = equipoGanador[_random.nextInt(equipoGanador.length)];
        final caidoCarta = equipoPerdedor[_random.nextInt(equipoPerdedor.length)];
        final heroe = '${heroeCarta['nombre'] ?? 'Jugador'}';
        final caido = '${caidoCarta['nombre'] ?? 'Rival'}';
        final lineaHeroe =
            _eventosPositivos[_random.nextInt(_eventosPositivos.length)].replaceAll('{jugador}', heroe);
        final lineaCaido =
            _eventosNegativos[_random.nextInt(_eventosNegativos.length)].replaceAll('{jugador}', caido);

        setState(() {
          _rondaEnVivo = {
            'ronda': numeroRonda,
            'gano': ganeLaRonda,
            'heroeCarta': heroeCarta,
            'caidoCarta': null,
            'lineas': <String>[],
          };
        });

        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() {
          _rondaEnVivo = {
            'ronda': numeroRonda,
            'gano': ganeLaRonda,
            'heroeCarta': heroeCarta,
            'caidoCarta': caidoCarta,
            'lineas': [lineaHeroe],
          };
        });

        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() {
          _rondaEnVivo = {
            'ronda': numeroRonda,
            'gano': ganeLaRonda,
            'heroeCarta': heroeCarta,
            'caidoCarta': caidoCarta,
            'lineas': [lineaHeroe, lineaCaido],
          };
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
            'heroeCarta': heroeCarta,
            'caidoCarta': caidoCarta,
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
      //debugPrint('ERROR AL PAGAR MONEDAS DE PARTIDA: $e');
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
          padding: EdgeInsets.fromLTRB(
            16, 20, 16, 30 + MediaQuery.of(context).padding.bottom,
          ),
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

  Widget _puntitosQuimica(int valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_quimicaObjetivosMax, (i) {
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
    final rachaJugador = _rachaActual(true);
    final rachaRival = _rachaActual(false);
    final Map<String, dynamic>? ultimoEvento =
        _rondaEnVivo ?? (_timelineEventos.isNotEmpty ? _timelineEventos.last : null);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: _kFondo),
        if (_mapaActual != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.62,
              child: Image.asset(
                _mapaActual!['imagen']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kFondo.withOpacity(0.35), _kFondo.withOpacity(0.5), _kFondo.withOpacity(0.35)],
            ),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
              child: Column(
                children: [
                  _buildMarcador(),
                  const SizedBox(height: 10),
                  _buildLineaRondas(),
                  const SizedBox(height: 16),
                  _buildBarraMomentum(rachaJugador, rachaRival),
                  const SizedBox(height: 16),
                  _buildPanelEvento(ultimoEvento),
                  const SizedBox(height: 14),
                  _buildInfoInferior(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarcador() {
    final nombreMapa = _mapaActual?['nombre']?.toUpperCase() ?? '';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Text(
                nombreMapa.isEmpty ? 'AL MEJOR DE $_rondasParaGanar RONDAS' : 'MAPA · $nombreMapa',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _escudoEquipo(icono: Icons.shield, color: _kRojo, etiqueta: 'TÚ'),
                  Column(
                    children: [
                      Text(
                        '$_rondasJugador  -  $_rondasIA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kFondoPanel,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kDorado.withOpacity(0.5)),
                        ),
                        child: Text(
                          _rondaActual == 0 ? 'PREPARANDO' : 'RONDA $_rondaActual',
                          style: const TextStyle(
                            color: _kDorado,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _escudoEquipo(icono: Icons.smart_toy, color: Colors.white54, etiqueta: 'IA'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -2,
          left: -2,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomRight: Radius.circular(10)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              color: _kRojo,
              child: const Text(
                'EN VIVO',
                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _escudoEquipo({required IconData icono, required Color color, required String etiqueta}) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kFondoPanel,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          etiqueta,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6),
        ),
      ],
    );
  }

  Widget _buildLineaRondas() {
    final total = _historialRondas.length + (_resolviendoRonda ? 1 : 0);
    if (total == 0) return const SizedBox(height: 6);

    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 1, color: Colors.white24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(children: List.generate(total, (i) => _tickRonda(i, total))),
          ),
        ],
      ),
    );
  }

  Widget _tickRonda(int i, int total) {
    final esActual = _resolviendoRonda && i == total - 1;
    final bool? gano = esActual ? null : _historialRondas[i];

    return SizedBox(
      width: 32,
      height: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            child: gano == true
                ? const Icon(Icons.circle, color: _kDorado, size: 8)
                : const SizedBox.shrink(),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: esActual ? _kCian : _kFondoPanel,
              border: Border.all(color: esActual ? _kCian : Colors.white38, width: 1.4),
              boxShadow: esActual ? [BoxShadow(color: _kCian.withOpacity(0.7), blurRadius: 6)] : null,
            ),
          ),
          const SizedBox(height: 2),
          Text('${i + 1}', style: const TextStyle(color: Colors.white38, fontSize: 8.5)),
          SizedBox(
            height: 16,
            child: gano == false
                ? const Icon(Icons.circle, color: _kRojo, size: 8)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraMomentum(int rachaJugador, int rachaRival) {
    var posicion = 0.5;
    if (rachaJugador >= 3) posicion = 0.85;
    if (rachaRival >= 3) posicion = 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOMENTUM',
          style: TextStyle(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.6),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(colors: [_kRojoOscuro, Colors.white12, _kDorado]),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              alignment: Alignment(posicion * 2 - 1, 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kCian,
                  boxShadow: [BoxShadow(color: _kCian.withOpacity(0.7), blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
        if (rachaJugador >= 3)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('¡Tu equipo está en racha! +1 de impulso',
                style: TextStyle(color: _kDorado, fontSize: 11.5, fontWeight: FontWeight.bold)),
          )
        else if (rachaRival >= 3)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('La IA está en racha, -1 a tu equipo',
                style: TextStyle(color: _kRojo, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildPanelEvento(Map<String, dynamic>? evento) {
    if (evento == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 34),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text('La partida está por comenzar...', style: TextStyle(color: Colors.white38, fontSize: 12.5)),
        ),
      );
    }

    final enVivo = identical(evento, _rondaEnVivo);
    final gano = evento['gano'] as bool;
    final ronda = evento['ronda'] as int;
    final lineas = (evento['lineas'] as List).cast<String>();
    final heroeCarta = evento['heroeCarta'] as Map<String, dynamic>?;
    final caidoCarta = evento['caidoCarta'] as Map<String, dynamic>?;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('$ronda-${lineas.length}-$enVivo'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kFondo,
                border: Border.all(color: _kCian, width: 2),
              ),
              child: Icon(
                enVivo ? Icons.bolt : (gano ? Icons.check : Icons.close),
                color: _kCian,
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              enVivo ? 'RONDA $ronda · EN JUEGO' : 'RONDA $ronda · ${gano ? 'GANADA' : 'PERDIDA'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kCian,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.6,
              ),
            ),
            if (heroeCarta != null) ...[
              const SizedBox(height: 16),
              _buildDueloCartas(heroeCarta, caidoCarta, gano),
            ],
            const SizedBox(height: 12),
            if (lineas.isEmpty)
              const Text(
                'Cargando la ronda...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12.5),
              )
            else
              Column(
                children: [
                  for (final linea in lineas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        linea,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueloCartas(
    Map<String, dynamic> heroeCarta,
    Map<String, dynamic>? caidoCarta,
    bool gano,
  ) {
    final colorAccion = gano ? _kDorado : _kRojo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: colorAccion.withOpacity(0.45), blurRadius: 10)],
          ),
          child: SizedBox(
            width: 76,
            child: AspectRatio(
              aspectRatio: 626 / 794,
              child: CartaMiniWidget(jugador: heroeCarta),
            ),
          ),
        ),
        SizedBox(
          width: 46,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: colorAccion, size: 20),
              Icon(Icons.arrow_forward, color: colorAccion, size: 16),
              const SizedBox(height: 2),
              Text(
                'MATÓ',
                style: TextStyle(color: colorAccion, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ],
          ),
        ),
        if (caidoCarta != null)
          Opacity(
            opacity: 0.55,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_kMatrizGrisEvento),
              child: SizedBox(
                width: 76,
                child: AspectRatio(
                  aspectRatio: 626 / 794,
                  child: CartaMiniWidget(jugador: caidoCarta),
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: 76,
            child: AspectRatio(
              aspectRatio: 626 / 794,
              child: Container(
                decoration: BoxDecoration(
                  color: _kFondoPanel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.question_mark, color: Colors.white24, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoInferior() {
    final nombreMapa = _mapaActual?['nombre']?.toUpperCase() ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (nombreMapa.isNotEmpty) ...[
          const Icon(Icons.map_outlined, color: Colors.white38, size: 13),
          const SizedBox(width: 6),
          Text(
            nombreMapa,
            style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 11.5, letterSpacing: 0.6),
          ),
        ],
        if (_bonoSinergia > 0) ...[
          const SizedBox(width: 16),
          const Icon(Icons.auto_awesome, color: _kDorado, size: 13),
          const SizedBox(width: 6),
          Text(
            'Sinergia +${_formatoBono(_bonoSinergia)}',
            style: const TextStyle(color: _kDorado, fontWeight: FontWeight.w600, fontSize: 11.5),
          ),
        ],
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
                      'Ventaja táctica por sinergia: +${_formatoBono(_bonoSinergia)}',
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

class _SelectorCartasSheet extends StatefulWidget {
  final List<Map<String, dynamic>> opciones;
  final void Function(Map<String, dynamic>) onElegir;
  final int Function(Map<String, dynamic>) quimicaPreview;

  const _SelectorCartasSheet({
    required this.opciones,
    required this.onElegir,
    required this.quimicaPreview,
  });

  @override
  State<_SelectorCartasSheet> createState() => _SelectorCartasSheetState();
}

class _SelectorCartasSheetState extends State<_SelectorCartasSheet> {
  final List<bool> _visibles = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _visibles.length; i++) {
      Future.delayed(Duration(milliseconds: 160 * i), () {
        if (!mounted) return;
        setState(() => _visibles[i] = true);
      });
    }
  }

  Widget _puntitos(int valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
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
      padding: EdgeInsets.fromLTRB(
        16, 20, 16, 30 + MediaQuery.of(context).padding.bottom,
      ),
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
              _opcionCarta(0, anchoTarjeta),
              _opcionCarta(1, anchoTarjeta),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _opcionCarta(2, anchoTarjeta),
              _opcionCarta(3, anchoTarjeta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcionCarta(int index, double ancho) {
    final carta = widget.opciones[index];
    final visible = _visibles[index];

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.18),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: visible ? () => widget.onElegir(carta) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kRojo.withOpacity(0.5), width: 1.5),
                ),
                child: SizedBox(
                  width: ancho,
                  child: AspectRatio(
                    aspectRatio: 626 / 794,
                    child: CartaMiniWidget(jugador: carta),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _puntitos(widget.quimicaPreview(carta)),
            ],
          ),
        ),
      ),
    );
  }
}