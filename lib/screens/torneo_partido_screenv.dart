import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/carta_widget.dart';

const Color _kFondo = Color(0xFF0A0A0A);
const Color _kFondoPanel = Color(0xFF1A0E0E);
const Color _kRojo = Color(0xFFE30425);
const Color _kDorado = Color(0xFFFFD700);
const Color _kTextoSuave = Color(0xFFB9B4B4);
const Color _kBorde = Color(0x33FFFFFF);

const int _rondasParaGanar = 5;
const List<String> _rolesPrincipales = ['DUE', 'INI', 'CON', 'CEN'];

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

class ResultadoPartidoTorneo {
  final int rondasUsuario;
  final int rondasRival;
  final bool ganoUsuario;
  ResultadoPartidoTorneo({
    required this.rondasUsuario,
    required this.rondasRival,
    required this.ganoUsuario,
  });
}

enum _FaseTorneo { agentes, simulando, resultado }

class TorneoPartidoUsuarioScreen extends StatefulWidget {
  final String etiquetaPartido;
  final List<Map<String, dynamic>> titularesUsuario;
  final List<Map<String, dynamic>> rosterRival;
  final String nombreRival;

  const TorneoPartidoUsuarioScreen({
    super.key,
    required this.etiquetaPartido,
    required this.titularesUsuario,
    required this.rosterRival,
    required this.nombreRival,
  });

  @override
  State<TorneoPartidoUsuarioScreen> createState() => _TorneoPartidoUsuarioScreenState();
}

class _TorneoPartidoUsuarioScreenState extends State<TorneoPartidoUsuarioScreen> {
  final _random = Random();
  _FaseTorneo _fase = _FaseTorneo.agentes;

  late final Map<String, String> _mapaActual =
      _mapasValorant[_random.nextInt(_mapasValorant.length)];
  final List<String?> _agentesAsignados = List<String?>.filled(5, null);
  int _bonoSinergia = 0;

  int _rondasUsuario = 0;
  int _rondasRival = 0;
  int _rondaActual = 0;
  final List<bool> _historialRondas = [];
  final List<Map<String, dynamic>> _timelineEventos = [];
  Map<String, dynamic>? _rondaEnVivo;
  bool _resolviendoRonda = false;

  String _rol(Map<String, dynamic> j) => '${j['posicion'] ?? ''}'.trim().toUpperCase();
  String _region(Map<String, dynamic> j) => '${j['region'] ?? ''}'.trim().toLowerCase();
  String _equipo(Map<String, dynamic> j) => '${j['equipo'] ?? ''}'.trim().toLowerCase();

  int _quimicaDeCarta(Map<String, dynamic> carta, List<Map<String, dynamic>> roster) {
    var puntos = 0;
    final rolesPresentes = roster.map(_rol).toSet();
    if (roster.length >= 4 && _rolesPrincipales.every(rolesPresentes.contains)) puntos += 1;

    final region = _region(carta);
    if (region.isNotEmpty && roster.where((j) => _region(j) == region).length > 1) puntos += 1;

    final equipo = _equipo(carta);
    if (equipo.isNotEmpty && roster.where((j) => _equipo(j) == equipo).length > 1) puntos += 1;

    return puntos;
  }

  double _ratingEfectivo(List<Map<String, dynamic>> roster, {bool conQuimica = true}) {
    if (roster.isEmpty) return 0;
    final suma = roster.fold<double>(0, (s, j) {
      final ovr = (j['ovr'] ?? 0) as num;
      final quimica = conQuimica ? _quimicaDeCarta(j, roster) : 0;
      return s + ovr + quimica;
    });
    return suma / roster.length;
  }

  bool _esBuenPick(String? agente) {
    if (agente == null) return false;
    return (_agentesFuertesPorMapa[_mapaActual['nombre']] ?? const <String>[]).contains(agente);
  }

  String _rutaAgente(String agente) {
    final archivo = agente.toLowerCase().replaceAll('/', '').replaceAll(' ', '_');
    return 'assets/valorant/agentes/$archivo.png';
  }

  int _bonificacionSinergia() {
    final buenos = _agentesFuertesPorMapa[_mapaActual['nombre']] ?? const <String>[];
    var puntos = 0;
    for (final agente in _agentesAsignados) {
      if (agente != null && buenos.contains(agente)) puntos += 1;
    }
    return puntos;
  }

  bool get _todosAsignados => !_agentesAsignados.contains(null);

  Future<void> _mostrarSelectorAgente(int index) async {
    final carta = widget.titularesUsuario[index];
    final rol = _rol(carta);
    final agentesDelRol =
        _agentesPorRol[rol] ?? _agentesPorRol.values.expand((lista) => lista).toList();

    final usadosPorOtros = <String>{
      for (var i = 0; i < _agentesAsignados.length; i++)
        if (i != index && _agentesAsignados[i] != null) _agentesAsignados[i]!
    };
    final agentes = agentesDelRol.where((a) => !usadosPorOtros.contains(a)).toList();
    final nombreMapa = _mapaActual['nombre'] ?? '';

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
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0),
              ),
              const SizedBox(height: 4),
              Text('Rol: $rol  ·  Mapa: $nombreMapa',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              const Text('⭐ = comfort pick para este mapa (+1 táctico oculto)',
                  style: TextStyle(color: _kDorado, fontSize: 11)),
              const SizedBox(height: 16),
              if (agentes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'No quedan agentes de este rol disponibles.',
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, color: Colors.white38, size: 28),
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

  void _confirmarAgentesYJugar() {
    if (!_todosAsignados) return;
    setState(() {
      _bonoSinergia = _bonificacionSinergia();
      _fase = _FaseTorneo.simulando;
    });
    _simular();
  }

  int _racha(bool paraUsuario) {
    var racha = 0;
    for (var i = _historialRondas.length - 1; i >= 0; i--) {
      final ganoUsuario = _historialRondas[i];
      if (paraUsuario ? ganoUsuario : !ganoUsuario) {
        racha++;
      } else {
        break;
      }
    }
    return racha;
  }

  String _plantilla(List<String> lista, Map<String, dynamic> jugador) {
    final base = lista[_random.nextInt(lista.length)];
    return base.replaceAll('{jugador}', '${jugador['nombre'] ?? 'Jugador'}');
  }

  Future<void> _simular() async {
    final quimicaJugador = _ratingEfectivo(widget.titularesUsuario, conQuimica: true) -
        _ratingEfectivo(widget.titularesUsuario, conQuimica: false);
    final ratingPropio = _ratingEfectivo(widget.titularesUsuario, conQuimica: true) + _bonoSinergia;
    final ratingRival = _ratingEfectivo(widget.rosterRival, conQuimica: false) +
        (quimicaJugador * 0.45) +
        (_bonoSinergia * 0.35);

    while (_rondasUsuario < _rondasParaGanar && _rondasRival < _rondasParaGanar) {
      final numeroRonda = _rondaActual + 1;
      setState(() {
        _rondaActual = numeroRonda;
        _resolviendoRonda = true;
        _rondaEnVivo = {'ronda': numeroRonda, 'lineas': <String>[]};
      });

      final rachaUsuario = _racha(true);
      final rachaRival = _racha(false);
      final momentumUsuario = rachaUsuario >= 3 ? 1 : (rachaRival >= 3 ? -1 : 0);
      final momentumRival = rachaRival >= 3 ? 1 : (rachaUsuario >= 3 ? -1 : 0);

      final miPuntaje = ratingPropio + momentumUsuario + (_random.nextInt(19) - 9);
      final rivalPuntaje = ratingRival + momentumRival + (_random.nextInt(19) - 9);

      final ganeLaRonda =
          miPuntaje == rivalPuntaje ? _random.nextBool() : miPuntaje > rivalPuntaje;

      final heroe = ganeLaRonda
          ? widget.titularesUsuario[_random.nextInt(widget.titularesUsuario.length)]
          : widget.rosterRival[_random.nextInt(widget.rosterRival.length)];
      final caido = ganeLaRonda
          ? widget.rosterRival[_random.nextInt(widget.rosterRival.length)]
          : widget.titularesUsuario[_random.nextInt(widget.titularesUsuario.length)];

      final lineaHeroe = _plantilla(_eventosPositivos, heroe);
      final lineaCaido = _plantilla(_eventosNegativos, caido);

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
          _rondasUsuario += 1;
        } else {
          _rondasRival += 1;
        }
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() => _fase = _FaseTorneo.resultado);
  }

  void _finalizar() {
    Navigator.of(context).pop(
      ResultadoPartidoTorneo(
        rondasUsuario: _rondasUsuario,
        rondasRival: _rondasRival,
        ganoUsuario: _rondasUsuario > _rondasRival,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _fase != _FaseTorneo.simulando,
      child: Scaffold(
        backgroundColor: _kFondo,
        appBar: AppBar(
          title: Text(widget.etiquetaPartido.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: _fase != _FaseTorneo.simulando,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: _kRojo),
          ),
        ),
        body: SafeArea(
          child: switch (_fase) {
            _FaseTorneo.agentes => _buildAgentes(),
            _FaseTorneo.simulando => _buildSimulando(),
            _FaseTorneo.resultado => _buildResultado(),
          },
        ),
      ),
    );
  }

  Widget _buildAgentes() {
    final mapaNombre = _mapaActual['nombre'] ?? '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Column(
            children: [
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorde),
                  image: DecorationImage(
                    image: AssetImage(_mapaActual['imagen'] ?? ''),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  color: Colors.black45,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(mapaNombre,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              Text('vs ${widget.nombreRival}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Asigna un agente a cada jugador para este mapa',
                  style: TextStyle(color: _kTextoSuave, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            itemCount: widget.titularesUsuario.length,
            itemBuilder: (context, index) {
              final carta = widget.titularesUsuario[index];
              final agente = _agentesAsignados[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kFondoPanel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: agente != null ? _kDorado.withOpacity(0.5) : _kBorde),
                ),
                child: Row(
                  children: [
                    CartaWidget(jugador: carta, width: 60, mostrarStats: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${carta['nombre'] ?? ''}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(_rol(carta), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: agente != null ? _kDorado : _kRojo),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _mostrarSelectorAgente(index),
                      child: Text(
                        agente ?? 'ELEGIR',
                        style: TextStyle(color: agente != null ? _kDorado : _kRojo, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _todosAsignados ? _kRojo : Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _todosAsignados ? _confirmarAgentesYJugar : null,
              child: Text(
                _todosAsignados ? 'JUGAR PARTIDO' : 'ASIGNA A TODOS LOS AGENTES',
                style: TextStyle(
                    color: _todosAsignados ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulando() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: _kDorado, size: 18),
              const SizedBox(width: 6),
              Text('TU EQUIPO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(width: 14),
              Text('$_rondasUsuario', style: const TextStyle(color: _kDorado, fontSize: 26, fontWeight: FontWeight.w900)),
              const Text('  -  ', style: TextStyle(color: Colors.white38, fontSize: 22)),
              Text('$_rondasRival', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(width: 14),
              Flexible(
                child: Text(widget.nombreRival,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        if (_resolviendoRonda && _rondaEnVivo != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kFondoPanel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kRojo.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RONDA ${_rondaEnVivo!['ronda']}',
                      style: const TextStyle(color: _kRojo, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  for (final linea in (_rondaEnVivo!['lineas'] as List).cast<String>())
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('•  $linea', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ),
                  if ((_rondaEnVivo!['lineas'] as List).isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('Jugando ronda...', style: TextStyle(color: Colors.white38, fontSize: 12.5)),
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            itemCount: _timelineEventos.length,
            itemBuilder: (context, i) {
              final evento = _timelineEventos[_timelineEventos.length - 1 - i];
              final gano = evento['gano'] as bool;
              final color = gano ? _kDorado : _kRojo;
              final lineas = (evento['lineas'] as List).cast<String>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(gano ? Icons.check_circle : Icons.cancel, color: color, size: 14),
                        const SizedBox(width: 6),
                        Text('RONDA ${evento['ronda']} · ${gano ? 'GANADA' : 'PERDIDA'}',
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                      ],
                    ),
                    for (final linea in lineas)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text('•  $linea', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultado() {
    final gano = _rondasUsuario > _rondasRival;
    final color = gano ? _kDorado : _kRojo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            decoration: BoxDecoration(
              color: _kFondoPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Icon(gano ? Icons.emoji_events : Icons.local_fire_department, color: color, size: 56),
                const SizedBox(height: 10),
                Text(gano ? '¡VICTORIA!' : 'DERROTA',
                    style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                const SizedBox(height: 4),
                Text('Marcador final: $_rondasUsuario - $_rondasRival',
                    style: const TextStyle(color: _kTextoSuave, fontSize: 14)),
                if (_bonoSinergia > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text('Ventaja táctica por sinergia: +$_bonoSinergia',
                        style: const TextStyle(color: _kDorado, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRojo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _finalizar,
              child: const Text('CONTINUAR EN LA LLAVE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5)),
            ),
          ),
        ],
      ),
    );
  }
}
