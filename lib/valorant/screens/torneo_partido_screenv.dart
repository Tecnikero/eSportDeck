import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/carta_widget.dart';
import '../core/tema_juego.dart';
import '../core/catalogos_juego.dart';
import '../core/combos.dart';
import '../core/rating.dart';
import '../core/quimica.dart';
import '../core/jugador_helpers.dart';
import '../widgets/selector_agente_sheet.dart';
import '../widgets/combo_tactico_sheet.dart';


const int _rondasParaGanar = 5;
const List<String> _rolesPrincipales = ['DUE', 'INI', 'CON', 'CEN'];

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
      mapasValorant[_random.nextInt(mapasValorant.length)];
  final List<String?> _agentesAsignados = List<String?>.filled(5, null);
  double _bonoSinergia = 0;

  int _rondasUsuario = 0;
  int _rondasRival = 0;
  int _rondaActual = 0;
  final List<bool> _historialRondas = [];
  final List<Map<String, dynamic>> _timelineEventos = [];
  Map<String, dynamic>? _rondaEnVivo;
  bool _resolviendoRonda = false;





  double _bonoIdentidadPromedio(List<Map<String, dynamic>> roster) {
    final activas = identidadesActivas(roster);
    if (activas.isEmpty) return 0;
    return activas.fold<double>(0.0, (s, id) {
      final atk = (id['bonoAtaque'] as num).toDouble();
      final def = (id['bonoDefensa'] as num).toDouble();
      return s + ((atk + def) / 2);
    });
  }


  double _bonoSinergiaAgentes() => sinergiasActivas(_agentesAsignados).length * 0.5;

  double _bonificacionSinergia() =>
      _bonoIdentidadPromedio(widget.titularesUsuario) + _bonoSinergiaAgentes();


  Future<void> _mostrarComboTactico() async => mostrarComboTactico(context);

  bool get _todosAsignados => !_agentesAsignados.contains(null);

  Future<void> _mostrarSelectorAgente(int index) async {
    final carta = widget.titularesUsuario[index];
    await mostrarSelectorAgente(
      context: context,
      carta: carta,
      rol: rolDe(carta),
      nombreMapa: _mapaActual['nombre'] ?? '',
      agentesAsignados: _agentesAsignados,
      indiceJugador: index,
      onElegir: (agente) => setState(() => _agentesAsignados[index] = agente),
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
    final miMediaBase =
        ratingEfectivo(widget.titularesUsuario, conQuimica: true) + _bonoSinergia;
    final rivalMediaBase = ratingEfectivo(widget.rosterRival, conQuimica: true);
    final ruidoPartido = (_random.nextDouble() * 6) - 3;
    final ratingPropio = miMediaBase + (ruidoPartido / 2);
    final ratingRival = rivalMediaBase - (ruidoPartido / 2);

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

      var miPuntaje = ratingPropio + momentumUsuario + (_random.nextInt(13) - 6);
      var rivalPuntaje = ratingRival + momentumRival + (_random.nextInt(13) - 6);
      if (_random.nextInt(100) < 8) {
        final golpe = 6 + _random.nextInt(7);
        if (_random.nextBool()) {
          miPuntaje += golpe;
        } else {
          rivalPuntaje += golpe;
        }
      }

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
        backgroundColor: TemaJuego.fondo,
        appBar: AppBar(
          title: Text(widget.etiquetaPartido.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: _fase != _FaseTorneo.simulando,
          actions: [
            if (_fase != _FaseTorneo.simulando)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: _mostrarComboTactico,
                  icon: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TemaJuego.rojo.withOpacity(0.12),
                      border: Border.all(color: TemaJuego.rojo.withOpacity(0.6), width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(color: TemaJuego.rojo, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ),
                  tooltip: 'Combos tácticos',
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: TemaJuego.rojo),
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
                  border: Border.all(color: TemaJuego.borde),
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
              const Text('Asigna un agente a cada jugador. Busca sinergias de habilidades.',
                  style: TextStyle(color: TemaJuego.textoSuave, fontSize: 12)),
              const SizedBox(height: 14),
              _buildPanelQuimica(),
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
                  color: TemaJuego.fondoPanel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: agente != null ? TemaJuego.dorado.withOpacity(0.5) : TemaJuego.borde),
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
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(rolDe(carta), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              const SizedBox(width: 8),
                              _puntitosQuimica(quimicaDeCarta(carta, widget.titularesUsuario)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: agente != null ? TemaJuego.dorado : TemaJuego.rojo),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _mostrarSelectorAgente(index),
                      child: Text(
                        agente ?? 'ELEGIR',
                        style: TextStyle(color: agente != null ? TemaJuego.dorado : TemaJuego.rojo, fontWeight: FontWeight.bold, fontSize: 12),
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
                backgroundColor: _todosAsignados ? TemaJuego.rojo : Colors.white12,
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

  Widget _buildPanelQuimica() {
    final roster = widget.titularesUsuario;
    final rolesPresentes = roster.map(rolDe).toSet();
    final rolesOk = _rolesPrincipales.where(rolesPresentes.contains).length;
    final regionOk = roster.any(
        (j) => regionDe(j).isNotEmpty && roster.where((k) => regionDe(k) == regionDe(j)).length > 1);
    final equipoOk = roster.any(
        (j) => equipoDe(j).isNotEmpty && roster.where((k) => equipoDe(k) == equipoDe(j)).length > 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TemaJuego.fondoPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TemaJuego.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: TemaJuego.dorado, size: 18),
              const SizedBox(width: 6),
              const Text('Química del equipo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('${quimicaTotalEquipo(widget.titularesUsuario)}/15',
                  style: const TextStyle(color: TemaJuego.dorado, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (quimicaTotalEquipo(widget.titularesUsuario) / 15).clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(TemaJuego.dorado),
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
    final color = activo ? TemaJuego.dorado : Colors.white38;
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
      children: List.generate(3, (i) {
        final activo = i < valor;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activo ? TemaJuego.dorado : Colors.transparent,
              border: Border.all(color: activo ? TemaJuego.dorado : Colors.white30, width: 1),
              boxShadow: activo ? [BoxShadow(color: TemaJuego.dorado.withOpacity(0.6), blurRadius: 4)] : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSimulando() {
    final rachaUsuario = _racha(true);
    final rachaRival = _racha(false);
    final Map<String, dynamic>? ultimoEvento =
        _rondaEnVivo ?? (_timelineEventos.isNotEmpty ? _timelineEventos.last : null);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: TemaJuego.fondo),
        Positioned.fill(
          child: Opacity(
            opacity: 0.62,
            child: Image.asset(
              _mapaActual['imagen'] ?? '',
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
              colors: [TemaJuego.fondo.withOpacity(0.35), TemaJuego.fondo.withOpacity(0.5), TemaJuego.fondo.withOpacity(0.35)],
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
                  _buildBarraMomentum(rachaUsuario, rachaRival),
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
    final nombreMapa = (_mapaActual['nombre'] ?? '').toUpperCase();
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
              const SizedBox(height: 4),
              Text(
                widget.etiquetaPartido.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TemaJuego.dorado,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _escudoEquipo(icono: Icons.star, color: TemaJuego.rojo, etiqueta: 'TÚ'),
                  Column(
                    children: [
                      Text(
                        '$_rondasUsuario  -  $_rondasRival',
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
                          color: TemaJuego.fondoPanel,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TemaJuego.dorado.withOpacity(0.5)),
                        ),
                        child: Text(
                          _rondaActual == 0 ? 'PREPARANDO' : 'RONDA $_rondaActual',
                          style: const TextStyle(
                            color: TemaJuego.dorado,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _escudoEquipo(icono: Icons.shield_outlined, color: Colors.white54, etiqueta: widget.nombreRival),
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
              color: TemaJuego.rojo,
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
            color: TemaJuego.fondoPanel,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            etiqueta,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          ),
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
      width: 26,
      height: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            child: gano == true
                ? const Icon(Icons.circle, color: TemaJuego.dorado, size: 7)
                : const SizedBox.shrink(),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: esActual ? TemaJuego.cian : TemaJuego.fondoPanel,
              border: Border.all(color: esActual ? TemaJuego.cian : Colors.white38, width: 1.3),
              boxShadow: esActual ? [BoxShadow(color: TemaJuego.cian.withOpacity(0.7), blurRadius: 6)] : null,
            ),
          ),
          const SizedBox(height: 2),
          Text('${i + 1}', style: const TextStyle(color: Colors.white38, fontSize: 8)),
          SizedBox(
            height: 16,
            child: gano == false
                ? const Icon(Icons.circle, color: TemaJuego.rojo, size: 7)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraMomentum(int rachaUsuario, int rachaRival) {
    var posicion = 0.5;
    if (rachaUsuario >= 3) posicion = 0.85;
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
                gradient: const LinearGradient(colors: [TemaJuego.rojoOscuro, Colors.white12, TemaJuego.dorado]),
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
                  color: TemaJuego.cian,
                  boxShadow: [BoxShadow(color: TemaJuego.cian.withOpacity(0.7), blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
        if (rachaUsuario >= 3)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('¡Tu equipo está en racha! +1 de impulso',
                style: TextStyle(color: TemaJuego.dorado, fontSize: 11.5, fontWeight: FontWeight.bold)),
          )
        else if (rachaRival >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('${widget.nombreRival} está en racha, -1 a tu equipo',
                style: const TextStyle(color: TemaJuego.rojo, fontSize: 11.5, fontWeight: FontWeight.bold)),
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
          child: Text('El partido está por comenzar...', style: TextStyle(color: Colors.white38, fontSize: 12.5)),
        ),
      );
    }

    final enVivo = identical(evento, _rondaEnVivo);
    final gano = evento['gano'] as bool? ?? false;
    final ronda = evento['ronda'] as int;
    final lineas = (evento['lineas'] as List).cast<String>();

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
                color: TemaJuego.fondo,
                border: Border.all(color: TemaJuego.cian, width: 2),
              ),
              child: Icon(
                enVivo ? Icons.bolt : (gano ? Icons.check : Icons.close),
                color: TemaJuego.cian,
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              enVivo ? 'RONDA $ronda · EN JUEGO' : 'RONDA $ronda · ${gano ? 'GANADA' : 'PERDIDA'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TemaJuego.cian,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.6,
              ),
            ),
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

  Widget _buildInfoInferior() {
    final nombreMapa = _mapaActual['nombre'] ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (nombreMapa.isNotEmpty) ...[
          const Icon(Icons.map, color: Colors.white38, size: 13),
          const SizedBox(width: 6),
          Text(
            nombreMapa,
            style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 11.5, letterSpacing: 0.6),
          ),
        ],
        if (_bonoSinergia > 0) ...[
          const SizedBox(width: 16),
          const Icon(Icons.auto_awesome, color: TemaJuego.dorado, size: 13),
          const SizedBox(width: 6),
          Text(
            'Sinergia +${formatoBono(_bonoSinergia)}',
            style: const TextStyle(color: TemaJuego.dorado, fontWeight: FontWeight.w600, fontSize: 11.5),
          ),
        ],
      ],
    );
  }

  Widget _buildResultado() {
    final gano = _rondasUsuario > _rondasRival;
    final color = gano ? TemaJuego.dorado : TemaJuego.rojo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            decoration: BoxDecoration(
              color: TemaJuego.fondoPanel,
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
                    style: const TextStyle(color: TemaJuego.textoSuave, fontSize: 14)),
                if (_bonoSinergia > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text('Ventaja táctica por sinergia: +${formatoBono(_bonoSinergia)}',
                        style: const TextStyle(color: TemaJuego.dorado, fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                backgroundColor: TemaJuego.rojo,
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