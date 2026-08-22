import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/visual.dart';
import '../providers/perfil_provider.dart';
import '../widgets/cartas_widgets.dart';
import '../widgets/panel_pincelado.dart';

const List<String> _kStatsOcultables = ['ovr', 'aim', 'men', 'imp', 'uti', 'rea', 'clu'];

const Map<String, String> _kEtiquetaStat = {
  'ovr': 'OVR',
  'aim': 'AIM',
  'men': 'MEN',
  'imp': 'IMP',
  'uti': 'UTI',
  'rea': 'REA',
  'clu': 'CLU',
};

enum _Fase { cargando, apuesta, jugando, revelando, error }

enum _Eleccion { mayor, igual, menor }

class MayorMenorScreen extends StatefulWidget {
  const MayorMenorScreen({super.key});

  @override
  State<MayorMenorScreen> createState() => _MayorMenorScreenState();
}

class _MayorMenorScreenState extends State<MayorMenorScreen> {
  final supabase = Supabase.instance.client;
  final _random = Random();

  _Fase _fase = _Fase.cargando;
  String? _error;

  List<Map<String, dynamic>> _catalogo = [];

  int _apuesta = 0;
  int _pozo = 0;
  int _racha = 0;

  Map<String, dynamic>? _cartaArriba;
  Map<String, dynamic>? _cartaAbajo;
  String _statOculto = 'ovr';

  bool _revelado = false;
  bool? _acierto;

  static const List<int> _opcionesApuesta = [100, 500, 1000];

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final datos = await supabase.from('jugadores').select();
      final catalogo = List<Map<String, dynamic>>.from(datos as List);

      if (catalogo.length < 2) {
        throw Exception('El catálogo no tiene suficientes jugadores.');
      }

      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _fase = _Fase.apuesta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _Fase.error;
        _error = 'No se pudo cargar el catálogo de jugadores.';
      });
    }
  }

  num _valorNumerico(Map<String, dynamic> jugador, String stat) {
    final valor = jugador[stat];
    return valor is num ? valor : (num.tryParse('$valor') ?? 0);
  }

  Map<String, dynamic> _cartaConStatOculto(Map<String, dynamic> jugador, String stat) {
    final copia = Map<String, dynamic>.from(jugador);
    copia[stat] = '?';
    return copia;
  }

  Map<String, dynamic> _cartaAleatoria({Map<String, dynamic>? distintaDe}) {
    Map<String, dynamic> elegida;
    do {
      elegida = _catalogo[_random.nextInt(_catalogo.length)];
    } while (distintaDe != null &&
        elegida['nombre'] == distintaDe['nombre'] &&
        _catalogo.length > 1);
    return elegida;
  }

  void _iniciarApuesta(int monto) {
    final perfil = context.read<PerfilProvider>();
    final dineroActual = perfil.dinero ?? 0;
    if (monto > dineroActual) return;

    final referencia = _cartaAleatoria();
    final oculta = _cartaAleatoria(distintaDe: referencia);
    final stat = _kStatsOcultables[_random.nextInt(_kStatsOcultables.length)];

    setState(() {
      _apuesta = monto;
      _pozo = monto;
      _racha = 0;
      _cartaArriba = referencia;
      _cartaAbajo = oculta;
      _statOculto = stat;
      _revelado = false;
      _acierto = null;
      _fase = _Fase.jugando;
    });

    perfil.actualizarDinero(dineroActual - monto);
  }

  Future<void> _elegir(_Eleccion eleccion) async {
    if (_fase != _Fase.jugando || _cartaArriba == null || _cartaAbajo == null) return;

    final valorArriba = _valorNumerico(_cartaArriba!, _statOculto);
    final valorAbajo = _valorNumerico(_cartaAbajo!, _statOculto);

    bool correcto;
    switch (eleccion) {
      case _Eleccion.mayor:
        correcto = valorAbajo > valorArriba;
        break;
      case _Eleccion.igual:
        correcto = valorAbajo == valorArriba;
        break;
      case _Eleccion.menor:
        correcto = valorAbajo < valorArriba;
        break;
    }

    setState(() {
      _fase = _Fase.revelando;
      _revelado = true;
      _acierto = correcto;
    });

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    if (correcto) {
      final incremento = eleccion == _Eleccion.igual ? _apuesta * 3 : _apuesta;
      final nuevaReferencia = _cartaAbajo!;
      final nuevaOculta = _cartaAleatoria(distintaDe: nuevaReferencia);
      final nuevoStat = _kStatsOcultables[_random.nextInt(_kStatsOcultables.length)];

      setState(() {
        _pozo += incremento;
        _racha += 1;
        _cartaArriba = nuevaReferencia;
        _cartaAbajo = nuevaOculta;
        _statOculto = nuevoStat;
        _revelado = false;
        _acierto = null;
        _fase = _Fase.jugando;
      });
    } else {
      setState(() {
        _pozo = 0;
        _racha = 0;
        _fase = _Fase.apuesta;
      });
      if (!mounted) return;
      _mostrarSnackbar('Perdiste la apuesta. ¡Intenta de nuevo!', TemaJuego.rojo);
    }
  }

  void _retirarse() {
    if (_fase != _Fase.jugando) return;
    final ganancia = _pozo;

    final perfil = context.read<PerfilProvider>();
    final dineroActual = perfil.dinero ?? 0;
    perfil.actualizarDinero(dineroActual + ganancia);

    setState(() {
      _pozo = 0;
      _racha = 0;
      _fase = _Fase.apuesta;
    });
    _mostrarSnackbar('Te retiraste con $ganancia monedas', TemaJuego.dorado);
  }

  void _mostrarSnackbar(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TemaJuego.fondoPanel,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.circle, color: color, size: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        title: const Text(
          'MAYOR O MENOR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TemaJuego.fondo, TemaJuego.fondo.withOpacity(0.92)],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildCuerpo(),
          ),
        ),
      ),
    );
  }

  Widget _buildCuerpo() {
    switch (_fase) {
      case _Fase.cargando:
        return const Center(
          key: ValueKey('cargando'),
          child: CircularProgressIndicator(color: TemaJuego.dorado),
        );
      case _Fase.error:
        return Center(
          key: const ValueKey('error'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white38, size: 40),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Ocurrió un error.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _fase = _Fase.cargando);
                    _cargarCatalogo();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: TemaJuego.rojo),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      case _Fase.apuesta:
        return _buildFaseApuesta();
      case _Fase.jugando:
      case _Fase.revelando:
        return _buildFaseJuego();
    }
  }

  Widget _buildFaseApuesta() {
    return Center(
      key: const ValueKey('apuesta'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    TemaJuego.dorado.withOpacity(0.28),
                    TemaJuego.dorado.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: TemaJuego.dorado.withOpacity(0.6), width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: TemaJuego.dorado.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.casino, color: TemaJuego.dorado, size: 46),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿CUÁNTO QUIERES APOSTAR?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Consumer<PerfilProvider>(
              builder: (context, perfil, _) {
                final dinero = perfil.dinero;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: TemaJuego.fondoPanel,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: TemaJuego.dorado.withOpacity(0.35), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: TemaJuego.dorado, size: 17),
                      const SizedBox(width: 7),
                      Text(
                        dinero == null ? 'Cargando saldo...' : 'Disponible: ${_formatearMonto(dinero)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Consumer<PerfilProvider>(
              builder: (context, perfil, _) {
                final dinero = perfil.dinero ?? 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _opcionesApuesta
                      .map((m) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: _botonApuesta(m, dinero),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatearMonto(int monto) {
    final texto = monto.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      final posicionDesdeElFinal = texto.length - i;
      buffer.write(texto[i]);
      if (posicionDesdeElFinal > 1 && posicionDesdeElFinal % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  Widget _botonApuesta(int monto, int dineroDisponible) {
    final disponible = monto <= dineroDisponible;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disponible ? 1.0 : 0.35,
      child: SizedBox(
        width: 98,
        height: 104,
        child: PanelPincelado(
          onTap: disponible ? () => _iniciarApuesta(monto) : null,
          colorBase: TemaJuego.fondoPanel,
          colorAcento: TemaJuego.dorado,
          corte: 12,
          grosorBorde: 1.6,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TemaJuego.dorado.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TemaJuego.dorado.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.monetization_on, color: TemaJuego.dorado, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatearMonto(monto),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaseJuego() {
    final arriba = _cartaArriba!;
    final abajo = _cartaAbajo!;

    return Column(
      key: const ValueKey('juego'),
      children: [
        _buildBarraSuperior(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Text(
                  'ESTADÍSTICA EN JUEGO: ${_kEtiquetaStat[_statOculto]}',
                  style: const TextStyle(
                    color: TemaJuego.dorado,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildTarjetaCarta(
                    key: ValueKey('arriba-${arriba['nombre']}-$_statOculto'),
                    jugador: arriba,
                    oculto: false,
                    etiqueta: 'REFERENCIA',
                    colorBorde: TemaJuego.cian,
                  ),
                ),
                const SizedBox(height: 10),
                _buildIndicadorCentral(),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildTarjetaCarta(
                    key: ValueKey('abajo-${abajo['nombre']}-$_statOculto-$_revelado'),
                    jugador: abajo,
                    oculto: !_revelado,
                    etiqueta: '¿MAYOR, IGUAL O MENOR?',
                    colorBorde: _acierto == null
                        ? TemaJuego.dorado
                        : (_acierto == true ? const Color(0xFF2ECC71) : TemaJuego.rojo),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildControles(),
      ],
    );
  }

  Widget _buildBarraSuperior() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _chip(icono: Icons.local_fire_department, texto: 'Racha: $_racha', color: TemaJuego.dorado),
          const SizedBox(width: 10),
          _chip(icono: Icons.savings, texto: 'Pozo: $_pozo', color: const Color(0xFF2ECC71)),
          const Spacer(),
          _botonRetirarse(),
        ],
      ),
    );
  }

  Widget _chip({required IconData icono, required String texto, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TemaJuego.fondoPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 15),
          const SizedBox(width: 6),
          Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _botonRetirarse() {
    final activo = _fase == _Fase.jugando;
    return GestureDetector(
      onTap: activo ? _retirarse : null,
      child: Opacity(
        opacity: activo ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: TemaJuego.rojo.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TemaJuego.rojo, width: 1.6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, color: TemaJuego.rojo, size: 15),
              SizedBox(width: 6),
              Text('RETIRARSE', style: TextStyle(color: TemaJuego.rojo, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicadorCentral() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _acierto == null
          ? Icon(Icons.swap_vert, key: const ValueKey('neutro'), color: TemaJuego.dorado.withOpacity(0.7), size: 28)
          : Icon(
              _acierto! ? Icons.check_circle : Icons.cancel,
              key: ValueKey('resultado-$_acierto'),
              color: _acierto! ? const Color(0xFF2ECC71) : TemaJuego.rojo,
              size: 32,
            ),
    );
  }

  Widget _buildTarjetaCarta({
    required Key key,
    required Map<String, dynamic> jugador,
    required bool oculto,
    required String etiqueta,
    required Color colorBorde,
  }) {
    final jugadorMostrado = oculto ? _cartaConStatOculto(jugador, _statOculto) : jugador;

    return Container(
      key: key,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde.withOpacity(0.8), width: 2.2),
        boxShadow: [BoxShadow(color: colorBorde.withOpacity(0.3), blurRadius: 16, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: TextStyle(color: colorBorde, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 190,
            child: CartaWidget(jugador: jugadorMostrado, width: 190),
          ),
        ],
      ),
    );
  }

  Widget _buildControles() {
    final activo = _fase == _Fase.jugando;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: _botonEleccion(
              texto: 'MENOR',
              icono: Icons.arrow_downward,
              color: TemaJuego.rojo,
              activo: activo,
              onTap: () => _elegir(_Eleccion.menor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _botonEleccion(
              texto: 'IGUAL',
              icono: Icons.drag_handle,
              color: const Color(0xFF8A8F98),
              activo: activo,
              onTap: () => _elegir(_Eleccion.igual),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _botonEleccion(
              texto: 'MAYOR',
              icono: Icons.arrow_upward,
              color: const Color(0xFF2ECC71),
              activo: activo,
              onTap: () => _elegir(_Eleccion.mayor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEleccion({
    required String texto,
    required IconData icono,
    required Color color,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: activo ? onTap : null,
      child: Opacity(
        opacity: activo ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Icon(icono, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                texto,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}