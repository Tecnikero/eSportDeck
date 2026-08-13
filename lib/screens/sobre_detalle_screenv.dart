import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/carta_widget.dart';
import '../providers/perfil_provider.dart';

enum _EfectoRareza { ninguno, plata, violeta, dorado }

const Color _kPlataUI = Color(0xFFC7CBD1);
const Color _kPlataOscuraUI = Color(0xFF3A3D42);
const Color _kAcentoUI = Color(0xFFD9B65C);

class SobreDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> sobre;
  final bool esPendiente;
  const SobreDetalleScreen({super.key, required this.sobre, this.esPendiente = false});

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

  late final AnimationController _revelado;

  bool _comprando = false;
  bool _comprado = false;
  bool _abriendo = false;
  bool _mostrarAmbas = false;
  bool _aperturaMasiva = false;
  String? _error;
  List<Map<String, dynamic>> _cartasReveladas = [];
  String _fondoOcultoRuta = 'assets/valorant/cartas/carta_normal_plata.png';

  static const int _umbralOvrOroOculta = 79;

  static const Map<String, String> _fondosPorRarezaOculta = {
    'champions': 'assets/valorant/cartas/carta_champions.png',
    'finals_champions': 'assets/valorant/cartas/carta_finals_champions.png',
  };

  String _rutaFondoParaCarta(Map<String, dynamic> jugador) {
    final rareza = '${jugador['rareza'] ?? 'normal'}'.toLowerCase().replaceAll(' ', '_');
    if (rareza == 'normal') {
      final ovr = (jugador['ovr'] ?? 0) as num;
      return ovr >= _umbralOvrOroOculta
          ? 'assets/valorant/cartas/carta_normal_oro.png'
          : 'assets/valorant/cartas/carta_normal_plata.png';
    }
    return _fondosPorRarezaOculta[rareza] ?? 'assets/valorant/cartas/carta_normal_plata.png';
  }

  ui.Image? _logoImagenCruda;

  static const int _pityVioletaMax = 30;

  int _pityVioleta = 0;

  String get _sobreId => '${widget.sobre['id'] ?? widget.sobre['nombre']}';

  void _cargarPity() {
    final perfil = context.read<PerfilProvider>();
    _pityVioleta = perfil.obtenerPity(_sobreId, 'violeta');
  }

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

    _revelado = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    _cargarImagenLogo();
    _cargarPity();
  }

  @override
  void dispose() {
    _pulso.dispose();
    _fondoController.dispose();
    _efecto.dispose();
    _rasgado.dispose();
    _revelado.dispose();
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

  static const Map<String, int> _pesoPorTipoPorDefecto = {
    'normal': 100,
    'heroe': 30,
    'icono': 8,
    'champions': 15,
    'finals_champions': 4,
  };

  Map<String, int> get _pesoPorTipo {
    final crudo = widget.sobre['peso_tipos'];
    if (crudo is Map) {
      return crudo.map((k, v) => MapEntry('$k'.toLowerCase(), (v as num).toInt()));
    }
    return _pesoPorTipoPorDefecto;
  }

  int _pesoTipoDe(Map<String, dynamic> jugador) {
    final tipo = '${jugador['rareza'] ?? 'normal'}'.toLowerCase().replaceAll(' ', '_');
    return _pesoPorTipo[tipo] ?? 100;
  }

  Map<String, dynamic> _elegirPonderadoPorTipo(List<Map<String, dynamic>> candidatos) {
    if (candidatos.length == 1) return candidatos.first;

    final pesos = candidatos.map(_pesoTipoDe).toList();
    final pesoTotal = pesos.fold<int>(0, (s, p) => s + p);
    if (pesoTotal <= 0) return candidatos[_random.nextInt(candidatos.length)];

    var roll = _random.nextInt(pesoTotal);
    for (var i = 0; i < candidatos.length; i++) {
      if (roll < pesos[i]) return candidatos[i];
      roll -= pesos[i];
    }
    return candidatos.last;
  }

  Map<String, dynamic> _elegirCartaPonderada(
    List<Map<String, dynamic>> pool, {
    Set<_EfectoRareza>? tramosPermitidos,
  }) {
    var tramosRestantes = List<Map<String, dynamic>>.from(_tramos);

    if (tramosPermitidos != null) {
      final filtrados =
          tramosRestantes.where((t) => tramosPermitidos.contains(t['efecto'])).toList();
      if (filtrados.isNotEmpty) tramosRestantes = filtrados;
    }

    while (tramosRestantes.isNotEmpty) {
      final pesoTotal = tramosRestantes.fold<int>(0, (s, t) => s + (t['peso'] as int));
      if (pesoTotal <= 0) break;
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
        return _elegirPonderadoPorTipo(candidatosTramo);
      }
      tramosRestantes.remove(tramoElegido);
    }
    return _elegirPonderadoPorTipo(pool);
  }

  void _aplicarPity(List<Map<String, dynamic>> elegidas, List<Map<String, dynamic>> poolRestante) {
    final huboVioletaOMejor = elegidas.any((j) {
      final e = _efectoDeCarta(j);
      return e == _EfectoRareza.violeta || e == _EfectoRareza.dorado;
    });

    _pityVioleta = huboVioletaOMejor ? 0 : _pityVioleta + elegidas.length;

    if (_pityVioleta >= _pityVioletaMax && !huboVioletaOMejor && poolRestante.isNotEmpty) {
      elegidas[elegidas.length - 1] = _elegirCartaPonderada(
        poolRestante,
        tramosPermitidos: {_EfectoRareza.violeta},
      );
      _pityVioleta = 0;
    }
  }

  bool get _sobreGarantizado => widget.sobre['garantia'] == true;
  static const Set<_EfectoRareza> _tramosGarantia = {_EfectoRareza.violeta, _EfectoRareza.dorado};

  List<Map<String, dynamic>> _abrirUnaCopia(List<Map<String, dynamic>> poolCompleto, int cantidadCartas) {
    var poolDisponible = List<Map<String, dynamic>>.from(poolCompleto);
    final cartas = <Map<String, dynamic>>[];

    for (var i = 0; i < cantidadCartas; i++) {
      if (poolDisponible.isEmpty) break;
      final carta = _elegirCartaPonderada(poolDisponible);
      cartas.add(carta);
      poolDisponible = poolDisponible.where((j) => j['id'] != carta['id']).toList();
    }

    if (_sobreGarantizado && cartas.isNotEmpty) {
      final yaCumpleGarantia = cartas.any((c) => _tramosGarantia.contains(_efectoDeCarta(c)));
      if (!yaCumpleGarantia) {
        cartas[cartas.length - 1] = _elegirCartaPonderada(
          poolDisponible.isNotEmpty ? poolDisponible : poolCompleto,
          tramosPermitidos: _tramosGarantia,
        );
      }
    }

    return cartas;
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

    if (widget.esPendiente) {
      if (!mounted) return;
      setState(() {
        _comprando = false;
        _comprado = true;
      });
      return;
    }

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
      final elegidas = _abrirUnaCopia(pool, cantidadCartas);

      _aplicarPity(elegidas, pool);
      elegidas.sort(_compararJugadores);

      if (mounted) {
        await context.read<PerfilProvider>().actualizarPity(
          _sobreId,
          {'violeta': _pityVioleta},
        );
      }

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
      setState(() {
        _efectoActivo = efecto;
        _fondoOcultoRuta = _rutaFondoParaCarta(elegidas.first);
      });

      _efecto.duration = _duracionEfecto(efecto);
      await _efecto.forward(from: 0);
      if (!mounted) return;

      await _rasgado.forward(from: 0);
      if (!mounted) return;
      setState(() => _efectoActivo = _EfectoRareza.ninguno);

      _revelado.duration = _duracionRevelado(efecto);
      setState(() {
        _cartasReveladas = elegidas;
        _abriendo = false;
      });
      _revelado.forward(from: 0);
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

  static const int _copiasBulk = 5;
  static const double _descuentoBulk = 0.9;

  int get precioBulk => ((widget.sobre['precio'] as int) * _copiasBulk * _descuentoBulk).round();

  Future<void> _comprarYAbrirBulk() async {
    if (_abriendo || _comprando) return;
    setState(() {
      _comprando = true;
      _abriendo = true;
      _error = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No hay sesión activa.');

      final perfil = await supabase.from('profiles').select('dinero').eq('id', userId).single();
      final dineroActual = (perfil['dinero'] ?? 0) as int;

      if (dineroActual < precioBulk) {
        setState(() {
          _error = 'No tienes suficiente dinero para abrir $_copiasBulk sobres.';
          _comprando = false;
          _abriendo = false;
        });
        return;
      }

      final catalogo = await supabase.from('jugadores').select();
      final todosCompletos = List<Map<String, dynamic>>.from(catalogo as List);
      final rarezas = List<String>.from(widget.sobre['rarezas'] as List);

      var pool = todosCompletos.where((j) => rarezas.contains(j['rareza'])).toList();
      if (pool.isEmpty) pool = todosCompletos;
      if (pool.isEmpty) throw Exception('No hay jugadores cargados en el catálogo.');

      final cantidadCartas = (widget.sobre['cantidad_cartas'] as int?) ?? 2;
      final elegidas = <Map<String, dynamic>>[];

      for (var copia = 0; copia < _copiasBulk; copia++) {
        elegidas.addAll(_abrirUnaCopia(pool, cantidadCartas));
      }

      _aplicarPity(elegidas, pool);
      elegidas.sort(_compararJugadores);

      if (elegidas.isNotEmpty) {
        _fondoOcultoRuta = _rutaFondoParaCarta(elegidas.first);
      }

      await supabase.from('profiles').update({'dinero': dineroActual - precioBulk}).eq('id', userId);

      if (mounted) {
        await context.read<PerfilProvider>().actualizarPity(
          _sobreId,
          {'violeta': _pityVioleta},
        );
        context.read<PerfilProvider>().actualizarDinero(dineroActual - precioBulk);
      }

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
          await supabase.from('inventario').update({'cantidad': cantidadActual + 1}).eq('id', inventarioId);
        } else {
          await supabase.from('inventario').insert({
            'user_id': userId,
            'jugador_id': jugadorId,
            'cantidad': 1,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _comprado = true;
        _comprando = false;
        _abriendo = false;
        _aperturaMasiva = true;
        _cartasReveladas = elegidas;
        _mostrarAmbas = true;
      });
    } catch (e) {
      debugPrint('ERROR AL ABRIR EN LOTE: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo completar la apertura múltiple.';
        _comprando = false;
        _abriendo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sobre = widget.sobre;
    final color = sobre['color'] as Color;
    final mostrandoFondoDeApertura = _comprado;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _cartasReveladas.isNotEmpty),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildFondoLogoVCT()),
          if (mostrandoFondoDeApertura) ...[
            Positioned.fill(child: _buildCapaFondoSolido(color)),
            Positioned.fill(child: _buildCapaBrillo(color)),
            Positioned.fill(child: _buildCapaFoto()),
          ],
          SafeArea(
            child: _cartasReveladas.isNotEmpty
                ? (_mostrarAmbas ? _buildCartasReveladas() : _buildRevelacionInicial())
                : (_comprado ? _buildSobreParaAbrir(sobre, color) : _buildVistaCompra(sobre, color)),
          ),
        ],
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
      //debugPrint('No se pudo cargar el logo: $error');
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

  Duration _duracionRevelado(_EfectoRareza efecto) {
    switch (efecto) {
      case _EfectoRareza.dorado:
        return const Duration(milliseconds: 6200);
      case _EfectoRareza.violeta:
        return const Duration(milliseconds: 5200);
      case _EfectoRareza.plata:
        return const Duration(milliseconds: 4400);
      case _EfectoRareza.ninguno:
        return const Duration(milliseconds: 500);
    }
  }

  String _rutaRegion(Map<String, dynamic> jugador) {
    final region = '${jugador['region'] ?? 'default'}'.toLowerCase();
    return 'assets/valorant/regiones/$region.png';
  }

  String _rutaBandera(Map<String, dynamic> jugador) {
    final pais = '${jugador['pais'] ?? ''}'.trim().toLowerCase();
    return 'assets/banderas/$pais.png';
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
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.18, 0.82, 1.0],
                  ).createShader(rect);
                },
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_matrizGris),
                  child: _logoRotadoCover(),
                ),
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
    return const SizedBox.shrink();
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
    if (_abriendo) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: Listenable.merge([_pulso, _fondoController]),
      builder: (context, child) {
        final colorSobre = widget.sobre['color'] as Color;
        final respiracion = _escalaPulso.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: respiracion,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorSobre.withOpacity(0.35),
                      blurRadius: 90,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            ...List.generate(6, (i) {
              final anguloBase = (i / 6) * 2 * pi;
              final angulo = anguloBase + _fondoController.value * 2 * pi;
              final radio = 150.0 + (sin(_fondoController.value * 2 * pi + i) * 12);
              final destello = (0.5 + 0.5 * sin(_fondoController.value * 2 * pi * 2 + i)).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(cos(angulo) * radio, sin(angulo) * radio * 0.6),
                child: Opacity(
                  opacity: 0.25 + destello * 0.55,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i.isEven ? colorSobre : Colors.white,
                      boxShadow: [
                        BoxShadow(color: (i.isEven ? colorSobre : Colors.white).withOpacity(0.8), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imagenSobre(sobre, color, 180),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),

          const SizedBox(height: 12),
          _buildPanelProbabilidades(color),

          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          if (_comprando)
            const CircularProgressIndicator(color: _kAcentoUI)
          else ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kPlataUI, _kPlataOscuraUI],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: _comprar,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.esPendiente ? Icons.card_giftcard : Icons.monetization_on,
                          color: const Color(0xFF17181B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.esPendiente ? 'ABRIR' : 'ABRIR 1 (${sobre['precio']})',
                          style: const TextStyle(
                              color: Color(0xFF17181B), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.esPendiente) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _kAcentoUI.withOpacity(0.7), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _comprarYAbrirBulk,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, color: _kAcentoUI),
                      const SizedBox(width: 8),
                      Text(
                        'ABRIR x5 ($precioBulk) · -10%',
                        style: const TextStyle(color: _kAcentoUI, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }


  Widget _buildPanelProbabilidades(Color color) {
    final pesoTotal = _tramos.fold<int>(0, (s, t) => s + (t['peso'] as int));

    String etiquetaTramo(_EfectoRareza efecto) => switch (efecto) {
          _EfectoRareza.dorado => 'Legendaria',
          _EfectoRareza.violeta => 'Épica',
          _EfectoRareza.plata => 'Rara',
          _EfectoRareza.ninguno => 'Común',
        };

    Color colorTramo(_EfectoRareza efecto) => switch (efecto) {
          _EfectoRareza.dorado => const Color(0xFFFFD700),
          _EfectoRareza.violeta => const Color(0xFF9B59B6),
          _EfectoRareza.plata => Colors.white70,
          _EfectoRareza.ninguno => Colors.white38,
        };

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: Colors.white54,
        iconColor: color,
        title: const Text(
          'Ver probabilidades',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        children: [
          for (final tramo in _tramos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorTramo(tramo['efecto'] as _EfectoRareza),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      etiquetaTramo(tramo['efecto'] as _EfectoRareza),
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ),
                  Text(
                    '${(((tramo['peso'] as int) / pesoTotal) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _visualAperturaSobre(Map<String, dynamic> sobre, Color color) {
    switch (_efectoActivo) {
      
      case _EfectoRareza.ninguno:
        return _aperturaDividida(sobre, color);

      case _EfectoRareza.plata:
        return _aperturaFlap(sobre, color);

      case _EfectoRareza.violeta:
        return _aperturaRasgada(sobre, color);

      case _EfectoRareza.dorado:
        return _aperturaTrizas(sobre, color, const Color(0xFFFFD700));
    }
  }

  Widget _buildCartaOculta(Color color) {
    return Container(
      width: 210,
      height: 296,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          _fondoOcultoRuta,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _aperturaDividida(Map<String, dynamic> sobre, Color color) {
    final t = Curves.easeInCubic.transform(_rasgado.value.clamp(0.0, 1.0));
    final desplazar = t * 260;
    final rotar = t * 0.30;
    final opacidad =
        (1 - ((_rasgado.value - 0.55).clamp(0.0, 0.45) / 0.45)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacidad,
      child: Transform.rotate(
        angle: _temblor.value,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildCartaOculta(color),
            Transform.translate(
              offset: Offset(0, -desplazar),
              child: Transform.rotate(
                angle: -rotar,
                child: ClipRect(
                  clipper: _MitadSobreClipperHorizontal(arriba: true),
                  child: _imagenSobre(sobre, color, 320),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, desplazar),
              child: Transform.rotate(
                angle: rotar,
                child: ClipRect(
                  clipper: _MitadSobreClipperHorizontal(arriba: false),
                  child: _imagenSobre(sobre, color, 320),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aperturaFlap(Map<String, dynamic> sobre, Color color) {
    final progresoSolapa = (_rasgado.value / 0.5).clamp(0.0, 1.0);
    final anguloSolapa = Curves.easeOutCubic.transform(progresoSolapa) * 2.4;
    final progresoCarta = ((_rasgado.value - 0.25) / 0.6).clamp(0.0, 1.0);
    final desplazarCarta = sin(pi * progresoCarta) * 150;
    final opacidadCarta = Curves.easeIn.transform((progresoCarta / 0.3).clamp(0.0, 1.0));

    final opacidadSobre =
        (1 - ((_rasgado.value - 0.8).clamp(0.0, 0.2) / 0.2)).clamp(0.0, 1.0);

    const double fraccionCorte = 0.20;

    return Transform.rotate(
      angle: _temblor.value * 0.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (progresoCarta > 0)
            Transform.translate(
              offset: Offset(0, -desplazarCarta),
              child: Opacity(
                opacity: opacidadCarta,
                child: _buildCartaOculta(color),
              ),
            ),
          Opacity(
            opacity: opacidadSobre,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRect(
                  clipper: _MitadSobreClipperHorizontal(arriba: false, fraccion: fraccionCorte),
                  child: _imagenSobre(sobre, color, 320),
                ),
                Transform(
                  alignment: FractionalOffset.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0025)
                    ..rotateY(-anguloSolapa),
                  child: ClipRect(
                    clipper: _MitadSobreClipperHorizontal(arriba: true, fraccion: fraccionCorte),
                    child: _imagenSobre(sobre, color, 320),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aperturaRasgada(Map<String, dynamic> sobre, Color color) {
    final progresoRasgado = (_rasgado.value / 0.45).clamp(0.0, 1.0);
    final progresoSeparacion = ((_rasgado.value - 0.45) / 0.55).clamp(0.0, 1.0);
    final separacionCurva = Curves.easeOutCubic.transform(progresoSeparacion);
    final desplazar = separacionCurva * 190;
    final opacidad =
        (1 - ((_rasgado.value - 0.7).clamp(0.0, 0.3) / 0.3)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacidad,
      child: Transform.rotate(
        angle: _temblor.value * 0.5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildCartaOculta(color),
            Transform.translate(
              offset: Offset(-desplazar, 0),
              child: ClipPath(
                clipper: _MitadSobreClipperDentado(izquierda: true),
                child: _imagenSobre(sobre, color, 320),
              ),
            ),
            Transform.translate(
              offset: Offset(desplazar, 0),
              child: ClipPath(
                clipper: _MitadSobreClipperDentado(izquierda: false),
                child: _imagenSobre(sobre, color, 320),
              ),
            ),
            if (progresoSeparacion <= 0.0)
              IgnorePointer(
                child: CustomPaint(
                  size: const Size(320, 450),
                  painter: _LineaRasgadoPainter(
                    progreso: progresoRasgado,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _aperturaTrizas(Map<String, dynamic> sobre, Color color, Color colorFragmentos) {
    final progresoEstallido = _rasgado.value.clamp(0.0, 1.0);
    final tEstallido = Curves.easeOutCirc.transform(progresoEstallido);
    
    final opacidadSobre = progresoEstallido < 0.05 ? 1.0 : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (progresoEstallido > 0)
          Opacity(
            opacity: (progresoEstallido * 4).clamp(0.0, 1.0),
            child: _buildCartaOculta(color),
          ),
          
        if (opacidadSobre > 0)
          Opacity(
            opacity: opacidadSobre,
            child: _imagenSobre(sobre, color, 320),
          ),
          
        if (progresoEstallido > 0 && progresoEstallido < 1.0)
          IgnorePointer(
            child: CustomPaint(
              size: const Size(230, 320),
              painter: _ParticulasPixelPainter(
                progreso: tEstallido,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSobreParaAbrir(Map<String, dynamic> sobre, Color color) {
    return GestureDetector(
      onTap: _abrirSobre,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
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
                          if (_efectoActivo == _EfectoRareza.ninguno) return const SizedBox.shrink();
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
                        animation: Listenable.merge([_rasgado, _pulso]),
                        builder: (context, child) {
                          if (!_abriendo) {
                            return Transform.scale(
                              scale: _escalaPulso.value,
                              child: _imagenSobre(sobre, color, 320),
                            );
                          }
                          return _visualAperturaSobre(sobre, color);
                        },
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

  String _rutaEquipo(Map<String, dynamic> jugador) {
    final region = '${jugador['region'] ?? 'default'}'.toLowerCase();
    final equipo = '${jugador['equipo'] ?? 'default'}'.toLowerCase();
    return 'assets/valorant/equipos/$region/$equipo.png';
  }

  List<double> _pulsoEtapa(double t, double inicio, double duracion) {
    final local = ((t - inicio) / duracion).clamp(0.0, 1.0);
    final entrada = (local / 0.35).clamp(0.0, 1.0);
    final salida = 1 - ((local - 0.75) / 0.25).clamp(0.0, 1.0);
    final opacidad = Curves.easeOut.transform(entrada) * salida;
    final escala = 0.55 + 0.45 * Curves.easeOutBack.transform(entrada);
    return [opacidad, escala];
  }

  Widget _bannerEtapa({
    required Widget contenido,
    required double opacidad,
    required double escala,
    required Color colorGlow,
  }) {
    return Opacity(
      opacity: opacidad,
      child: Transform.scale(
        scale: escala,
        child: contenido,
      ),
    );
  }

  Widget _buildRevelacionInicial() {
    final mejorCarta = _cartasReveladas.first;
    final efecto = _efectoDeCarta(mejorCarta);
    final esComun = efecto == _EfectoRareza.ninguno;

    Color colorGlow = Colors.transparent;
    if (efecto == _EfectoRareza.dorado) colorGlow = const Color(0xFFFFD700);
    if (efecto == _EfectoRareza.violeta) colorGlow = const Color(0xFF9B59B6);
    if (efecto == _EfectoRareza.plata) colorGlow = Colors.white;

    final intensidadGlow = switch (efecto) {
      _EfectoRareza.dorado => 1.3,
      _EfectoRareza.violeta => 1.0,
      _EfectoRareza.plata => 0.7,
      _EfectoRareza.ninguno => 0.0,
    };

    const double inicioPais = 0.00;
    const double inicioRegion = 0.22;
    const double inicioEquipo = 0.44;
    const double inicioPosicion = 0.66;
    const double duracionEtapa = 0.22;
    const double inicioResto = 0.88;

    return GestureDetector(
      onTap: () {
        if (_revelado.isAnimating) {
          _revelado.stop();
          setState(() => _revelado.value = 1.0);
          return;
        }
        setState(() => _mostrarAmbas = true);
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedBuilder(
          animation: _revelado,
          builder: (context, child) {
            final t = _revelado.value;

            if (esComun) {
              final opacidadResto = Curves.easeOut.transform((t / 0.6).clamp(0.0, 1.0));
              final opacidadTexto = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.92 + (0.08 * opacidadResto),
                    child: CartaWidget(
                      jugador: mejorCarta,
                      width: 280,
                      opacidadRegion: 1.0,
                      opacidadEquipo: 1.0,
                      opacidadPosicion: 1.0,
                      opacidadPais: 1.0,
                      opacidadResto: opacidadResto,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Opacity(
                    opacity: opacidadTexto,
                    child: const Text(
                      'Toca la pantalla para continuar',
                      style: TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 1.2),
                    ),
                  ),
                ],
              );
            }

            final opacidadPais = Curves.easeOut.transform(((t - inicioPais) / duracionEtapa).clamp(0.0, 1.0));
            final opacidadRegion = Curves.easeOut.transform(((t - inicioRegion) / duracionEtapa).clamp(0.0, 1.0));
            final opacidadEquipo = Curves.easeOut.transform(((t - inicioEquipo) / duracionEtapa).clamp(0.0, 1.0));
            final opacidadPosicion = Curves.easeOut.transform(((t - inicioPosicion) / duracionEtapa).clamp(0.0, 1.0));

            final bannerPais = _pulsoEtapa(t, inicioPais, duracionEtapa);
            final bannerRegion = _pulsoEtapa(t, inicioRegion, duracionEtapa);
            final bannerEquipo = _pulsoEtapa(t, inicioEquipo, duracionEtapa);
            final bannerPosicion = _pulsoEtapa(t, inicioPosicion, duracionEtapa);

            final localFinal = ((t - inicioResto) / (1.0 - inicioResto)).clamp(0.0, 1.0);
            final opacidadResto = Curves.easeOut.transform((localFinal / 0.4).clamp(0.0, 1.0));
            final opacidadFlash = opacidadResto < 1.0
                ? Curves.easeOut.transform((localFinal / 0.18).clamp(0.0, 1.0)) *
                    (1 - Curves.easeIn.transform((((localFinal - 0.18) / 0.22).clamp(0.0, 1.0))))
                : 0.0;
            final opacidadTexto = ((t - 0.96) / 0.04).clamp(0.0, 1.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 82,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (bannerPais[0] > 0)
                        _bannerEtapa(
                          opacidad: bannerPais[0],
                          escala: bannerPais[1],
                          colorGlow: colorGlow,
                          contenido: SizedBox(
                            width: 68,
                            height: 46,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                _rutaBandera(mejorCarta),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.flag, color: colorGlow, size: 38),
                              ),
                            ),
                          ),
                        ),
                      if (bannerRegion[0] > 0)
                        _bannerEtapa(
                          opacidad: bannerRegion[0],
                          escala: bannerRegion[1],
                          colorGlow: colorGlow,
                          contenido: SizedBox(
                            width: 58,
                            height: 58,
                            child: Image.asset(
                              _rutaRegion(mejorCarta),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.public, color: colorGlow, size: 42),
                            ),
                          ),
                        ),
                      if (bannerEquipo[0] > 0)
                        _bannerEtapa(
                          opacidad: bannerEquipo[0],
                          escala: bannerEquipo[1],
                          colorGlow: colorGlow,
                          contenido: SizedBox(
                            width: 58,
                            height: 58,
                            child: Image.asset(
                              _rutaEquipo(mejorCarta),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.shield, color: colorGlow, size: 42),
                            ),
                          ),
                        ),
                      if (bannerPosicion[0] > 0)
                        _bannerEtapa(
                          opacidad: bannerPosicion[0],
                          escala: bannerPosicion[1],
                          colorGlow: colorGlow,
                          contenido: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gps_fixed, color: colorGlow, size: 30),
                              const SizedBox(width: 12),
                              Text(
                                '${mejorCarta['posicion'] ?? 'Posición'}'.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 1.2,
                                  shadows: [Shadow(color: colorGlow, blurRadius: 12)],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (opacidadFlash > 0)
                      Opacity(
                        opacity: opacidadFlash,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [colorGlow, colorGlow.withOpacity(0.0)],
                            ),
                          ),
                        ),
                      ),
                    Transform.scale(
                      scale: 0.92 + (0.08 * opacidadResto),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: opacidadResto > 0.3 && intensidadGlow > 0
                              ? [
                                  BoxShadow(
                                    color: colorGlow.withOpacity(
                                        0.8 * opacidadResto * intensidadGlow.clamp(0.0, 1.0)),
                                    blurRadius: 80 * opacidadResto * intensidadGlow,
                                    spreadRadius: 20 * opacidadResto * intensidadGlow,
                                  )
                                ]
                              : null,
                        ),
                        child: CartaWidget(
                          jugador: mejorCarta,
                          width: 280,
                          opacidadRegion: opacidadRegion,
                          opacidadEquipo: opacidadEquipo,
                          opacidadPosicion: opacidadPosicion,
                          opacidadPais: opacidadPais,
                          opacidadResto: opacidadResto,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                Opacity(
                  opacity: opacidadTexto,
                  child: const Text(
                    'Toca la pantalla para continuar',
                    style: TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 1.2),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartasReveladas() {
    Map<String, dynamic>? mejor;
    for (final carta in _cartasReveladas) {
      if (mejor == null || ((carta['ovr'] ?? 0) as num) > ((mejor['ovr'] ?? 0) as num)) {
        mejor = carta;
      }
    }
    final efectoMejor = mejor != null ? _efectoDeCarta(mejor) : _EfectoRareza.ninguno;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            children: [
              Text(
                '¡Obtuviste ${_cartasReveladas.length} cartas!',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_aperturaMasiva && efectoMejor != _EfectoRareza.ninguno) ...[
                const SizedBox(height: 6),
                Text(
                  efectoMejor == _EfectoRareza.dorado
                      ? '★ ¡Sacaste una LEGENDARIA! ★'
                      : (efectoMejor == _EfectoRareza.violeta ? '¡Sacaste una ÉPICA!' : '¡Sacaste una carta RARA!'),
                  style: TextStyle(
                    color: efectoMejor == _EfectoRareza.dorado
                        ? const Color(0xFFFFD700)
                        : (efectoMejor == _EfectoRareza.violeta ? const Color(0xFF9B59B6) : Colors.white70),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ],
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
                side: BorderSide(color: _kPlataUI.withOpacity(0.5), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'VOLVER A LA TIENDA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MitadSobreClipperHorizontal extends CustomClipper<Rect> {
  final bool arriba;
  final double fraccion;

  _MitadSobreClipperHorizontal({required this.arriba, this.fraccion = 0.5});

  @override
  Rect getClip(Size size) {
    final cutY = size.height * fraccion;
    return arriba
        ? Rect.fromLTWH(0, 0, size.width, cutY)
        : Rect.fromLTWH(0, cutY, size.width, size.height - cutY);
  }

  @override
  bool shouldReclip(covariant _MitadSobreClipperHorizontal oldClipper) =>
      oldClipper.arriba != arriba || oldClipper.fraccion != fraccion;
}

class _MitadSobreClipperDentado extends CustomClipper<Path> {
  final bool izquierda;
  final int dientes;
  final double amplitud;
  _MitadSobreClipperDentado({
    required this.izquierda,
    this.dientes = 10,
    this.amplitud = 9,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final midX = size.width / 2;
    final pasoY = size.height / dientes;

    if (izquierda) {
      path.moveTo(0, 0);
      path.lineTo(midX, 0);
      for (int i = 1; i <= dientes; i++) {
        final y = pasoY * i;
        final desfaseX = i.isOdd ? amplitud : -amplitud;
        path.lineTo(midX + desfaseX, y);
      }
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(midX, 0);
      for (int i = 1; i <= dientes; i++) {
        final y = pasoY * i;
        final desfaseX = i.isOdd ? amplitud : -amplitud;
        path.lineTo(midX + desfaseX, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _MitadSobreClipperDentado oldClipper) =>
      oldClipper.izquierda != izquierda ||
      oldClipper.dientes != dientes ||
      oldClipper.amplitud != amplitud;
}

class _LineaRasgadoPainter extends CustomPainter {
  final double progreso;
  final Color color;
  _LineaRasgadoPainter({required this.progreso, required this.color});

  static const int _dientes = 10;
  static const double _amplitud = 9;

  @override
  void paint(Canvas canvas, Size size) {
    if (progreso <= 0) return;
    final midX = size.width / 2;
    final alturaVisible = size.height * progreso;
    final pasoY = size.height / _dientes;

    final path = Path()..moveTo(midX, 0);
    for (int i = 1; i <= _dientes; i++) {
      final y = pasoY * i;
      if (y > alturaVisible) break;
      final desfaseX = i.isOdd ? _amplitud : -_amplitud;
      path.lineTo(midX + desfaseX, y);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineaRasgadoPainter oldDelegate) =>
      oldDelegate.progreso != progreso || oldDelegate.color != color;
}

class _ParticulasPixelPainter extends CustomPainter {
  final double progreso;

  _ParticulasPixelPainter({required this.progreso});

  @override
  void paint(Canvas canvas, Size size) {
    if (progreso <= 0 || progreso >= 1) return;

    final rnd = Random(42); 
    const int cols = 15;
    const int rows = 22;
    final double blockW = size.width / cols;
    final double blockH = size.height / rows;
    final paint = Paint();

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double cx = (i + 0.5) * blockW;
        final double cy = (j + 0.5) * blockH;
        final double dx = cx - size.width / 2;
        final double dy = cy - size.height / 2;
        final double rndVx = (rnd.nextDouble() - 0.5) * 140;
        final double rndVy = (rnd.nextDouble() - 0.5) * 140;
        final double rndZ = rnd.nextDouble(); 
        final double moveX = cx + (dx * progreso * 2.5) + (rndVx * progreso);
        final double moveY = cy + (dy * progreso * 2.5) + (rndVy * progreso);
        final double escala = (1.0 - progreso) * (1.0 + rndZ * progreso * 2.0);
        final double opacidad = (1.0 - (progreso * 1.2)).clamp(0.0, 1.0);

        if (opacidad <= 0) continue;

        final rect = Rect.fromCenter(
          center: Offset(moveX, moveY),
          width: blockW * 1.05 * escala, 
          height: blockH * 1.05 * escala,
        );

        final esGris = rnd.nextDouble() > 0.6;
        paint.color = esGris
            ? const Color(0xFF2A2A2A).withOpacity(opacidad)
            : Colors.black.withOpacity(opacidad);

        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticulasPixelPainter oldDelegate) {
    return oldDelegate.progreso != progreso;
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