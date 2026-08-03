import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/carta_widget.dart';
import '../providers/perfil_provider.dart';
import 'torneo_partido_screenv.dart';

const Color _kFondo = Color(0xFF0A0A0A);
const Color _kFondoPanel = Color(0xFF1A0E0E);
const Color _kRojo = Color(0xFFE30425);
const Color _kDorado = Color(0xFFFFD700);
const Color _kAzulUpper = Color(0xFF3B82F6);
const Color _kMoradoLower = Color(0xFF9B59B6);

const int _rondasParaGanar = 5;
const int _premioMonedas = 2500;

const double _kCardW = 190;
const double _kCardH = 56;
const double _kColGap = 50;
const double _kRowGap = 14;
const double _kSectionGap = 60;
const double _kHeaderH = 26;

class _Equipo {
  final String nombre;
  final List<Map<String, dynamic>> jugadores;
  final bool esUsuario;

  _Equipo({required this.nombre, required this.jugadores, this.esUsuario = false});

  double get rating {
    if (jugadores.isEmpty) return 0;
    final suma = jugadores.fold<double>(0, (s, j) => s + ((j['ovr'] ?? 0) as num));
    return suma / jugadores.length;
  }

  int get ovrPromedio => rating.round();
}

class _BracketPainter extends CustomPainter {
  final Map<String, Offset> posiciones;
  final List<List<String>> conexiones;
  final Map<String, bool> jugado;

  _BracketPainter({required this.posiciones, required this.conexiones, required this.jugado});

  @override
  void paint(Canvas canvas, Size size) {
    for (final par in conexiones) {
      final origen = posiciones[par[0]];
      final destino = posiciones[par[1]];
      if (origen == null || destino == null) continue;

      final activo = jugado[par[0]] ?? false;
      final paint = Paint()
        ..color = activo ? Colors.white54 : Colors.white12
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;

      final p1 = Offset(origen.dx + _kCardW, origen.dy + _kCardH / 2);
      final p2 = Offset(destino.dx, destino.dy + _kCardH / 2);
      final midX = (p1.dx + p2.dx) / 2;

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(midX, p1.dy)
        ..lineTo(midX, p2.dy)
        ..lineTo(p2.dx, p2.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) =>
      oldDelegate.posiciones != posiciones || oldDelegate.jugado != jugado;
}

class _Partido {
  final String id;
  final String etiqueta;
  _Equipo? a;
  _Equipo? b;
  _Equipo? ganador;
  _Equipo? perdedor;
  int rondasA = 0;
  int rondasB = 0;
  bool jugado = false;

  _Partido(this.id, this.etiqueta, {this.a, this.b});

  bool get listoParaJugar => a != null && b != null && !jugado;
}

class TorneoDraftScreen extends StatefulWidget {
  const TorneoDraftScreen({super.key});

  @override
  State<TorneoDraftScreen> createState() => _TorneoDraftScreenState();
}

class _TorneoDraftScreenState extends State<TorneoDraftScreen> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _futureInventario;
  final List<Map<String, dynamic>> _titulares = [];

  @override
  void initState() {
    super.initState();
    _futureInventario = _cargarInventario();
  }

  Future<List<Map<String, dynamic>>> _cargarInventario() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('inventario')
        .select('id, cantidad, jugadores(*)')
        .eq('user_id', userId);

    final List<Map<String, dynamic>> misCartas = [];
    for (final fila in (response as List)) {
      final jugadorData = fila['jugadores'];
      if (jugadorData != null) {
        misCartas.add(Map<String, dynamic>.from(jugadorData));
      }
    }
    misCartas.sort((a, b) => ((b['ovr'] ?? 0) as num).compareTo((a['ovr'] ?? 0) as num));
    return misCartas;
  }

  void _alternar(Map<String, dynamic> carta) {
    setState(() {
      final yaEsta = _titulares.any((c) => c['id'] == carta['id']);
      if (yaEsta) {
        _titulares.removeWhere((c) => c['id'] == carta['id']);
      } else if (_titulares.length < 5) {
        _titulares.add(carta);
      }
    });
  }

  void _confirmar() {
    if (_titulares.length != 5) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TorneoBracketScreen(titulares: List.of(_titulares)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text('DRAFT · TORNEO',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: _kRojo),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: _kDorado, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Elige 5 titulares de tu inventario para competir en el torneo (${_titulares.length}/5)',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureInventario,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: _kDorado));
                  }
                  final cartas = snapshot.data ?? [];
                  if (cartas.isEmpty) {
                    return const Center(
                      child: Text('No tienes cartas en tu colección todavía.',
                          style: TextStyle(color: Colors.white54)),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: cartas.length,
                    itemBuilder: (context, index) {
                      final carta = cartas[index];
                      final elegido = _titulares.any((c) => c['id'] == carta['id']);
                      return GestureDetector(
                        onTap: () => _alternar(carta),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: (!elegido && _titulares.length >= 5) ? 0.35 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: elegido ? _kDorado : Colors.white12,
                                    width: elegido ? 2.5 : 1,
                                  ),
                                  boxShadow: elegido
                                      ? [BoxShadow(color: _kDorado.withOpacity(0.4), blurRadius: 14)]
                                      : [],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: CartaWidget(jugador: carta, width: 160, mostrarStats: false),
                              ),
                            ),
                            if (elegido)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: _kDorado, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: Colors.black, size: 16),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _titulares.length == 5 ? _kRojo : Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _titulares.length == 5 ? _confirmar : null,
              child: Text(
                _titulares.length == 5 ? 'CONFIRMAR TITULARES' : 'FALTAN ${5 - _titulares.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TorneoBracketScreen extends StatefulWidget {
  final List<Map<String, dynamic>> titulares;
  const TorneoBracketScreen({super.key, required this.titulares});

  @override
  State<TorneoBracketScreen> createState() => _TorneoBracketScreenState();
}

class _TorneoBracketScreenState extends State<TorneoBracketScreen> {
  final supabase = Supabase.instance.client;
  final _random = Random();

  bool _cargando = true;
  String? _error;

  late _Equipo _equipoUsuario;
  final Map<String, _Partido> _p = {};
  final List<String> _ordenPartidos = [
    'UR1_1', 'UR1_2', 'UR1_3', 'UR1_4',
    'LR1_1', 'LR1_2',
    'UR2_1', 'UR2_2',
    'LR2_1', 'LR2_2',
    'LR3',
    'UF',
    'LF',
    'GF',
  ];
  final Set<_Equipo> _perdioUnaVez = {};

  bool _simulando = false;
  bool _torneoTerminado = false;
  bool _usuarioCampeon = false;
  bool _usuarioEliminado = false;
  bool _entregandoPremio = false;

  static const List<String> _nombresIA = [
    'Ascendant Five', 'Radiant Core', 'Vipers Squad', 'Null Sector',
    'Phantom Line', 'Iron Wolves', 'Prime Circuit', 'Eclipse Gaming',
  ];

  @override
  void initState() {
    super.initState();
    _prepararTorneo();
  }

  Future<void> _prepararTorneo() async {
    try {
      final catalogo = await supabase.from('jugadores').select();
      var pool = List<Map<String, dynamic>>.from(catalogo as List);
      pool.shuffle(_random);

      if (pool.length < 35) {
        throw Exception('El catálogo no tiene suficientes jugadores para armar el torneo.');
      }

      _equipoUsuario = _Equipo(nombre: 'TU EQUIPO', jugadores: widget.titulares, esUsuario: true);

      final nombres = List<String>.of(_nombresIA)..shuffle(_random);
      final equiposIA = <_Equipo>[];
      var cursor = 0;
      for (var i = 0; i < 7; i++) {
        final roster = pool.sublist(cursor, cursor + 5);
        cursor += 5;
        equiposIA.add(_Equipo(nombre: nombres[i], jugadores: roster));
      }

      final equipos = List<_Equipo>.of(equiposIA);
      equipos.insert(_random.nextInt(equipos.length + 1), _equipoUsuario);

      _p['UR1_1'] = _Partido('UR1_1', 'Llave de Ganadores · Ronda 1', a: equipos[0], b: equipos[1]);
      _p['UR1_2'] = _Partido('UR1_2', 'Llave de Ganadores · Ronda 1', a: equipos[2], b: equipos[3]);
      _p['UR1_3'] = _Partido('UR1_3', 'Llave de Ganadores · Ronda 1', a: equipos[4], b: equipos[5]);
      _p['UR1_4'] = _Partido('UR1_4', 'Llave de Ganadores · Ronda 1', a: equipos[6], b: equipos[7]);

      _p['UR2_1'] = _Partido('UR2_1', 'Semifinal · Llave de Ganadores');
      _p['UR2_2'] = _Partido('UR2_2', 'Semifinal · Llave de Ganadores');
      _p['UF'] = _Partido('UF', 'Final · Llave de Ganadores');

      _p['LR1_1'] = _Partido('LR1_1', 'Llave de Perdedores · Ronda 1');
      _p['LR1_2'] = _Partido('LR1_2', 'Llave de Perdedores · Ronda 1');
      _p['LR2_1'] = _Partido('LR2_1', 'Llave de Perdedores · Ronda 2');
      _p['LR2_2'] = _Partido('LR2_2', 'Llave de Perdedores · Ronda 2');
      _p['LR3'] = _Partido('LR3', 'Semifinal · Llave de Perdedores');
      _p['LF'] = _Partido('LF', 'Final · Llave de Perdedores');

      _p['GF'] = _Partido('GF', 'GRAN FINAL');

      setState(() => _cargando = false);
    } catch (e) {
      debugPrint('ERROR AL PREPARAR TORNEO: $e');
      setState(() {
        _cargando = false;
        _error = 'No se pudo armar el torneo. Intenta de nuevo.';
      });
    }
  }

  _Partido? get _partidoActual {
    for (final id in _ordenPartidos) {
      final partido = _p[id]!;
      if (partido.listoParaJugar) return partido;
    }
    return null;
  }

  void _propagar(_Partido p) {
    switch (p.id) {
      case 'UR1_1':
        _p['UR2_1']!.a = p.ganador;
        _p['LR1_1']!.a = p.perdedor;
        break;
      case 'UR1_2':
        _p['UR2_1']!.b = p.ganador;
        _p['LR1_1']!.b = p.perdedor;
        break;
      case 'UR1_3':
        _p['UR2_2']!.a = p.ganador;
        _p['LR1_2']!.a = p.perdedor;
        break;
      case 'UR1_4':
        _p['UR2_2']!.b = p.ganador;
        _p['LR1_2']!.b = p.perdedor;
        break;
      case 'UR2_1':
        _p['UF']!.a = p.ganador;
        _p['LR2_2']!.b = p.perdedor;
        break;
      case 'UR2_2':
        _p['UF']!.b = p.ganador;
        _p['LR2_1']!.b = p.perdedor;
        break;
      case 'LR1_1':
        _p['LR2_1']!.a = p.ganador;
        break;
      case 'LR1_2':
        _p['LR2_2']!.a = p.ganador;
        break;
      case 'LR2_1':
        _p['LR3']!.a = p.ganador;
        break;
      case 'LR2_2':
        _p['LR3']!.b = p.ganador;
        break;
      case 'LR3':
        _p['LF']!.a = p.ganador;
        break;
      case 'UF':
        _p['GF']!.a = p.ganador;
        _p['LF']!.b = p.perdedor;
        break;
      case 'LF':
        _p['GF']!.b = p.ganador;
        break;
      case 'GF':
        _torneoTerminado = true;
        _usuarioCampeon = p.ganador?.esUsuario ?? false;
        break;
    }
  }

  Future<void> _simularPartido(_Partido partido) async {
    if (_simulando || partido.a == null || partido.b == null) return;
    setState(() => _simulando = true);

    final equipoA = partido.a!;
    final equipoB = partido.b!;
    int rondasA;
    int rondasB;

    if (equipoA.esUsuario || equipoB.esUsuario) {
      final usuarioEsA = equipoA.esUsuario;
      final equipoUsuario = usuarioEsA ? equipoA : equipoB;
      final equipoIA = usuarioEsA ? equipoB : equipoA;

      if (!mounted) return;
      final resultado = await Navigator.push<ResultadoPartidoTorneo>(
        context,
        MaterialPageRoute(
          builder: (context) => TorneoPartidoUsuarioScreen(
            etiquetaPartido: partido.etiqueta,
            titularesUsuario: equipoUsuario.jugadores,
            rosterRival: equipoIA.jugadores,
            nombreRival: equipoIA.nombre,
          ),
        ),
      );

      if (!mounted) return;
      if (resultado == null) {
        setState(() => _simulando = false);
        return;
      }

      rondasA = usuarioEsA ? resultado.rondasUsuario : resultado.rondasRival;
      rondasB = usuarioEsA ? resultado.rondasRival : resultado.rondasUsuario;
    } else {
      rondasA = 0;
      rondasB = 0;
      while (rondasA < _rondasParaGanar && rondasB < _rondasParaGanar) {
        await Future.delayed(const Duration(milliseconds: 160));
        final puntajeA = equipoA.rating + (_random.nextInt(19) - 9);
        final puntajeB = equipoB.rating + (_random.nextInt(19) - 9);
        final ganoA = puntajeA == puntajeB ? _random.nextBool() : puntajeA > puntajeB;
        if (ganoA) {
          rondasA++;
        } else {
          rondasB++;
        }
        if (!mounted) return;
        setState(() {
          partido.rondasA = rondasA;
          partido.rondasB = rondasB;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      partido.rondasA = rondasA;
      partido.rondasB = rondasB;
    });

    final ganador = rondasA > rondasB ? equipoA : equipoB;
    final perdedor = rondasA > rondasB ? equipoB : equipoA;

    partido.jugado = true;
    partido.ganador = ganador;
    partido.perdedor = perdedor;

    final eraSegundaDerrota = _perdioUnaVez.contains(perdedor);
    if (partido.id == 'GF') {
    } else if (eraSegundaDerrota) {
      if (perdedor.esUsuario) _usuarioEliminado = true;
    } else {
      _perdioUnaVez.add(perdedor);
    }

    _propagar(partido);

    if (!mounted) return;
    setState(() => _simulando = false);

    if (_torneoTerminado) {
      if (_usuarioCampeon) {
        await _entregarPremio();
      } else if (partido.perdedor?.esUsuario ?? false) {
        setState(() => _usuarioEliminado = true);
      }
      if (!mounted) return;
      await _mostrarResultadoFinal();
    } else if (_usuarioEliminado) {
      if (!mounted) return;
      await _mostrarEliminacion();
    }
  }

  Future<void> _entregarPremio() async {
    setState(() => _entregandoPremio = true);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _entregandoPremio = false);
      return;
    }

    String? errorMonedas;
    try {
      await supabase.rpc('fn_pagar_monedas_partida', params: {'p_cantidad': _premioMonedas});
    } catch (e) {
      debugPrint('ERROR AL PAGAR MONEDAS DE TORNEO: $e');
      errorMonedas = e.toString();
    }

    String? errorSobre;
    if (mounted) {
      final perfil = context.read<PerfilProvider>();
      errorSobre = await perfil.agregarSobrePendienteConError('premium_torneo');
      await perfil.cargar();
    }

    if (mounted) setState(() => _entregandoPremio = false);

    if ((errorMonedas != null || errorSobre != null) && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _kFondoPanel,
          title: const Text('Hubo un problema al entregar el premio', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: SelectableText(
              [
                if (errorMonedas != null) 'MONEDAS:\n$errorMonedas',
                if (errorSobre != null) 'SOBRE:\n$errorSobre',
              ].join('\n\n'),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar', style: TextStyle(color: _kDorado)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _mostrarEliminacion() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: _kFondoPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close, color: _kRojo, size: 44),
              const SizedBox(height: 10),
              const Text('Eliminado del torneo',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Tu equipo perdió su segunda llave. El torneo continúa sin ti.',
                  style: TextStyle(color: Colors.white54, fontSize: 12.5), textAlign: TextAlign.center),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRojo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('SALIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarResultadoFinal() async {
    if (_usuarioEliminado && !_usuarioCampeon) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: _kFondoPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_usuarioCampeon ? Icons.emoji_events : Icons.military_tech,
                  color: _kDorado, size: 52),
              const SizedBox(height: 10),
              Text(
                _usuarioCampeon ? '¡CAMPEÓN DEL TORNEO!' : 'Torneo finalizado',
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _usuarioCampeon
                    ? 'Ganaste la Gran Final: +$_premioMonedas monedas y un Sobre Premium en tu inventario de la Tienda.'
                    : 'Tu equipo no logró llegar a la cima esta vez.',
                style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDorado,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('SALIR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text('TORNEO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: _kRojo),
        ),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: _kDorado))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
                : _entregandoPremio
                    ? const Center(child: CircularProgressIndicator(color: _kDorado))
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _leyendaColor(_kAzulUpper, 'Ganadores'),
                                  const SizedBox(width: 14),
                                  _leyendaColor(_kMoradoLower, 'Perdedores'),
                                  const SizedBox(width: 14),
                                  _leyendaColor(_kDorado, 'Gran Final'),
                                  const SizedBox(width: 18),
                                  const Icon(Icons.pinch_outlined, color: Colors.white24, size: 15),
                                  const SizedBox(width: 4),
                                  const Text('mueve y pellizca para explorar',
                                      style: TextStyle(color: Colors.white24, fontSize: 10.5)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                              child: _bracketVisual(),
                            ),
                          ),
                        ],
                      ),
      ),
      bottomNavigationBar: (_cargando || _error != null || _torneoTerminado || _entregandoPremio)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _partidoActual == null
                    ? const SizedBox.shrink()
                    : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kRojo,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _simulando ? null : () => _simularPartido(_partidoActual!),
                          icon: _simulando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.play_arrow, color: Colors.white),
                          label: Text(
                            _simulando ? 'JUGANDO...' : 'JUGAR: ${_partidoActual!.etiqueta}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                      ),
              ),
            ),
    );
  }

  Widget _leyendaColor(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Map<String, Offset> _layoutPosiciones() {
    final pos = <String, Offset>{};
    double colX(int i) => i * (_kCardW + _kColGap);
    double centro(String id) => pos[id]!.dy + _kCardH / 2;

    for (var i = 0; i < 4; i++) {
      pos['UR1_${i + 1}'] = Offset(colX(0), i * (_kCardH + _kRowGap));
    }
    pos['UR2_1'] = Offset(colX(1), (centro('UR1_1') + centro('UR1_2')) / 2 - _kCardH / 2);
    pos['UR2_2'] = Offset(colX(1), (centro('UR1_3') + centro('UR1_4')) / 2 - _kCardH / 2);
    pos['UF'] = Offset(colX(2), (centro('UR2_1') + centro('UR2_2')) / 2 - _kCardH / 2);
    pos['GF'] = Offset(colX(4), pos['UF']!.dy);

    final abajoDeGanadores =
        [0, 1, 2, 3].map((i) => pos['UR1_${i + 1}']!.dy).reduce(max) + _kCardH;
    final baseInferior = abajoDeGanadores + _kSectionGap;

    pos['LR1_1'] = Offset(colX(0), baseInferior + 0 * (_kCardH + _kRowGap));
    pos['LR1_2'] = Offset(colX(0), baseInferior + 1 * (_kCardH + _kRowGap));
    pos['LR2_1'] = Offset(colX(1), pos['LR1_1']!.dy);
    pos['LR2_2'] = Offset(colX(1), pos['LR1_2']!.dy);
    pos['LR3'] = Offset(colX(2), (centro('LR2_1') + centro('LR2_2')) / 2 - _kCardH / 2);
    pos['LF'] = Offset(colX(3), pos['LR3']!.dy);

    return pos.map((k, v) => MapEntry(k, v + const Offset(0, _kHeaderH + 12)));
  }

  static const List<List<String>> _conexionesBracket = [
    ['UR1_1', 'UR2_1'], ['UR1_2', 'UR2_1'],
    ['UR1_3', 'UR2_2'], ['UR1_4', 'UR2_2'],
    ['UR2_1', 'UF'], ['UR2_2', 'UF'],
    ['UF', 'GF'],
    ['LR1_1', 'LR2_1'], ['LR1_2', 'LR2_2'],
    ['LR2_1', 'LR3'], ['LR2_2', 'LR3'],
    ['LR3', 'LF'],
    ['LF', 'GF'],
  ];

  Color _colorDeGrupo(String id) {
    if (id == 'GF') return _kDorado;
    if (id.startsWith('U')) return _kAzulUpper;
    return _kMoradoLower;
  }

  Widget _bracketVisual() {
    final pos = _layoutPosiciones();
    final maxX = pos.values.map((o) => o.dx).reduce(max) + _kCardW + 20;
    final maxY = pos.values.map((o) => o.dy).reduce(max) + _kCardH + 20;
    final jugado = {for (final e in _p.entries) e.key: e.value.jugado};

    final encabezados = <Map<String, Object>>[
      {'texto': 'CUARTOS DE FINAL', 'x': pos['UR1_1']!.dx, 'y': 0.0, 'color': _kAzulUpper},
      {'texto': 'SEMIFINALES', 'x': pos['UR2_1']!.dx, 'y': 0.0, 'color': _kAzulUpper},
      {'texto': 'FINAL GANADORES', 'x': pos['UF']!.dx, 'y': 0.0, 'color': _kAzulUpper},
      {'texto': 'GRAN FINAL', 'x': pos['GF']!.dx, 'y': 0.0, 'color': _kDorado},
      {'texto': 'RONDA 1', 'x': pos['LR1_1']!.dx, 'y': pos['LR1_1']!.dy - 24, 'color': _kMoradoLower},
      {'texto': 'RONDA 2', 'x': pos['LR2_1']!.dx, 'y': pos['LR1_1']!.dy - 24, 'color': _kMoradoLower},
      {'texto': 'SEMIFINAL', 'x': pos['LR3']!.dx, 'y': pos['LR1_1']!.dy - 24, 'color': _kMoradoLower},
      {'texto': 'FINAL PERDEDORES', 'x': pos['LF']!.dx, 'y': pos['LR1_1']!.dy - 24, 'color': _kMoradoLower},
    ];

    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 2.0,
      boundaryMargin: const EdgeInsets.all(60),
      child: SizedBox(
        width: maxX,
        height: maxY,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BracketPainter(posiciones: pos, conexiones: _conexionesBracket, jugado: jugado),
              ),
            ),
            for (final enc in encabezados)
              Positioned(
                left: enc['x'] as double,
                top: enc['y'] as double,
                child: Text(
                  enc['texto'] as String,
                  style: TextStyle(
                    color: enc['color'] as Color,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            for (final id in _p.keys)
              Positioned(
                left: pos[id]!.dx,
                top: pos[id]!.dy,
                child: _tarjetaPartido(_p[id]!, _colorDeGrupo(id)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaPartido(_Partido partido, Color color) {
    final esActual = identical(partido, _partidoActual);
    return Tooltip(
      message: partido.etiqueta,
      waitDuration: const Duration(milliseconds: 400),
      child: Container(
        width: _kCardW,
        height: _kCardH,
        decoration: BoxDecoration(
          color: _kFondoPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: esActual ? color : Colors.white12,
            width: esActual ? 1.8 : 1,
          ),
          boxShadow: esActual ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)] : [],
        ),
        child: Column(
          children: [
            Expanded(
              child: _filaEquipoCompacta(
                partido.a, partido.rondasA, partido.jugado && partido.ganador == partido.a, color,
              ),
            ),
            Container(height: 1, color: Colors.white10),
            Expanded(
              child: _filaEquipoCompacta(
                partido.b, partido.rondasB, partido.jugado && partido.ganador == partido.b, color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaEquipoCompacta(_Equipo? equipo, int rondas, bool esGanador, Color color) {
    if (equipo == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Por definir',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white24, fontSize: 11.5, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: equipo.esUsuario ? _kDorado.withOpacity(0.2) : Colors.white10,
              border: Border.all(color: equipo.esUsuario ? _kDorado : Colors.white24, width: 1),
            ),
            child: Icon(
              equipo.esUsuario ? Icons.star : Icons.shield_outlined,
              size: 10,
              color: equipo.esUsuario ? _kDorado : Colors.white38,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              equipo.nombre,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: esGanador ? Colors.white : Colors.white60,
                fontWeight: esGanador ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 22,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: esGanador ? color.withOpacity(0.22) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: esGanador ? Border.all(color: color, width: 1) : null,
            ),
            child: Text(
              '$rondas',
              style: TextStyle(
                color: esGanador ? color : Colors.white38,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}