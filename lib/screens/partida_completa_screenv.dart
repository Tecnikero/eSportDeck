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
const Color _kAzulEvento = Color(0xFF3AA7FF);

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
  final Color color;

  const _BotonPrincipal({required this.texto, required this.onPressed, this.color = _kRojo});

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
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
  '{jugador} clucheó la ronda',
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

enum _FaseJuego { draft, simulando, resultado }

class PartidaCompletaScreen extends StatefulWidget {
  const PartidaCompletaScreen({super.key});

  @override
  State<PartidaCompletaScreen> createState() => _PartidaCompletaScreenState();
}

class _PartidaCompletaScreenState extends State<PartidaCompletaScreen> {
  final supabase = Supabase.instance.client;
  final _random = Random();

  _FaseJuego _fase = _FaseJuego.draft;
  String? _error;

  final List<Map<String, dynamic>?> _casillas = List<Map<String, dynamic>?>.filled(5, null);
  bool _revelando = false;
  int? _casillaEnRevelacion;
  List<Map<String, dynamic>> _opcionesActuales = [];

  List<Map<String, dynamic>> get _seleccionados =>
      _casillas.whereType<Map<String, dynamic>>().toList();

  List<Map<String, dynamic>> _rosterRival = [];

  static const int _rondasParaGanar = 13;
  int _rondasJugador = 0;
  int _rondasIA = 0;
  int _rondaActual = 0;
  final List<bool> _historialRondas = [];
  final List<Map<String, dynamic>> _timelineEventos = [];
  bool _resolviendoRonda = false;
  Map<String, dynamic>? _rondaEnVivo;
  bool _enProrroga = false;

  final Map<int, bool> _resultadoForzado = {};
  bool _penalizacionRonda3 = false;

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
      debugPrint('ERROR AL REVELAR CASILLA (partida completa): $e');
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

  String _rol(Map<String, dynamic> j) => '${j['posicion'] ?? ''}'.trim().toUpperCase();
  String _region(Map<String, dynamic> j) => '${j['region'] ?? ''}'.trim().toLowerCase();
  String _equipo(Map<String, dynamic> j) => '${j['equipo'] ?? ''}'.trim().toLowerCase();
  String _pais(Map<String, dynamic> j) => '${j['pais'] ?? ''}'.trim().toLowerCase();

  static const int _quimicaObjetivosMax = 4;
  static const double _quimicaPuntosPorObjetivo = 0.5;

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

  Future<List<Map<String, dynamic>>> _generarRivalIA() async {
    final catalogo = await supabase.from('jugadores').select();
    var pool = List<Map<String, dynamic>>.from(catalogo as List);
    pool.shuffle(_random);
    if (pool.length < 5) {
      throw Exception('El catálogo no tiene suficientes jugadores para generar un rival.');
    }
    return pool.take(5).toList();
  }

  bool _partidaTerminada() {
    if (_rondasJugador >= 12 && _rondasIA >= 12) {
      return (_rondasJugador - _rondasIA).abs() >= 2;
    }
    return _rondasJugador == _rondasParaGanar || _rondasIA == _rondasParaGanar;
  }

  Future<void> _jugarPartida() async {
    if (_seleccionados.length != 5) return;

    setState(() {
      _error = null;
      _fase = _FaseJuego.simulando;
      _rondasJugador = 0;
      _rondasIA = 0;
      _rondaActual = 0;
      _historialRondas.clear();
      _timelineEventos.clear();
      _rondaEnVivo = null;
      _enProrroga = false;
      _resultadoForzado.clear();
      _penalizacionRonda3 = false;
    });

    try {
      _rosterRival = await _generarRivalIA();

      final miMediaBase = _ratingEfectivo(_seleccionados, conQuimica: true);
      final rivalMediaBase = _ratingEfectivo(_rosterRival, conQuimica: true);
      final ruidoPartido = (_random.nextDouble() * 6) - 3;
      final ratingPropioBase = miMediaBase + (ruidoPartido / 2);
      final ratingRivalBase = rivalMediaBase - (ruidoPartido / 2);

      while (!_partidaTerminada()) {
        final numeroRonda = _rondaActual + 1;
        final enProrrogaAhora = _rondasJugador >= 12 && _rondasIA >= 12;

        setState(() {
          _rondaActual = numeroRonda;
          _resolviendoRonda = true;
          _enProrroga = enProrrogaAhora;
          _rondaEnVivo = {'ronda': numeroRonda, 'lineas': <String>[]};
        });

        double modificadorPropio = 0;
        String? lineaEvento;
        bool? resultadoForzadoManual;

        if (numeroRonda == 2 && _historialRondas.isNotEmpty && _historialRondas[0] == true) {
          final decision = await _mostrarDecisionEconomica();
          if (decision == 'forzar') {
            final exito = _random.nextDouble() < 0.70;
            resultadoForzadoManual = exito;
            if (!exito) _penalizacionRonda3 = true;
            lineaEvento = exito
                ? 'Compra forzada: el equipo se arriesgó y la jugada salió perfecta.'
                : 'Compra forzada: el armamento a medias no fue suficiente.';
          } else if (decision == 'eco') {
            resultadoForzadoManual = false;
            _resultadoForzado[3] = true;
            lineaEvento = 'Eco: se sacrificó la ronda para asegurar la número 3 con full-buy.';
          }
        }
        else if (numeroRonda == 3 && _resultadoForzado.containsKey(3)) {
          resultadoForzadoManual = _resultadoForzado[3];
          lineaEvento = 'El full-buy del eco se sintió: equipo completo y confiado.';
        } else if (numeroRonda == 3 && _penalizacionRonda3) {
          final derrota = _random.nextDouble() < 0.80;
          resultadoForzadoManual = !derrota;
          _penalizacionRonda3 = false;
          lineaEvento = derrota
              ? 'El golpe económico del force pasó la cuenta: ronda perdida con poco armamento.'
              : 'Contra todo pronóstico, el equipo remontó con lo justo.';
        }
        else if (numeroRonda != 1 && numeroRonda != 13 && _random.nextDouble() < 0.30) {
          final resultado = await _mostrarDueloAim();
          if (resultado != null) {
            modificadorPropio += resultado;
            lineaEvento = resultado >= 3
                ? '¡Jugada táctica por la espalda! El duelo se ganó como el claro underdog.'
                : (resultado > 0
                    ? 'El duelo 1v1 se leyó correctamente.'
                    : 'La apuesta del duelo 1v1 no se cumplió.');
          }
        }
        else if (_rachaActual(false) >= 2 && _random.nextDouble() < 0.45) {
          final resultado = await _mostrarClutch();
          if (resultado != null) {
            modificadorPropio += resultado;
            lineaEvento = resultado > 0
                ? '¡Clutch leído a la perfección! Cayó primero el rival más débil.'
                : 'La lectura del clutch falló: se enfrentó primero al rival equivocado.';
          }
        }
        else if (_rachaActual(true) >= 2 && _random.nextDouble() < 0.35) {
          final resultado = await _mostrarAntiEco();
          if (resultado != null) {
            modificadorPropio += resultado;
            lineaEvento = resultado >= 3
                ? '¡Rush perfecto al anti-eco! El rival no tuvo tiempo de reaccionar.'
                : (resultado > 0
                    ? 'Se jugó con calma y se cerró la ronda sin sobresaltos.'
                    : 'El rush salió mal: el rival defendió mejor de lo esperado.');
          }
        }
        else if (_rachaActual(true) >= 3 && _random.nextDouble() < 0.30) {
          final resultado = await _mostrarMomentoAce();
          if (resultado != null) {
            modificadorPropio += resultado;
            lineaEvento = resultado >= 4
                ? '¡ACE! El jugador en racha cerró la ronda él solo.'
                : (resultado > 0
                    ? 'Se jugó seguro y se cerró la ronda sin arriesgar de más.'
                    : 'La búsqueda del ace terminó exponiendo al equipo.');
          }
        }

        bool ganeLaRonda;
        if (resultadoForzadoManual != null) {
          ganeLaRonda = resultadoForzadoManual;
        } else {
          final rachaJugador = _rachaActual(true);
          final rachaRival = _rachaActual(false);
          final momentumJugador = rachaJugador >= 3 ? 1 : (rachaRival >= 3 ? -1 : 0);
          final momentumRival = rachaRival >= 3 ? 1 : (rachaJugador >= 3 ? -1 : 0);
          var miPuntaje =
              ratingPropioBase + momentumJugador + modificadorPropio + (_random.nextInt(13) - 6);
          var rivalPuntaje = ratingRivalBase + momentumRival + (_random.nextInt(13) - 6);

          if (_random.nextInt(100) < 8) {
            final golpe = 6 + _random.nextInt(7);
            if (_random.nextBool()) {
              miPuntaje += golpe;
            } else {
              rivalPuntaje += golpe;
            }
          }

          ganeLaRonda = miPuntaje == rivalPuntaje ? _random.nextBool() : miPuntaje > rivalPuntaje;
        }

        final equipoGanador = ganeLaRonda ? _seleccionados : _rosterRival;
        final equipoPerdedor = ganeLaRonda ? _rosterRival : _seleccionados;
        final heroe = '${equipoGanador[_random.nextInt(equipoGanador.length)]['nombre'] ?? 'Jugador'}';
        final caido = '${equipoPerdedor[_random.nextInt(equipoPerdedor.length)]['nombre'] ?? 'Rival'}';
        final lineaHeroe =
            _eventosPositivos[_random.nextInt(_eventosPositivos.length)].replaceAll('{jugador}', heroe);
        final lineaCaido =
            _eventosNegativos[_random.nextInt(_eventosNegativos.length)].replaceAll('{jugador}', caido);

        final lineasRonda = [
          if (lineaEvento != null) lineaEvento,
          lineaHeroe,
          lineaCaido,
        ];

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() {
          _rondaEnVivo = {'ronda': numeroRonda, 'lineas': lineasRonda.take(1).toList()};
        });

        await Future.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        setState(() {
          _rondaEnVivo = {'ronda': numeroRonda, 'lineas': lineasRonda};
        });

        await Future.delayed(const Duration(milliseconds: 550));
        if (!mounted) return;

        setState(() {
          _resolviendoRonda = false;
          _rondaEnVivo = null;
          _historialRondas.add(ganeLaRonda);
          _timelineEventos.add({
            'ronda': numeroRonda,
            'gano': ganeLaRonda,
            'lineas': lineasRonda,
            'prorroga': enProrrogaAhora,
          });
          if (ganeLaRonda) {
            _rondasJugador += 1;
          } else {
            _rondasIA += 1;
          }
        });

        await Future.delayed(const Duration(milliseconds: 550));
        if (!mounted) return;
      }

      final victoria = _rondasJugador > _rondasIA;

      final mvp = List<Map<String, dynamic>>.from(_seleccionados)
        ..sort((a, b) {
          final ratingA = ((a['ovr'] ?? 0) as num) + _quimicaDeCarta(a);
          final ratingB = ((b['ovr'] ?? 0) as num) + _quimicaDeCarta(b);
          return ratingB.compareTo(ratingA);
        });

      final monedas = victoria ? (400 + (_rondaActual * 3)) : (140 + _rondaActual);
      await _pagarMonedas(monedas);

      if (!mounted) return;
      setState(() {
        _victoria = victoria;
        _monedasGanadas = monedas;
        _mvp = mvp.first;
        _fase = _FaseJuego.resultado;
      });
    } catch (e) {
      debugPrint('ERROR EN PARTIDA COMPLETA: $e');
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

  void _jugarDeNuevo() {
    setState(() {
      for (var i = 0; i < _casillas.length; i++) {
        _casillas[i] = null;
      }
      _rosterRival = [];
      _timelineEventos.clear();
      _rondaEnVivo = null;
      _enProrroga = false;
      _fase = _FaseJuego.draft;
    });
  }

  Future<String?> _mostrarDecisionEconomica() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: _kFondoPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _kDorado, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: _kDorado, size: 30),
              const SizedBox(height: 8),
              const Text(
                'GANASTE LA PISTOLA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              const Text(
                '¿Cómo administras la economía para la ronda 2?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextoSuave, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              _opcionEvento(
                icono: Icons.bolt,
                color: _kRojo,
                titulo: 'FORZAR COMPRA',
                subtitulo: '70% de ganar la ronda 2 ahora mismo.\nSi falla, la ronda 3 queda muy comprometida.',
                onTap: () => Navigator.of(context).pop('forzar'),
              ),
              const SizedBox(height: 12),
              _opcionEvento(
                icono: Icons.savings,
                color: _kAzulEvento,
                titulo: 'HACER ECO',
                subtitulo: 'Se pierde la ronda 2 a propósito,\npero la ronda 3 queda asegurada con full-buy.',
                onTap: () => Navigator.of(context).pop('eco'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double?> _mostrarDueloAim() async {
    if (_seleccionados.isEmpty || _rosterRival.isEmpty) return null;
    final nuestro = _seleccionados[_random.nextInt(_seleccionados.length)];
    final rival = _rosterRival[_random.nextInt(_rosterRival.length)];

    final aimNuestro = ((nuestro['aim'] ?? 50) as num).toDouble();
    final aimRival = ((rival['aim'] ?? 50) as num).toDouble();
    final ruido = _random.nextDouble() * 14 - 7;
    final ganaNuestro = (aimNuestro + ruido) >= aimRival;

    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        String? elegido;
        bool revelado = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void elegir(String opcion) {
              if (elegido != null) return;
              setSheetState(() {
                elegido = opcion;
                revelado = true;
              });

              final acerto = (opcion == 'nuestro' && ganaNuestro) || (opcion == 'rival' && !ganaNuestro);
              double resultado;
              if (!acerto) {
                resultado = -1.5;
              } else if (opcion == 'nuestro' && aimNuestro < aimRival) {
                resultado = 3.5;
              } else {
                resultado = 1.2;
              }

              Future.delayed(const Duration(milliseconds: 1100), () {
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop(resultado);
                }
              });
            }

            final acerto = elegido == null
                ? null
                : (elegido == 'nuestro' && ganaNuestro) || (elegido == 'rival' && !ganaNuestro);
            final espalda = acerto == true && elegido == 'nuestro' && aimNuestro < aimRival;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: _kFondoPanel,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _kAzulEvento, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gps_fixed, color: _kAzulEvento, size: 28),
                  const SizedBox(height: 8),
                  const Text(
                    'DUELO 1v1',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    revelado
                        ? (espalda
                            ? '¡Leíste el duelo como el claro underdog!'
                            : (acerto! ? 'Leíste bien el duelo.' : 'No acertaste el duelo.'))
                        : 'El AIM de ambos está oculto. ¿Quién gana el duelo?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _kTextoSuave, fontSize: 12.5),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => elegir('nuestro'),
                        child: _CartaConStatOculta(
                          jugador: nuestro,
                          etiquetaStat: 'AIM',
                          valorStat: aimNuestro,
                          width: 112,
                          revelado: revelado,
                          destacado: revelado && ganaNuestro,
                          colorDestacado: _kDorado,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 42.0),
                        child: Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () => elegir('rival'),
                        child: _CartaConStatOculta(
                          jugador: rival,
                          etiquetaStat: 'AIM',
                          valorStat: aimRival,
                          width: 112,
                          revelado: revelado,
                          destacado: revelado && !ganaNuestro,
                          colorDestacado: _kRojo,
                        ),
                      ),
                    ],
                  ),
                  if (revelado) ...[
                    const SizedBox(height: 26),
                    _BannerResultadoEvento(
                      acerto: acerto!,
                      textoAcerto: espalda ? '¡JUGADA POR LA ESPALDA!' : 'ACERTASTE EL DUELO',
                      textoFalla: 'NO ACERTASTE',
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<double?> _mostrarClutch() async {
    if (_rosterRival.isEmpty) return null;
    final numRivales = (_rosterRival.length >= 3 && _random.nextBool()) ? 3 : min(2, _rosterRival.length);
    final rivales = (List<Map<String, dynamic>>.from(_rosterRival)..shuffle(_random)).take(numRivales).toList();
    final clus = rivales.map((r) => ((r['clu'] ?? 50) as num).toDouble()).toList();
    final indiceMasDebil = clus.indexOf(clus.reduce(min));

    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        int? elegido;
        bool revelado = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void elegir(int i) {
              if (elegido != null) return;
              setSheetState(() {
                elegido = i;
                revelado = true;
              });

              final resultado = i == indiceMasDebil ? 2.2 : -1.0;
              Future.delayed(const Duration(milliseconds: 1100), () {
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop(resultado);
                }
              });
            }

            final acerto = elegido == null ? null : elegido == indiceMasDebil;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: _kFondoPanel,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _kRojo, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: _kRojo, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    'CLUTCH 1v$numRivales',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    revelado
                        ? (acerto! ? '¡Leíste bien al rival más débil!' : 'Te enfrentaste al rival equivocado.')
                        : 'La estadística CLUTCH de los rivales está oculta.\n¿A cuál enfrentas primero?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _kTextoSuave, fontSize: 12.5),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 28,
                    children: List.generate(numRivales, (i) {
                      return GestureDetector(
                        onTap: () => elegir(i),
                        child: _CartaConStatOculta(
                          jugador: rivales[i],
                          etiquetaStat: 'CLU',
                          valorStat: clus[i],
                          width: 96,
                          revelado: revelado,
                          destacado: revelado && i == indiceMasDebil,
                          colorDestacado: _kDorado,
                        ),
                      );
                    }),
                  ),
                  if (revelado) ...[
                    const SizedBox(height: 26),
                    _BannerResultadoEvento(
                      acerto: acerto!,
                      textoAcerto: '¡CLUTCH GANADO!',
                      textoFalla: 'CLUTCH PERDIDO',
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<double?> _mostrarAntiEco() {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: _kFondoPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _kAzulEvento, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.speed, color: _kAzulEvento, size: 28),
              const SizedBox(height: 8),
              const Text(
                'LECTURA DE ANTI-ECO',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              const Text(
                'El rival viene de una mala racha económica. ¿Cómo lo aprovechas?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextoSuave, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              _opcionEvento(
                icono: Icons.flash_on,
                color: _kRojo,
                titulo: 'RUSHEAR EL SITIO',
                subtitulo: 'Alto riesgo: si sale bien, ventaja grande.\nSi sale mal, el equipo queda expuesto.',
                onTap: () => Navigator.of(context).pop(_random.nextDouble() < 0.65 ? 3.2 : -2.0),
              ),
              const SizedBox(height: 12),
              _opcionEvento(
                icono: Icons.shield_moon,
                color: _kAzulEvento,
                titulo: 'JUGAR CON CALMA',
                subtitulo: 'Ventaja pequeña pero garantizada.',
                onTap: () => Navigator.of(context).pop(0.8),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double?> _mostrarMomentoAce() {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: _kFondoPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _kDorado, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, color: _kDorado, size: 30),
              const SizedBox(height: 8),
              const Text(
                'MOMENTO CALIENTE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              const Text(
                'El equipo está en racha. ¿Buscas el ace o cierras la ronda seguro?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextoSuave, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              _opcionEvento(
                icono: Icons.emoji_events,
                color: _kDorado,
                titulo: 'BUSCAR EL ACE',
                subtitulo: '50% de gloria total, 50% de quedar expuesto.',
                onTap: () => Navigator.of(context).pop(_random.nextDouble() < 0.5 ? 4.2 : -2.0),
              ),
              const SizedBox(height: 12),
              _opcionEvento(
                icono: Icons.check_circle_outline,
                color: _kAzulEvento,
                titulo: 'CERRAR SEGURO',
                subtitulo: 'Ventaja pequeña pero garantizada.',
                onTap: () => Navigator.of(context).pop(0.8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _opcionEvento({
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kFondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.6)),
                  const SizedBox(height: 3),
                  Text(subtitulo, style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text('PARTIDA COMPLETA',
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
            icono: Icons.stadium,
            titulo: 'ARMA TU EQUIPO',
            subtitulo: 'Simulación real a 13 rondas con eventos en vivo. Toca una casilla y elige un jugador.',
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
            texto: equipoCompleto ? 'JUGAR PARTIDA COMPLETA' : '${_seleccionados.length}/5 jugadores elegidos',
            onPressed: equipoCompleto ? _jugarPartida : null,
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
    return Container(
      color: _kFondo,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Tarjeta(
                borde: _enProrroga ? _kDorado : _kRojoOscuro,
                child: Column(
                  children: [
                    if (_enProrroga)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6.0),
                        child: Text('¡PRÓRROGA!',
                            style: TextStyle(color: _kDorado, fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
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
                      _enProrroga
                          ? 'Se necesita diferencia de 2 rondas para ganar'
                          : 'Primero en llegar a $_rondasParaGanar rondas gana',
                      style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _rondaActual == 0 ? 'Preparando la partida...' : 'Ronda $_rondaActual',
                      style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    _buildIndicadorMomentum(),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildTimeline(),
            ],
          ),
        ),
      ),
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
        child: Text('El rival está en racha, -1 a tu equipo', style: TextStyle(color: _kRojo, fontSize: 12, fontWeight: FontWeight.bold)),
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
      constraints: const BoxConstraints(maxHeight: 300),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
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
    final enProrroga = evento['prorroga'] == true;
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
              'RONDA $ronda${enProrroga ? ' (PRÓRROGA)' : ''} · ${gano ? 'GANADA' : 'PERDIDA'}',
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
          const Icon(Icons.stadium, color: _kRojo, size: 28),
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

class _CartaConStatOculta extends StatelessWidget {
  final Map<String, dynamic> jugador;
  final String etiquetaStat;
  final num valorStat;
  final double width;
  final bool revelado;
  final bool destacado;
  final Color colorDestacado;

  const _CartaConStatOculta({
    required this.jugador,
    required this.etiquetaStat,
    required this.valorStat,
    required this.width,
    required this.revelado,
    this.destacado = false,
    this.colorDestacado = _kDorado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (destacado ? colorDestacado : Colors.black).withOpacity(destacado ? 0.55 : 0.25),
                    blurRadius: destacado ? 16 : 8,
                  ),
                ],
              ),
              child: CartaWidget(jugador: jugador, width: width, mostrarStats: false),
            ),
            Positioned(
              bottom: -16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey(revelado),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kFondo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: revelado && destacado ? colorDestacado : Colors.white38,
                      width: 1.5,
                    ),
                    boxShadow: revelado && destacado
                        ? [BoxShadow(color: colorDestacado.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$etiquetaStat  ',
                          style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      Text(
                        revelado ? '${valorStat.round()}' : '?',
                        style: TextStyle(
                          color: revelado ? (destacado ? colorDestacado : Colors.white) : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: width,
          child: Text(
            '${jugador['nombre'] ?? ''}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _BannerResultadoEvento extends StatelessWidget {
  final bool acerto;
  final String textoAcerto;
  final String textoFalla;

  const _BannerResultadoEvento({
    required this.acerto,
    required this.textoAcerto,
    required this.textoFalla,
  });

  @override
  Widget build(BuildContext context) {
    final color = acerto ? _kDorado : _kRojo;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, valor, child) {
        return Opacity(
          opacity: valor,
          child: Transform.scale(scale: 0.9 + (0.1 * valor), child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.6), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(acerto ? Icons.check_circle : Icons.cancel, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              acerto ? textoAcerto : textoFalla,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}