import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/carta_widget.dart';

enum _EfectoRareza { ninguno, plata, violeta, dorado }

class SobreDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> sobre;
  const SobreDetalleScreen({super.key, required this.sobre});

  @override
  State<SobreDetalleScreen> createState() => _SobreDetalleScreenState();
}

class _SobreDetalleScreenState extends State<SobreDetalleScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _random = Random();


  static const List<Map<String, dynamic>> _tramosOvrPorDefecto = [
    {'min': 0, 'max': 70, 'peso': 50, 'efecto': _EfectoRareza.ninguno},
    {'min': 71, 'max': 80, 'peso': 35, 'efecto': _EfectoRareza.ninguno},
    {'min': 81, 'max': 88, 'peso': 20, 'efecto': _EfectoRareza.plata},
    {'min': 89, 'max': 91, 'peso': 4, 'efecto': _EfectoRareza.violeta},
    {'min': 92, 'max': 99, 'peso': 1, 'efecto': _EfectoRareza.dorado},
  ];

  static const Map<String, _EfectoRareza> _efectoPorNombre = {
    'ninguno': _EfectoRareza.ninguno,
    'plata': _EfectoRareza.plata,
    'violeta': _EfectoRareza.violeta,
    'dorado': _EfectoRareza.dorado,
  };

  late final List<Map<String, dynamic>> _tramos = _construirTramos();

  List<Map<String, dynamic>> _construirTramos() {
    final crudos = widget.sobre['tramos'] as List<dynamic>?;
    if (crudos == null || crudos.isEmpty) return _tramosOvrPorDefecto;

    return crudos.map((t) {
      final tramo = Map<String, dynamic>.from(t as Map);
      final efectoCrudo = tramo['efecto'];
      tramo['efecto'] = efectoCrudo is _EfectoRareza
          ? efectoCrudo
          : (_efectoPorNombre[efectoCrudo] ?? _EfectoRareza.ninguno);
      return tramo;
    }).toList();
  }

  late final AnimationController _pulso;
  late final Animation<double> _escalaPulso;

  late final AnimationController _fondoController;

  late final AnimationController _efecto;
  late final Animation<double> _opacidadEfecto;
  _EfectoRareza _efectoActivo = _EfectoRareza.ninguno;

  late final AnimationController _rasgado;
  late final Animation<double> _temblor;
  late final Animation<double> _escalaSobre;
  late final Animation<double> _opacidadSobre;
  late final Animation<double> _escalaDestello;
  late final Animation<double> _opacidadDestello;

  bool _comprando = false;
  bool _comprado = false;
  bool _abriendo = false;
  bool _mostrarAmbas = false;
  String? _error;
  List<Map<String, dynamic>> _cartasReveladas = [];

  ui.Image? _logoImagenCruda;

  @override
  void initState() {
    super.initState();

    _pulso = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _escalaPulso = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulso, curve: Curves.easeInOutSine),
    );

    _fondoController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _efecto = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _opacidadEfecto = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_efecto);

    _rasgado = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _temblor = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.04), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.05), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.08), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.1), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.12), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _rasgado, curve: const Interval(0.0, 0.5)));

    _escalaSobre = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.25, end: 0.4).chain(CurveTween(curve: Curves.easeInExpo)), weight: 60),
    ]).animate(_rasgado);

    _opacidadSobre = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _rasgado, curve: const Interval(0.4, 0.7)),
    );

    _escalaDestello = Tween<double>(begin: 0.1, end: 4.5).animate(
      CurvedAnimation(parent: _rasgado, curve: const Interval(0.4, 0.9, curve: Curves.easeOutExpo)),
    );
    _opacidadDestello = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 90),
    ]).animate(CurvedAnimation(parent: _rasgado, curve: const Interval(0.4, 1.0)));

    _cargarImagenLogo();
  }

  @override
  void dispose() {
    _pulso.dispose();
    _fondoController.dispose();
    _efecto.dispose();
    _rasgado.dispose();
    super.dispose();
  }

  int _compararJugadores(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ovrA = (a['ovr'] ?? 0) as num;
    final ovrB = (b['ovr'] ?? 0) as num;
    if (ovrB != ovrA) return ovrB.compareTo(ovrA);
    final aimA = (a['aim'] ?? 0) as num;
    final aimB = (b['aim'] ?? 0) as num;
    return aimB.compareTo(aimA);
  }

  Map<String, dynamic> _elegirCartaPonderada(List<Map<String, dynamic>> pool) {
    final tramosRestantes = List<Map<String, dynamic>>.from(_tramos);

    while (tramosRestantes.isNotEmpty) {
      final pesoTotal = tramosRestantes.fold<int>(0, (s, t) => s + (t['peso'] as int));
      var roll = _random.nextInt(pesoTotal);

      Map<String, dynamic> tramoElegido = tramosRestantes.last;
      for (final tramo in tramosRestantes) {
        final peso = tramo['peso'] as int;
        if (roll < peso) {
          tramoElegido = tramo;
          break;
        }
        roll -= peso;
      }

      final candidatosTramo = pool.where((j) {
        final ovr = (j['ovr'] ?? 0) as num;
        return ovr >= tramoElegido['min'] && ovr <= tramoElegido['max'];
      }).toList();

      if (candidatosTramo.isNotEmpty) {
        return candidatosTramo[_random.nextInt(candidatosTramo.length)];
      }
      tramosRestantes.remove(tramoElegido);
    }
    return pool[_random.nextInt(pool.length)];
  }

  _EfectoRareza _efectoDeCarta(Map<String, dynamic> jugador) {
    final ovr = (jugador['ovr'] ?? 0) as num;
    for (final tramo in _tramos) {
      if (ovr >= tramo['min'] && ovr <= tramo['max']) {
        return tramo['efecto'] as _EfectoRareza;
      }
    }
    return _EfectoRareza.ninguno;
  }

  Future<void> _comprar() async {
    setState(() {
      _comprando = true;
      _error = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No hay sesión activa.');

      final precio = widget.sobre['precio'] as int;
      final perfil = await supabase.from('profiles').select('dinero').eq('id', userId).single();
      final dineroActual = (perfil['dinero'] ?? 0) as int;

      if (dineroActual < precio) {
        setState(() {
          _error = 'No tienes suficiente dinero para este sobre.';
          _comprando = false;
        });
        return;
      }

      await supabase.from('profiles').update({'dinero': dineroActual - precio}).eq('id', userId);

      if (!mounted) return;
      setState(() {
        _comprando = false;
        _comprado = true;
      });
    } catch (e) {
      debugPrint('ERROR AL COMPRAR SOBRE: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo completar la compra.';
        _comprando = false;
      });
    }
  }

  Future<void> _abrirSobre() async {
    if (_abriendo) return;
    _pulso.stop();
    setState(() => _abriendo = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No hay sesión activa.');

      final catalogo = await supabase.from('jugadores').select();
      final todosCompletos = List<Map<String, dynamic>>.from(catalogo as List);
      final rarezas = List<String>.from(widget.sobre['rarezas'] as List);

      var pool = todosCompletos.where((j) => rarezas.contains(j['rareza'])).toList();
      if (pool.isEmpty) pool = todosCompletos;
      if (pool.isEmpty) throw Exception('No hay jugadores cargados en el catálogo.');

      final cantidadCartas = (widget.sobre['cantidad_cartas'] as int?) ?? 2;

      final elegidas = <Map<String, dynamic>>[];
      var poolDisponible = List<Map<String, dynamic>>.from(pool);

      for (var i = 0; i < cantidadCartas; i++) {
        if (poolDisponible.isEmpty) {
          break;
        }
        final carta = _elegirCartaPonderada(poolDisponible);
        elegidas.add(carta);
        final idElegido = carta['id'];
        poolDisponible = poolDisponible.where((j) => j['id'] != idElegido).toList();
      }
      elegidas.sort(_compararJugadores);

      for (var jugador in elegidas) {
        final jugadorId = jugador['id'];

        final respuesta = await supabase
        .from('inventario')
        .select('id, cantidad')
        .eq('user_id', userId)
        .eq('jugador_id', jugadorId);

        final List filas = (respuesta as List);

        if (filas.isNotEmpty) {
        final registro = filas.first;
        final int inventarioId = registro['id'];
        final int cantidadActual = (registro['cantidad'] ?? 1) as int;

        await supabase
        .from('inventario')
        .update({'cantidad': cantidadActual + 1})
        .eq('id', inventarioId)
        .select();
        } else {
          await supabase
              .from('inventario')
              .insert({
                'user_id': userId,
                'jugador_id': jugadorId,
                'cantidad': 1,
              });
        }
      }

      final efecto = _efectoDeCarta(elegidas.first);
      if (!mounted) return;
      setState(() => _efectoActivo = efecto);

      _efecto.duration = _duracionEfecto(efecto);
      await _efecto.forward(from: 0);
      if (!mounted) return;
      setState(() => _efectoActivo = _EfectoRareza.ninguno);

      await _rasgado.forward(from: 0);

      if (!mounted) return;
      setState(() {
        _cartasReveladas = elegidas;
        _abriendo = false;
      });
    } catch (e) {
      debugPrint('ERROR AL ABRIR SOBRE: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo abrir el sobre.';
        _abriendo = false;
        _efectoActivo = _EfectoRareza.ninguno;
      });
      _pulso.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sobre = widget.sobre;
    final color = sobre['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _cartasReveladas.isNotEmpty),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildFondoLogoVCT()),

            _cartasReveladas.isNotEmpty
                ? (_mostrarAmbas ? _buildCartasReveladas() : _buildRevelacionInicial())
                : (_comprado ? _buildSobreParaAbrir(sobre, color) : _buildVistaCompra(sobre, color)),
          ],
        ),
      ),
    );
  }

  static const String _rutaLogoVCT = 'assets/valorant/logos/vct_logo.png';

  Widget _logoRotadoCover() {
    return RotatedBox(
      quarterTurns: 1,
      child: SizedBox.expand(
        child: Image.asset(
          _rutaLogoVCT,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<void> _cargarImagenLogo() async {
    final stream = const AssetImage(_rutaLogoVCT).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _logoImagenCruda = info.image);
      stream.removeListener(listener);
    }, onError: (error, stackTrace) {
      debugPrint('No se pudo cargar el logo para la máscara: $error');
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  static const List<double> _matrizGris = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  Duration _duracionEfecto(_EfectoRareza efecto) {
    switch (efecto) {
      case _EfectoRareza.dorado:
        return const Duration(milliseconds: 2000);
      case _EfectoRareza.violeta:
        return const Duration(milliseconds: 1500);
      case _EfectoRareza.plata:
        return const Duration(milliseconds: 1100);
      case _EfectoRareza.ninguno:
        return const Duration(milliseconds: 900);
    }
  }

  Color _getColorEfectoActivo() {
    switch (_efectoActivo) {
      case _EfectoRareza.dorado: return const Color(0xFFFFD700);
      case _EfectoRareza.violeta: return const Color(0xFF9B59B6);
      case _EfectoRareza.plata: return Colors.white;
      case _EfectoRareza.ninguno: return Colors.transparent;
    }
  }

  Widget _buildFondoLogoVCT() {
    final brillando = _efectoActivo != _EfectoRareza.ninguno;
    final colorBrillo = _getColorEfectoActivo();

    return Container(
      color: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(_matrizGris),
                child: _logoRotadoCover(),
              ),
            ),
          ),
          if (brillando && _logoImagenCruda != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _efecto,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MascaraLogoPainter(
                      logoImagen: _logoImagenCruda!,
                      progresoBrillo: _efecto.value,
                      colorBrillo: colorBrillo,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagenSobre(Map<String, dynamic> sobre, Color color, double size) {
    return SizedBox(
      height: size,
      child: Image.asset(
        sobre['imagen'] as String,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(sobre['icono'] as IconData, size: size * 0.7, color: color),
      ),
    );
  }

  Widget _buildCapaFondoSolido(Color color) {
    return Container(
      color: Color.alphaBlend(color.withOpacity(0.22), const Color(0xFF05070D)),
    );
  }

  Widget _buildCapaBrillo(Color color) {
    return Center(
      child: AnimatedBuilder(
        animation: _efecto,
        builder: (context, child) {
          switch (_efectoActivo) {
            case _EfectoRareza.dorado:
              return _efectoDorado();
            case _EfectoRareza.violeta:
              return _efectoVioleta();
            case _EfectoRareza.plata:
              return _efectoPlata();
            case _EfectoRareza.ninguno:
              return _brilloComun(color);
          }
        },
      ),
    );
  }

  Widget _brilloComun(Color color) {
    final t = _efecto.value;
    if (t <= 0.0) return const SizedBox.shrink();
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final diagonal = sqrt(w * w + h * h);
            return Stack(
              children: [
                _bandaBrillo(
                  w: w,
                  diagonal: diagonal,
                  progreso: t,
                  color: color,
                  opacidadPico: 0.55,
                  grosor: 0.24,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bandaBrillo({
    required double w,
    required double diagonal,
    required double progreso,
    required Color color,
    required double opacidadPico,
    required double grosor,
  }) {
    final centroX = (-0.3 + progreso * 1.6) * w;
    return Positioned(
      left: centroX - diagonal * (grosor / 2),
      top: -diagonal * 0.2,
      child: Transform.rotate(
        angle: -pi / 7,
        child: Container(
          width: diagonal * grosor,
          height: diagonal * 1.4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                color.withOpacity(0.0),
                color.withOpacity(opacidadPico),
                color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapaFoto() {
    return _logoRotadoCover();
  }

  Widget _buildEfectoPrevio() {
    return const SizedBox.shrink();
  }

  Widget _efectoPlata() {
    final t = _efecto.value;
    return Opacity(
      opacity: _opacidadEfecto.value,
      child: Transform.rotate(
        angle: t * pi,
        child: Transform.scale(
          scale: 0.5 + (t * 2.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 4, height: 400, color: Colors.white.withOpacity(0.8)),
              Container(width: 400, height: 4, color: Colors.white.withOpacity(0.8)),
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white54, blurRadius: 40, spreadRadius: 20)],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _efectoVioleta() {
    const colorVioleta = Color(0xFF9B59B6);
    final t = _efecto.value;
    return Opacity(
      opacity: _opacidadEfecto.value,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: colorVioleta.withOpacity(0.4), blurRadius: 80, spreadRadius: 40)],
            ),
          ),
          Transform.rotate(
            angle: t * 2 * pi,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(6, (i) {
                final angulo = (i / 6) * 2 * pi;
                return Transform.translate(
                  offset: Offset(cos(angulo) * 130, sin(angulo) * 130),
                  child: Opacity(
                    opacity: (sin(t * pi)).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: pi / 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          ...List.generate(3, (i) {
            final retraso = i * 0.15;
            final progreso = (_efecto.value - retraso).clamp(0.0, 1.0);
            return Transform.scale(
              scale: progreso * 2.5,
              child: Opacity(
                opacity: (1 - progreso).clamp(0.0, 1.0),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 4),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _efectoDorado() {
    const colorDorado = Color(0xFFFFD700);
    final t = _efecto.value;
    return Opacity(
      opacity: _opacidadEfecto.value,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: colorDorado.withOpacity(0.7), blurRadius: 120, spreadRadius: 60)
              ],
            ),
          ),
          Transform.rotate(
            angle: t * 4 * pi,
            child: Transform.scale(
              scale: 0.5 + (t * 1.5),
              child: Container(
                width: 500,
                height: 500,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0x00FFD700), Color(0xFFFFFFaa),
                      Color(0x00FFD700), Color(0xFFFFFFaa),
                      Color(0x00FFD700), Color(0xFFFFFFaa),
                      Color(0x00FFD700), Color(0xFFFFFFaa),
                      Color(0x00FFD700),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -t * 6 * pi,
            child: Transform.scale(
              scale: 0.3 + (t * 1.1),
              child: Container(
                width: 340,
                height: 340,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0x00FFFFFF), Color(0x99FFD700),
                      Color(0x00FFFFFF), Color(0x99FFD700),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: (1 - (t / 0.35).clamp(0.0, 1.0)),
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaCompra(Map<String, dynamic> sobre, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imagenSobre(sobre, color, 200),
          const SizedBox(height: 28),
          Text(
            sobre['nombre'],
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            sobre['descripcion'],
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          if (_comprando)
            const CircularProgressIndicator(color: Color(0xFFFFD700))
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _comprar,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      'COMPRAR (${sobre['precio']})',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSobreParaAbrir(Map<String, dynamic> sobre, Color color) {
    return GestureDetector(
      onTap: _abrirSobre,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(child: _buildCapaFondoSolido(color)),

          Positioned.fill(child: _buildCapaBrillo(color)),

          Positioned.fill(child: _buildCapaFoto()),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 450,
                  width: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      _buildEfectoPrevio(),

                      AnimatedBuilder(
                        animation: _rasgado,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _opacidadDestello.value,
                            child: Transform.scale(
                              scale: _escalaDestello.value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [Colors.white, color.withOpacity(0.0)],
                                    stops: const [0.2, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      AnimatedBuilder(
                        animation: _rasgado,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _abriendo ? _opacidadSobre.value : 1,
                            child: Transform.rotate(
                              angle: _abriendo ? _temblor.value : 0,
                              child: Transform.scale(
                                scale: _abriendo ? _escalaSobre.value : 1,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: AnimatedBuilder(
                          animation: _pulso,
                          builder: (context, child) => Transform.scale(
                            scale: _abriendo ? 1 : _escalaPulso.value,
                            child: child,
                          ),
                          child: _imagenSobre(sobre, color, 320),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                if (!_abriendo && _error == null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    builder: (context, opacidad, child) => Opacity(
                      opacity: opacidad,
                      child: child,
                    ),
                    child: const Text(
                      'Toca el sobre para abrirlo',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevelacionInicial() {
    final mejorCarta = _cartasReveladas.first;
    final efecto = _efectoDeCarta(mejorCarta);

    Color colorGlow = Colors.transparent;
    if (efecto == _EfectoRareza.dorado) colorGlow = const Color(0xFFFFD700);
    if (efecto == _EfectoRareza.violeta) colorGlow = const Color(0xFF9B59B6);
    if (efecto == _EfectoRareza.plata) colorGlow = Colors.white;

    final duracionFlip = _duracionEfecto(efecto) + const Duration(milliseconds: 200);
    final intensidadGlow = switch (efecto) {
      _EfectoRareza.dorado => 1.3,
      _EfectoRareza.violeta => 1.0,
      _EfectoRareza.plata => 0.7,
      _EfectoRareza.ninguno => 0.0,
    };

    return GestureDetector(
      onTap: () => setState(() => _mostrarAmbas = true),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: duracionFlip,
              curve: Curves.easeOutExpo,
              builder: (context, value, child) {
                final angle = (1 - value) * pi; 
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..translate(0.0, 150 * (1 - value), 0.0)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: value > 0.6 && intensidadGlow > 0
                            ? [
                                BoxShadow(
                                  color: colorGlow.withOpacity(0.8 * value * intensidadGlow.clamp(0.0, 1.0)),
                                  blurRadius: 80 * value * intensidadGlow,
                                  spreadRadius: 20 * value * intensidadGlow,
                                )
                              ]
                            : null,
                      ),
                      child: Opacity(
                        opacity: value < 0.2 ? (value * 5).clamp(0.0, 1.0) : 1.0, 
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: CartaWidget(jugador: mejorCarta, width: 280),
            ),
            const SizedBox(height: 40),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: const Text(
                'Toca la pantalla para continuar',
                style: TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartasReveladas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Text(
            '¡Obtuviste ${_cartasReveladas.length} cartas!',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _cartasReveladas.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 626 / 794,
            ),
            itemBuilder: (context, index) {
              final delay = index * 150;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  final delayedValue = (value - (delay / 1000)).clamp(0.0, 1.0) / (1 - (delay / 1000)).clamp(0.001, 1.0);
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - delayedValue)),
                    child: Opacity(
                      opacity: delayedValue,
                      child: child,
                    ),
                  );
                },
                child: CartaWidget(jugador: _cartasReveladas[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'VOLVER A LA TIENDA',
                style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MascaraLogoPainter extends CustomPainter {
  final ui.Image logoImagen;
  final double progresoBrillo; 
  final Color colorBrillo;

  _MascaraLogoPainter({
    required this.logoImagen,
    required this.progresoBrillo,
    required this.colorBrillo,
  });

  static const List<double> _matrizLuminanciaAlpha = <double>[
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.saveLayer(rect, Paint());

    final centro = progresoBrillo * 2.0 - 0.5; 
    
    final gradiente = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Colors.transparent,
        colorBrillo.withOpacity(0.7),
        colorBrillo,
        colorBrillo.withOpacity(0.7),
        Colors.transparent,
      ],
      stops: [
        (centro - 0.3).clamp(0.0, 1.0),
        (centro - 0.1).clamp(0.0, 1.0),
        centro.clamp(0.0, 1.0),
        (centro + 0.1).clamp(0.0, 1.0),
        (centro + 0.3).clamp(0.0, 1.0),
      ],
    );
    
    canvas.drawRect(rect, Paint()..shader = gradiente.createShader(rect));

    final paintMascara = Paint()
      ..blendMode = BlendMode.dstIn
      ..colorFilter = const ColorFilter.matrix(_matrizLuminanciaAlpha);

    _dibujarImagenGiradaCover(canvas, rect, paintMascara);

    canvas.restore();
  }

  void _dibujarImagenGiradaCover(Canvas canvas, Rect destino, Paint paint) {
    canvas.save();
    canvas.translate(destino.center.dx, destino.center.dy);
    canvas.rotate(pi / 2);

    final tamRotado = Size(destino.height, destino.width);
    final tamOrigen = Size(logoImagen.width.toDouble(), logoImagen.height.toDouble());
    final ajuste = applyBoxFit(BoxFit.cover, tamOrigen, tamRotado);

    final rectOrigen = Alignment.center.inscribe(
      ajuste.source,
      Offset.zero & tamOrigen,
    );
    final rectDestino = Alignment.center.inscribe(
      ajuste.destination,
      Rect.fromCenter(center: Offset.zero, width: tamRotado.width, height: tamRotado.height),
    );

    canvas.drawImageRect(logoImagen, rectOrigen, rectDestino, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascaraLogoPainter oldDelegate) {
    return oldDelegate.progresoBrillo != progresoBrillo ||
        oldDelegate.colorBrillo != colorBrillo ||
        oldDelegate.logoImagen != logoImagen;
  }
}