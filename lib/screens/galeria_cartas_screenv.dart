import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/carta_widget.dart';
import '../widgets/carta_mini_widget.dart';

const Color _kFondo = Color(0xFF0B0C10);
const Color _kFondoPanel = Color(0xFF1C1E22);
const Color _kDorado = Color(0xFFD9B65C);
const Color _kPlata = Color(0xFFC7CBD1);
const Color _kPlataOscuro = Color(0xFF3A3D42);

const List<Map<String, String>> _rarezas = [
  {'valor': 'todas', 'etiqueta': 'TODAS'},
  {'valor': 'normal', 'etiqueta': 'NORMAL'},
  {'valor': 'icono', 'etiqueta': 'ICONO'},
  {'valor': 'heroe', 'etiqueta': 'HEROE'},
  {'valor': 'tos1', 'etiqueta': 'TOS1'},
  {'valor': 'tos2', 'etiqueta': 'TOS2'},
];

const List<double> _kMatrizGris = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

class GaleriaCartasScreen extends StatefulWidget {
  const GaleriaCartasScreen({super.key});

  @override
  State<GaleriaCartasScreen> createState() => _GaleriaCartasScreenState();
}

class _GaleriaCartasScreenState extends State<GaleriaCartasScreen> {
  final supabase = Supabase.instance.client;
  late Future<_DatosGaleria> _future;

  Map<String, dynamic>? _cartaSeleccionada;
  bool _seleccionadaPoseida = false;

  String _rarezaFiltro = 'todas';

  @override
  void initState() {
    super.initState();
    _future = _cargarGaleria();
  }

  Future<_DatosGaleria> _cargarGaleria() async {
    final todos = await supabase.from('jugadores').select();
    final todasLasCartas = List<Map<String, dynamic>>.from(todos as List)
      ..sort((a, b) => (((b['ovr'] ?? 0) as num)).compareTo((a['ovr'] ?? 0) as num));

    final userId = supabase.auth.currentUser?.id;
    var poseidas = <dynamic>{};
    if (userId != null) {
      final inv = await supabase
          .from('inventario')
          .select('jugador_id')
          .eq('user_id', userId);
      poseidas = (inv as List).map((fila) => fila['jugador_id']).toSet();
    }

    return _DatosGaleria(cartas: todasLasCartas, poseidasIds: poseidas);
  }

  Future<void> _refrescar() async {
    setState(() {
      _future = _cargarGaleria();
    });
    await _future;
  }

  List<Map<String, dynamic>> _aplicarFiltro(List<Map<String, dynamic>> cartas) {
    if (_rarezaFiltro == 'todas') return cartas;
    return cartas.where((c) {
      final rareza = '${c['rareza'] ?? 'normal'}'.toLowerCase().replaceAll(' ', '_');
      return rareza == _rarezaFiltro;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text('Galería', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<_DatosGaleria>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kDorado));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudo cargar la galería.', style: TextStyle(color: Colors.white54)),
            );
          }

          final datos = snapshot.data!;
          final total = datos.cartas.length;
          final descubiertas = datos.cartas.where((c) => datos.poseidasIds.contains(c['id'])).length;
          final progreso = total == 0 ? 0.0 : descubiertas / total;
          final cartasFiltradas = _aplicarFiltro(datos.cartas);

          return Stack(
            children: [
              RefreshIndicator(
                color: _kDorado,
                backgroundColor: _kFondoPanel,
                onRefresh: _refrescar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                  children: [
                    _buildProgreso(descubiertas, total, progreso),
                    const SizedBox(height: 14),
                    _buildFiltrosRareza(),
                    const SizedBox(height: 14),
                    if (cartasFiltradas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            'No hay cartas con este filtro.',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartasFiltradas.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 15,
                          childAspectRatio: 400 / 450,
                        ),
                        itemBuilder: (context, index) {
                          final carta = cartasFiltradas[index];
                          final poseida = datos.poseidasIds.contains(carta['id']);
                          return _casillaCarta(carta, poseida);
                        },
                      ),
                  ],
                ),
              ),
              if (_cartaSeleccionada != null) _buildOverlayDetalle(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgreso(int descubiertas, int total, double progreso) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.06), _kFondoPanel.withOpacity(0.6)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.style, color: _kDorado, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'CARTAS DESCUBIERTAS',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    '$descubiertas / $total',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(_kDorado),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltrosRareza() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rarezas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final r = _rarezas[index];
          final activo = _rarezaFiltro == r['valor'];
          return GestureDetector(
            onTap: () => setState(() => _rarezaFiltro = r['valor']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: activo
                    ? const LinearGradient(colors: [_kPlata, _kPlataOscuro])
                    : const LinearGradient(colors: [Color(0xFF1C1E22), Color(0xFF1C1E22)]),
                border: Border.all(color: activo ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                r['etiqueta']!,
                style: TextStyle(
                  color: activo ? const Color(0xFF17181B) : Colors.white54,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _casillaCarta(Map<String, dynamic> carta, bool poseida) {
    return GestureDetector(
      onTap: () => setState(() {
        _cartaSeleccionada = carta;
        _seleccionadaPoseida = poseida;
      }),
      child: Stack(
        alignment: Alignment.center,
        children: [
          poseida
              ? CartaMiniWidget(jugador: carta)
              : Opacity(
                  opacity: 0.42,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_kMatrizGris),
                    child: CartaMiniWidget(jugador: carta),
                  ),
                ),
          if (!poseida)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.55),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.lock, color: Colors.white70, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayDetalle(BuildContext context) {
    final carta = _cartaSeleccionada!;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _cartaSeleccionada = null),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _seleccionadaPoseida
                    ? CartaWidget(
                        jugador: carta,
                        width: MediaQuery.of(context).size.width * 0.82,
                      )
                    : ColorFiltered(
                        colorFilter: const ColorFilter.matrix(_kMatrizGris),
                        child: Opacity(
                          opacity: 0.55,
                          child: CartaWidget(
                            jugador: carta,
                            width: MediaQuery.of(context).size.width * 0.82,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                if (!_seleccionadaPoseida)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kFondoPanel,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white54, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Aún no tienes esta carta.\nConsíguela en sobres o en la tienda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatosGaleria {
  final List<Map<String, dynamic>> cartas;
  final Set<dynamic> poseidasIds;

  _DatosGaleria({required this.cartas, required this.poseidasIds});
}
