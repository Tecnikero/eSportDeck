import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/cartas_widgets.dart';
import '../providers/perfil_provider.dart';
import '../core/visual.dart';
import '../core/mecanicas.dart';
import '../core/jugadores.dart';
import '../widgets/panel_pincelado.dart';
import '../widgets/sheets_partida.dart';

const Color _kAzulEvento = Color(0xFF3AA7FF);

const List<String> _rolesPrincipales = ['DUE', 'INI', 'CON', 'CEN'];


class _Tarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borde;

  const _Tarjeta({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borde = TemaJuego.borde,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: TemaJuego.fondoPanel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borde, width: 2.0),
      ),
      child: child,
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
      child: PanelPincelado(
        onTap: onPressed,
        colorBase: activo ? TemaJuego.rojo : Colors.white12,
        colorAcento: activo ? Colors.white : Colors.white24,
        corte: 16,
        grosorBorde: activo ? 2.4 : 1.4,
        gradiente: LinearGradient(
          colors: activo
              ? [TemaJuego.rojo, TemaJuego.rojo.withOpacity(0.85)]
              : [Colors.white12, Colors.white10],
        ),
        child: Center(
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

enum _FaseJuego { draft, agentes, simulando, resultado }

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

  Map<String, String>? _mapaActual;
  final List<String?> _agentesAsignados = List<String?>.filled(5, null);
  double _bonoSinergia = 0;

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
        return SelectorCartasSheet(
          opciones: _opcionesActuales,
          onElegir: (carta) => _elegirCarta(index, carta),
          quimicaPreview: (carta) => quimicaSiSeElige(carta, _seleccionados),
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
      _bonoIdentidadPromedio(_seleccionados) + _bonoSinergiaAgentes();


  Future<void> _mostrarComboTactico() async => mostrarComboTactico(context);

  void _irAAsignarAgentes() {
    if (_seleccionados.length != 5) return;
    setState(() {
      _mapaActual = mapasValorant[_random.nextInt(mapasValorant.length)];
      for (var i = 0; i < _agentesAsignados.length; i++) {
        _agentesAsignados[i] = null;
      }
      _fase = _FaseJuego.agentes;
    });
  }

  Future<void> _mostrarSelectorAgente(int index) async {
    final carta = _casillas[index];
    if (carta == null) return;
    await mostrarSelectorAgente(
      context: context,
      carta: carta,
      rol: rolDe(carta),
      nombreMapa: _mapaActual?['nombre'] ?? '',
      agentesAsignados: _agentesAsignados,
      indiceJugador: index,
      onElegir: (agente) => setState(() => _agentesAsignados[index] = agente),
    );
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
      _bonoSinergia = _bonificacionSinergia();
    });

    try {
      _rosterRival = await _generarRivalIA();

      final miMediaBase = ratingEfectivo(_seleccionados, conQuimica: true);
      final rivalMediaBase = ratingEfectivo(_rosterRival, conQuimica: true);
      final ruidoPartido = (_random.nextDouble() * 6) - 3;
      final ratingPropioBase = miMediaBase + (ruidoPartido / 2) + _bonoSinergia;
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
          final gano1v1 = await _mostrarDueloAim();
          if (gano1v1 != null) {
            resultadoForzadoManual = gano1v1;
            lineaEvento = gano1v1
                ? '¡Duelo 1v1 ganado! El resultado del duelo definió la ronda.'
                : 'El duelo 1v1 se perdió y con él, la ronda.';
          }
        }
        else if (_rachaActual(false) >= 2 && _random.nextDouble() < 0.45) {
          final ganoClutch = await _mostrarClutch();
          if (ganoClutch != null) {
            resultadoForzadoManual = ganoClutch;
            lineaEvento = ganoClutch
                ? '¡Clutch leído a la perfección! El jugador cerró la ronda él solo.'
                : 'La lectura del clutch falló: se enfrentó primero al rival equivocado y la ronda se perdió.';
          }
        }
        else if (_rachaActual(true) >= 2 && _random.nextDouble() < 0.35) {
          final resultado = await _mostrarAntiEco();
          if (resultado is bool) {
            resultadoForzadoManual = resultado;
            lineaEvento = resultado
                ? '¡Rush perfecto al anti-eco! El rival no tuvo tiempo de reaccionar y la ronda cayó.'
                : 'El rush salió mal: el rival defendió mejor de lo esperado y la ronda se perdió.';
          } else if (resultado is double) {
            modificadorPropio += resultado;
            lineaEvento = 'Se jugó con calma y se cerró la ronda sin sobresaltos.';
          }
        }
        else if (_rachaActual(true) >= 3 && _random.nextDouble() < 0.30) {
          final resultado = await _mostrarMomentoAce();
          if (resultado is bool) {
            resultadoForzadoManual = resultado;
            lineaEvento = resultado
                ? '¡ACE! El jugador en racha cerró la ronda él solo.'
                : 'La búsqueda del ace terminó exponiendo al equipo y la ronda se perdió.';
          } else if (resultado is double) {
            modificadorPropio += resultado;
            lineaEvento = 'Se jugó seguro y se cerró la ronda sin arriesgar de más.';
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
          final ratingA = ((a['ovr'] ?? 0) as num) + quimicaDeCarta(a, _seleccionados);
          final ratingB = ((b['ovr'] ?? 0) as num) + quimicaDeCarta(b, _seleccionados);
          return ratingB.compareTo(ratingA);
        });

      final monedas = victoria ? (400 + (_rondaActual * 3)) : (140 + _rondaActual);
      await _pagarMonedas(monedas);

      if (victoria) {
        if (!mounted) return;
        await context.read<PerfilProvider>().agregarSobrePendiente('basico');
      }

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
      for (var i = 0; i < _agentesAsignados.length; i++) {
        _agentesAsignados[i] = null;
      }
      _mapaActual = null;
      _bonoSinergia = 0;
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
            color: TemaJuego.fondoPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: TemaJuego.dorado, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: TemaJuego.dorado, size: 30),
              const SizedBox(height: 8),
              const Text(
                'GANASTE LA PISTOLA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              const Text(
                '¿Cómo administras la economía para la ronda 2?',
                textAlign: TextAlign.center,
                style: TextStyle(color: TemaJuego.textoSuave, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              _opcionEvento(
                icono: Icons.bolt,
                color: TemaJuego.rojo,
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

  Future<bool?> _mostrarDueloAim() async {
    if (_seleccionados.isEmpty || _rosterRival.isEmpty) return null;
    final nuestro = _seleccionados[_random.nextInt(_seleccionados.length)];
    final rival = _rosterRival[_random.nextInt(_rosterRival.length)];

    final aimNuestro = ((nuestro['aim'] ?? 50) as num).toDouble();
    final aimRival = ((rival['aim'] ?? 50) as num).toDouble();
    final ruido = _random.nextDouble() * 14 - 7;
    final ganaNuestro = (aimNuestro + ruido) >= aimRival;

    return showModalBottomSheet<bool>(
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

              Future.delayed(const Duration(milliseconds: 1100), () {
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop(acerto);
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
                color: TemaJuego.fondoPanel,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _kAzulEvento, width: 2.5),
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
                            ? '¡Ganaste el duelo como el claro underdog! La ronda es tuya.'
                            : (acerto! ? '¡Ganaste el duelo! La ronda es tuya.' : 'Perdiste el duelo. La ronda se pierde.'))
                        : 'El AIM de ambos está oculto. ¿Quién gana el duelo?\nEsto define el resultado de la ronda.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: TemaJuego.textoSuave, fontSize: 12.5),
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
                          colorDestacado: TemaJuego.dorado,
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
                          colorDestacado: TemaJuego.rojo,
                        ),
                      ),
                    ],
                  ),
                  if (revelado) ...[
                    const SizedBox(height: 26),
                    _BannerResultadoEvento(
                      acerto: acerto!,
                      textoAcerto: espalda ? '¡JUGADA POR LA ESPALDA! RONDA GANADA' : 'RONDA GANADA',
                      textoFalla: 'RONDA PERDIDA',
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

  Future<bool?> _mostrarClutch() async {
    if (_rosterRival.isEmpty || _seleccionados.isEmpty) return null;
    final numRivales = (_rosterRival.length >= 3 && _random.nextBool()) ? 3 : min(2, _rosterRival.length);
    final rivales = (List<Map<String, dynamic>>.from(_rosterRival)..shuffle(_random)).take(numRivales).toList();
    final clus = rivales.map((r) => ((r['clu'] ?? 50) as num).toDouble()).toList();
    final indiceMasDebil = clus.indexOf(clus.reduce(min));

    final ordenPorClutch = List<Map<String, dynamic>>.from(_seleccionados)
      ..sort((a, b) => (((b['clu'] ?? 0) as num)).compareTo((a['clu'] ?? 0) as num));
    final clutcher = ordenPorClutch.first;
    final clutcherClu = ((clutcher['clu'] ?? 50) as num).toDouble();

    return showModalBottomSheet<bool>(
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

              final acerto = i == indiceMasDebil;
              Future.delayed(const Duration(milliseconds: 1100), () {
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop(acerto);
                }
              });
            }

            final acerto = elegido == null ? null : elegido == indiceMasDebil;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: TemaJuego.fondoPanel,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: TemaJuego.rojo, width: 2.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: TemaJuego.rojo, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    'CLUTCH 1v$numRivales',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    revelado
                        ? (acerto! ? '¡CLUTCH GANADO! La ronda es tuya.' : 'Te enfrentaste al rival equivocado. Ronda perdida.')
                        : 'La estadística CLUTCH de los rivales está oculta.\n¿A cuál enfrentas primero? El resultado define la ronda.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: TemaJuego.textoSuave, fontSize: 12.5),
                  ),
                  const SizedBox(height: 20),

                  _CartaConStatOculta(
                    jugador: clutcher,
                    etiquetaStat: 'CLU',
                    valorStat: clutcherClu,
                    width: 100,
                    revelado: true,
                    destacado: revelado && acerto == true,
                    colorDestacado: TemaJuego.dorado,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      'TU CLUTCHER',
                      style: TextStyle(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                  const Icon(Icons.arrow_downward_rounded, color: Colors.white24, size: 18),
                  const SizedBox(height: 10),

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
                          width: 90,
                          revelado: revelado,
                          destacado: revelado && i == indiceMasDebil,
                          colorDestacado: TemaJuego.dorado,
                        ),
                      );
                    }),
                  ),
                  if (revelado) ...[
                    const SizedBox(height: 22),
                    _BannerResultadoEvento(
                      acerto: acerto!,
                      textoAcerto: 'RONDA GANADA',
                      textoFalla: 'RONDA PERDIDA',
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

  Future<dynamic> _mostrarAntiEco() {
    return showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: TemaJuego.fondoPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _kAzulEvento, width: 2.5),
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
                style: TextStyle(color: TemaJuego.textoSuave, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              _opcionEvento(
                icono: Icons.flash_on,
                color: TemaJuego.rojo,
                titulo: 'RUSHEAR EL SITIO',
                subtitulo: '65% de ganar la ronda al instante.\nSi sale mal, la ronda se pierde directo.',
                onTap: () => Navigator.of(context).pop(_random.nextDouble() < 0.65),
              ),
              const SizedBox(height: 12),
              _opcionEvento(
                icono: Icons.shield_moon,
                color: _kAzulEvento,
                titulo: 'JUGAR CON CALMA',
                subtitulo: 'Ventaja pequeña pero garantizada,\nsin arriesgar la ronda.',
                onTap: () => Navigator.of(context).pop(0.8),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<dynamic> _mostrarMomentoAce() {
    return showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 30 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: TemaJuego.fondoPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: TemaJuego.dorado, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, color: TemaJuego.dorado, size: 30),
              const SizedBox(height: 8),
              const Text(
                'MOMENTO CALIENTE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              const Text(
                'El equipo está en racha. ¿Buscas el ace o cierras la ronda seguro?',
                textAlign: TextAlign.center,
                style: TextStyle(color: TemaJuego.textoSuave, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              _opcionEvento(
                icono: Icons.emoji_events,
                color: TemaJuego.dorado,
                titulo: 'BUSCAR EL ACE',
                subtitulo: '50% de ganar la ronda con gloria total.\n50% de quedar expuesto y perderla.',
                onTap: () => Navigator.of(context).pop(_random.nextDouble() < 0.5),
              ),
              const SizedBox(height: 12),
              _opcionEvento(
                icono: Icons.check_circle_outline,
                color: _kAzulEvento,
                titulo: 'CERRAR SEGURO',
                subtitulo: 'Ventaja pequeña pero garantizada,\nsin arriesgar la ronda.',
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
          color: TemaJuego.fondo,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.6), width: 2.0),
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
      backgroundColor: TemaJuego.fondo,
      appBar: AppBar(
        title: const Text('PARTIDA COMPLETA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
                  border: Border.all(color: TemaJuego.rojo.withOpacity(0.6), width: 2.5),
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
          child: EncabezadoSheet(
            icono: Icons.stadium,
            titulo: 'ARMA TU EQUIPO',
            subtitulo: 'Simulación real a 13 rondas con eventos en vivo. Toca una casilla y elige un jugador.',
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(_error!, style: const TextStyle(color: TemaJuego.rojo), textAlign: TextAlign.center),
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
            texto: equipoCompleto ? 'ASIGNAR AGENTES' : '${_seleccionados.length}/5 jugadores elegidos',
            onPressed: equipoCompleto ? _irAAsignarAgentes : null,
          ),
        ),
      ],
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
          child: EncabezadoSheet(
            icono: Icons.map_outlined,
            titulo: 'MAPA: ${nombreMapa.toUpperCase()}',
            color: TemaJuego.dorado,
            subtitulo:
                'Elige un agente por jugador. Busca sinergias de habilidades.',
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
            texto: todosAsignados ? 'JUGAR PARTIDA COMPLETA' : 'Agentes asignados: $asignados/5',
            onPressed: todosAsignados ? _jugarPartida : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCasillaAgente(int index) {
    final carta = _casillas[index]!;
    final agenteActual = _agentesAsignados[index];

    return SizedBox(
      width: 100,
      child: GestureDetector(
        onTap: () => _mostrarSelectorAgente(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: TemaJuego.dorado.withOpacity(0.4), blurRadius: 8)],
              ),
              child: CartaWidget(jugador: carta, width: 100),
            ),
            const SizedBox(height: 6),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TemaJuego.fondo,
                border: Border.all(
                  color: agenteActual == null ? Colors.white24 : TemaJuego.rojoOscuro,
                  width: 2.5,
                ),
              ),
              child: agenteActual == null
                  ? const Icon(Icons.add, color: Colors.white38, size: 20)
                  : ClipOval(
                      child: Image.asset(
                        rutaAgente(agenteActual),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: TemaJuego.dorado.withOpacity(0.35), blurRadius: 8)],
                    ),
                    child: CartaWidget(jugador: carta, width: 100),
                  ),
                  const SizedBox(height: 5),
                  _puntitosQuimica(quimicaDeCarta(carta, _seleccionados)),
                ],
              )
            : AspectRatio(
                aspectRatio: 626 / 794,
                child: Container(
                  decoration: BoxDecoration(
                    color: TemaJuego.fondoPanel,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: TemaJuego.borde, width: 2.5),
                  ),
                  child: Center(
                    child: estaRevelando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: TemaJuego.rojo, strokeWidth: 2),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: TemaJuego.rojo.withOpacity(0.12),
                                  border: Border.all(color: TemaJuego.rojo.withOpacity(0.5), width: 2.0),
                                ),
                                child: Icon(Icons.add, color: TemaJuego.rojo.withOpacity(0.9), size: 20),
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
    final rolesPresentes = _seleccionados.map(rolDe).toSet();
    final rolesOk = _rolesPrincipales.where(rolesPresentes.contains).length;
    final regionOk = _seleccionados.any(
        (j) => regionDe(j).isNotEmpty && _seleccionados.where((k) => regionDe(k) == regionDe(j)).length > 1);
    final equipoOk = _seleccionados.any(
        (j) => equipoDe(j).isNotEmpty && _seleccionados.where((k) => equipoDe(k) == equipoDe(j)).length > 1);

    return _Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              Text('${quimicaTotalEquipo(_seleccionados)}/15', style: const TextStyle(color: TemaJuego.dorado, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (quimicaTotalEquipo(_seleccionados) / 15).clamp(0, 1).toDouble(),
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activo ? TemaJuego.dorado : Colors.transparent,
              border: Border.all(color: activo ? TemaJuego.dorado : Colors.white30, width: 1.8),
              boxShadow: activo ? [BoxShadow(color: TemaJuego.dorado.withOpacity(0.6), blurRadius: 4)] : null,
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
        Container(color: TemaJuego.fondo),
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
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _enProrroga ? TemaJuego.dorado.withOpacity(0.6) : Colors.white12, width: 2.0),
          ),
          child: Column(
            children: [
              if (_enProrroga)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    '¡PRÓRROGA! · SE NECESITA DIFERENCIA DE 2',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TemaJuego.dorado, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                  ),
                ),
              Text(
                nombreMapa.isEmpty ? 'PRIMERO EN LLEGAR A $_rondasParaGanar RONDAS' : 'MAPA · $nombreMapa',
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
                  _escudoEquipo(icono: Icons.shield, color: TemaJuego.rojo, etiqueta: 'TÚ'),
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
                          color: TemaJuego.fondoPanel,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: TemaJuego.dorado.withOpacity(0.5), width: 2.0),
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
            border: Border.all(color: color, width: 2.5),
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
              border: Border.all(color: esActual ? TemaJuego.cian : Colors.white38, width: 2.3),
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
                borderRadius: BorderRadius.circular(2),
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
        if (rachaJugador >= 3)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('¡Tu equipo está en racha! +1 de impulso',
                style: TextStyle(color: TemaJuego.dorado, fontSize: 11.5, fontWeight: FontWeight.bold)),
          )
        else if (rachaRival >= 3)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('El rival está en racha, -1 a tu equipo',
                style: TextStyle(color: TemaJuego.rojo, fontSize: 11.5, fontWeight: FontWeight.bold)),
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
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white12, width: 2.0),
        ),
        child: const Center(
          child: Text('La partida está por comenzar...', style: TextStyle(color: Colors.white38, fontSize: 12.5)),
        ),
      );
    }

    final enVivo = identical(evento, _rondaEnVivo);
    final gano = evento['gano'] as bool? ?? false;
    final ronda = evento['ronda'] as int;
    final enProrroga = evento['prorroga'] == true;
    final lineas = (evento['lineas'] as List).cast<String>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('$ronda-${lineas.length}-$enVivo'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: enProrroga ? TemaJuego.dorado.withOpacity(0.5) : Colors.white12, width: 2.0),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TemaJuego.fondo,
                border: Border.all(color: enProrroga ? TemaJuego.dorado : TemaJuego.cian, width: 2.5),
              ),
              child: Icon(
                enVivo ? Icons.bolt : (gano ? Icons.check : Icons.close),
                color: enProrroga ? TemaJuego.dorado : TemaJuego.cian,
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              enVivo
                  ? 'RONDA $ronda${enProrroga ? ' · PRÓRROGA' : ''} · EN JUEGO'
                  : 'RONDA $ronda${enProrroga ? ' (PRÓRROGA)' : ''} · ${gano ? 'GANADA' : 'PERDIDA'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enProrroga ? TemaJuego.dorado : TemaJuego.cian,
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
    final nombreMapa = _mapaActual?['nombre'] ?? '';
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
    final color = _victoria ? TemaJuego.dorado : TemaJuego.rojo;
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
                  style: const TextStyle(color: TemaJuego.textoSuave, fontSize: 14.5),
                ),
                if (_bonoSinergia > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Ventaja táctica por sinergia: +${formatoBono(_bonoSinergia)}',
                      style: const TextStyle(color: TemaJuego.dorado, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: TemaJuego.dorado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: TemaJuego.dorado.withOpacity(0.4), width: 2.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: TemaJuego.dorado, size: 20),
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
                  _puntitosQuimica(quimicaDeCarta(_mvp!, _seleccionados)),
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
    this.colorDestacado = TemaJuego.dorado,
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
                borderRadius: BorderRadius.circular(3),
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
                    color: TemaJuego.fondo,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: revelado && destacado ? colorDestacado : Colors.white38,
                      width: 2.5,
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
    final color = acerto ? TemaJuego.dorado : TemaJuego.rojo;
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
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.6), width: 2.2),
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