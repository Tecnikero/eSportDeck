import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/carta_widget.dart';
import '../widgets/sesion_dialog.dart';
import '../providers/perfil_provider.dart';

// ---------- ORDEN POR OVR ----------
// Se alterna presionando el circulito "OVR": sin orden -> descendente -> ascendente -> sin orden.
enum _OrdenOvr { ninguno, descendente, ascendente }

const Color _kFondo = Color(0xFF050914);
const Color _kDorado = Color(0xFFFFD700);
const Color _kFondoPanel = Color(0xFF11172A);

class ColeccionScreen extends StatefulWidget {
  const ColeccionScreen({super.key});

  @override
  State<ColeccionScreen> createState() => _ColeccionScreenState();
}

class _ColeccionScreenState extends State<ColeccionScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _cartaSeleccionada;
  late Future<List<Map<String, dynamic>>> _futureJugadores;

  // ---------- FILTROS ----------
  String? _regionFiltro; // null = todas las regiones
  String? _equipoFiltro; // null = todos los equipos
  _OrdenOvr _ordenOvr = _OrdenOvr.ninguno;

  // Controla si el panel de circulitos de cada filtro está desplegado.
  bool _regionExpandida = false;
  bool _equipoExpandido = false;

  // Cada equipo vive dentro de una carpeta de región (assets/valorant/equipos/<region>/<equipo>.png),
  // así que necesitamos saber a qué región pertenece cada equipo para armar la ruta del ícono.
  Map<String, String> _equipoPorRegion = {};

  @override
  void initState() {
    super.initState();
    _futureJugadores = _cargarJugadores();
  }

  Future<List<Map<String, dynamic>>> _cargarJugadores() async {
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
        final Map<String, dynamic> carta = Map<String, dynamic>.from(jugadorData);
        
        carta['_inventario_id'] = fila['id'];
        carta['_cantidad'] = (fila['cantidad'] ?? 1) as int;

        misCartas.add(carta);
      }
    }

    return misCartas;
  }

  Future<void> _venderCarta(Map<String, dynamic> carta) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final inventarioId = carta['_inventario_id'];
    final cantidadActual = carta['_cantidad'] as int;
    final precioVenta = _precioVenta(carta);

    try {
      if (cantidadActual > 1) {
        await supabase
            .from('inventario')
            .update({'cantidad': cantidadActual - 1})
            .eq('id', inventarioId);
      } else {
        await supabase
            .from('inventario')
            .delete()
            .eq('id', inventarioId);
      }

      final perfil = await supabase.from('profiles').select('dinero').eq('id', userId).single();
      final monedasActuales = (perfil['dinero'] ?? 1000) as int;
      final nuevoSaldo = monedasActuales + precioVenta;

      await supabase
          .from('profiles')
          .update({'dinero': nuevoSaldo})
          .eq('id', userId);

      if (mounted) {
  context.read<PerfilProvider>().actualizarDinero(nuevoSaldo);
  setState(() {
    _cartaSeleccionada = null;
    _futureJugadores = _cargarJugadores();
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('¡Vendiste a ${carta['nombre']} por $precioVenta monedas!'),
      backgroundColor: Colors.green,
    ),
  );
}
    } catch (e) {
      debugPrint('Error al vender: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo procesar la venta.'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------- VENTA MASIVA DE REPETIDAS ----------
  // "Repetida" = toda copia por encima de la primera de cada carta (siempre
  // se conserva 1 unidad de cada una). Se vende todo de una sola vez al
  // precio normal según rareza.

  List<Map<String, dynamic>> _repetidasDe(List<Map<String, dynamic>> jugadores) =>
      jugadores.where((c) => (c['_cantidad'] as int? ?? 1) > 1).toList();

  int _totalCopiasRepetidas(List<Map<String, dynamic>> repetidas) =>
      repetidas.fold<int>(0, (suma, c) => suma + ((c['_cantidad'] as int) - 1));

  int _totalGananciaRepetidas(List<Map<String, dynamic>> repetidas) => repetidas.fold<int>(
      0, (suma, c) => suma + (_precioVenta(c) * ((c['_cantidad'] as int) - 1)));

  Future<void> _confirmarVenderTodasLasRepetidas(List<Map<String, dynamic>> repetidas) async {
    final totalCopias = _totalCopiasRepetidas(repetidas);
    final totalGanado = _totalGananciaRepetidas(repetidas);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _kFondoPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sell, color: _kDorado, size: 36),
              const SizedBox(height: 10),
              const Text(
                '¿Vender todas las repetidas?',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Se conserva 1 copia de cada carta y se venden las otras $totalCopias por un total de \$$totalGanado.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kDorado,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Vender', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true) return;
    await _venderTodasLasRepetidas(repetidas, totalCopias, totalGanado);
  }

  Future<void> _venderTodasLasRepetidas(
      List<Map<String, dynamic>> repetidas, int totalCopias, int totalGanado) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Deja 1 unidad de cada carta repetida (nunca elimina la fila).
      for (final carta in repetidas) {
        await supabase
            .from('inventario')
            .update({'cantidad': 1})
            .eq('id', carta['_inventario_id']);
      }

      final perfil = await supabase.from('profiles').select('dinero').eq('id', userId).single();
      final monedasActuales = (perfil['dinero'] ?? 1000) as int;
      final nuevoSaldo = monedasActuales + totalGanado;

      await supabase.from('profiles').update({'dinero': nuevoSaldo}).eq('id', userId);

      if (!mounted) return;
      context.read<PerfilProvider>().actualizarDinero(nuevoSaldo);
      setState(() {
        _cartaSeleccionada = null;
        _futureJugadores = _cargarJugadores();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Vendiste $totalCopias cartas repetidas por $totalGanado monedas!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error al vender repetidas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo procesar la venta masiva.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------- PRECIOS DE VENTA RÁPIDA (por rareza) ----------
  // Las bandas de OVR coinciden con las probabilidades de los sobres:
  // Común 0-80 · Rara 81-88 · Épica 89-91 · Legendaria 92-99.
  static const Map<String, int> _precioVentaPorRareza = {
    'comun': 100,
    'rara': 250,
    'epica': 300,
    'legendaria': 500,
  };

  String _rarezaPorOvr(num ovr) {
    if (ovr >= 92) return 'legendaria';
    if (ovr >= 89) return 'epica';
    if (ovr >= 81) return 'rara';
    return 'comun';
  }

  int _precioVenta(Map<String, dynamic> jugador) {
    final ovr = (jugador['ovr'] ?? 0) as num;
    return _precioVentaPorRareza[_rarezaPorOvr(ovr)] ?? 100;
  }

  
  void _alternarSeleccion(Map<String, dynamic> jugador) {
    setState(() {
      _cartaSeleccionada = (_cartaSeleccionada == jugador) ? null : jugador;
    });
  }

  // ---------- HELPERS DE FILTROS ----------

  String _regionDe(Map<String, dynamic> j) => '${j['region'] ?? ''}'.trim();
  String _equipoDe(Map<String, dynamic> j) => '${j['equipo'] ?? ''}'.trim();

  // Ícono de región (VCT), ej: "amer" -> assets/valorant/regiones/amer.png
  String _rutaRegion(String region) => 'assets/valorant/regiones/${region.toLowerCase()}.png';

  // Estandarte del equipo eSports: vive dentro de la carpeta de su región,
  // ej: equipo "sen" de la región "amer" -> assets/valorant/equipos/amer/sen.png
  String _rutaEquipo(String equipo) {
    final region = _equipoPorRegion[equipo];
    if (region == null || region.isEmpty) {
      return 'assets/valorant/equipos/${equipo.toLowerCase()}.png';
    }
    return 'assets/valorant/equipos/${region.toLowerCase()}/${equipo.toLowerCase()}.png';
  }

  void _alternarOrdenOvr() {
    setState(() {
      _ordenOvr = switch (_ordenOvr) {
        _OrdenOvr.ninguno => _OrdenOvr.descendente,
        _OrdenOvr.descendente => _OrdenOvr.ascendente,
        _OrdenOvr.ascendente => _OrdenOvr.ninguno,
      };
    });
  }

  void _alternarPanelRegion() {
    setState(() {
      _regionExpandida = !_regionExpandida;
      if (_regionExpandida) _equipoExpandido = false;
    });
  }

  void _alternarPanelEquipo() {
    setState(() {
      _equipoExpandido = !_equipoExpandido;
      if (_equipoExpandido) _regionExpandida = false;
    });
  }

  void _seleccionarRegion(String? region) {
    setState(() {
      _regionFiltro = (_regionFiltro == region) ? null : region;
      _regionExpandida = false;
      // Si el equipo elegido no pertenece a la nueva región, lo limpiamos
      // para no dejar un filtro imposible de cumplir.
      if (_regionFiltro != null &&
          _equipoFiltro != null &&
          _equipoPorRegion[_equipoFiltro] != _regionFiltro) {
        _equipoFiltro = null;
      }
    });
  }

  void _seleccionarEquipo(String? equipo) {
    setState(() {
      _equipoFiltro = (_equipoFiltro == equipo) ? null : equipo;
      _equipoExpandido = false;
    });
  }

  List<Map<String, dynamic>> _aplicarFiltros(List<Map<String, dynamic>> jugadores) {
    var resultado = jugadores.where((j) {
      if (_regionFiltro != null && _regionDe(j) != _regionFiltro) return false;
      if (_equipoFiltro != null && _equipoDe(j) != _equipoFiltro) return false;
      return true;
    }).toList();

    if (_ordenOvr != _OrdenOvr.ninguno) {
      resultado.sort((a, b) {
        final ovrA = (a['ovr'] ?? 0) as num;
        final ovrB = (b['ovr'] ?? 0) as num;
        return _ordenOvr == _OrdenOvr.ascendente ? ovrA.compareTo(ovrB) : ovrB.compareTo(ovrA);
      });
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text('Colección', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: const [BotonCerrarSesion()],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureJugadores,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error cargando cartas',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final jugadores = snapshot.data ?? [];

              // Las opciones de filtro salen de TODA la colección, no de la
              // lista ya filtrada, para que los circulitos no desaparezcan
              // al elegir un filtro.
              final regiones = jugadores
                  .map(_regionDe)
                  .where((r) => r.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
              final equipos = jugadores
                  .map(_equipoDe)
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              // A qué región pertenece cada equipo (para armar la ruta del
              // ícono y para poder mostrar solo los equipos de la región
              // elegida dentro del panel).
              _equipoPorRegion = {
                for (final j in jugadores)
                  if (_equipoDe(j).isNotEmpty) _equipoDe(j): _regionDe(j),
              };

              // Si hay una región elegida, el panel de equipos solo muestra
              // los equipos de esa región.
              final equiposDisponibles = _regionFiltro == null
                  ? equipos
                  : equipos.where((e) => _equipoPorRegion[e] == _regionFiltro).toList();

              final jugadoresFiltrados = _aplicarFiltros(jugadores);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          if (regiones.isNotEmpty)
                            _buildBotonPrincipal(
                              etiqueta: _regionFiltro?.toUpperCase() ?? 'REGIÓN',
                              expandido: _regionExpandida,
                              activo: _regionFiltro != null,
                              onTap: _alternarPanelRegion,
                              contenido: _regionFiltro == null
                                  ? const Icon(Icons.public, color: Colors.white54, size: 26)
                                  : Image.asset(
                                      _rutaRegion(_regionFiltro!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.public, color: Colors.white38, size: 24),
                                    ),
                            ),
                          if (regiones.isNotEmpty && equipos.isNotEmpty) const SizedBox(width: 16),
                          if (equipos.isNotEmpty)
                            _buildBotonPrincipal(
                              etiqueta: _equipoFiltro?.toUpperCase() ?? 'EQUIPO',
                              expandido: _equipoExpandido,
                              activo: _equipoFiltro != null,
                              onTap: _alternarPanelEquipo,
                              contenido: _equipoFiltro == null
                                  ? const Icon(Icons.shield_outlined, color: Colors.white54, size: 26)
                                  : Image.asset(
                                      _rutaEquipo(_equipoFiltro!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.shield_outlined, color: Colors.white38, size: 24),
                                    ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _regionExpandida
                          ? _buildPanelRegiones(regiones)
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _equipoExpandido
                          ? _buildPanelEquipos(equiposDisponibles)
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                    _buildBannerVenderRepetidas(jugadores),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Cartas únicas: ${jugadoresFiltrados.length} · Total: ${jugadoresFiltrados.fold<int>(0, (suma, j) => suma + (j['_cantidad'] as int? ?? 1))}',
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ),
                          _buildBotonOvr(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: jugadoresFiltrados.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay cartas con estos filtros.',
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            )
                          : GridView.builder(
                        itemCount: jugadoresFiltrados.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 15,
                          childAspectRatio: 626 / 794,
                        ),
                        itemBuilder: (context, index) {
                          final jugador = jugadoresFiltrados[index];
                          final cantidad = jugador['_cantidad'] as int? ?? 1;
                          return GestureDetector(
                            onTap: () => _alternarSeleccion(jugador),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CartaWidget(jugador: jugador),
                                if (cantidad > 1)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFF050914), width: 2),
                                      ),
                                      child: Text(
                                        'x$cantidad',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (_cartaSeleccionada != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _cartaSeleccionada = null),
                behavior: HitTestBehavior.opaque,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1,
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CartaWidget(
                                jugador: _cartaSeleccionada!,
                                width: MediaQuery.of(context).size.width * 0.88,
                              ),
                              if ((_cartaSeleccionada!['_cantidad'] as int? ?? 1) > 1)
                                Positioned(
                                  top: -6,
                                  right: MediaQuery.of(context).size.width * 0.06 - 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF050914), width: 2),
                                    ),
                                    child: Text(
                                      'x${_cartaSeleccionada!['_cantidad']}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _venderCarta(_cartaSeleccionada!),
                            icon: const Icon(Icons.sell, color: Colors.black),
                            label: Text(
                              (_cartaSeleccionada!['_cantidad'] as int? ?? 1) > 1
                                  ? 'Vender 1 copia por \$${_precioVenta(_cartaSeleccionada!)}'
                                  : 'Vender por \$${_precioVenta(_cartaSeleccionada!)}',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- UI: BOTÓN PRINCIPAL (Región / Equipo) ----------

  /// El circulito único que se ve siempre: muestra el ícono de lo elegido
  /// (o uno genérico si no hay filtro) y una flechita que indica si el
  /// panel de opciones está desplegado o no. Al tocarlo, se abre/cierra
  /// el panel con los circulitos de verdad.
  Widget _buildBotonPrincipal({
    required Widget contenido,
    required bool activo,
    required bool expandido,
    required String etiqueta,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activo ? _kDorado.withOpacity(0.16) : Colors.white10,
              border: Border.all(
                color: (activo || expandido) ? _kDorado : Colors.white24,
                width: (activo || expandido) ? 2.5 : 1.5,
              ),
              boxShadow: (activo || expandido)
                  ? [BoxShadow(color: _kDorado.withOpacity(0.4), blurRadius: 8)]
                  : null,
            ),
            child: ClipOval(child: Center(child: contenido)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  color: (activo || expandido) ? Colors.white : Colors.white54,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 15,
                color: (activo || expandido) ? Colors.white : Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanelRegiones(List<String> regiones) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 78,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          children: [
            _circuloFiltro(
              activo: _regionFiltro == null,
              etiqueta: 'TODAS',
              onTap: () => _seleccionarRegion(null),
              child: const Icon(Icons.public, color: Colors.white54, size: 24),
            ),
            for (final region in regiones) ...[
              const SizedBox(width: 10),
              _circuloFiltro(
                activo: _regionFiltro == region,
                etiqueta: region.toUpperCase(),
                onTap: () => _seleccionarRegion(region),
                child: Image.asset(
                  _rutaRegion(region),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.public, color: Colors.white38, size: 22),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPanelEquipos(List<String> equipos) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 78,
        child: equipos.isEmpty
            ? const Center(
                child: Text(
                  'Esta región no tiene equipos en tu colección.',
                  style: TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
              )
            : ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: [
                  _circuloFiltro(
                    activo: _equipoFiltro == null,
                    etiqueta: 'TODOS',
                    onTap: () => _seleccionarEquipo(null),
                    child: const Icon(Icons.shield_outlined, color: Colors.white54, size: 24),
                  ),
                  for (final equipo in equipos) ...[
                    const SizedBox(width: 10),
                    _circuloFiltro(
                      activo: _equipoFiltro == equipo,
                      etiqueta: equipo.toUpperCase(),
                      onTap: () => _seleccionarEquipo(equipo),
                      child: Image.asset(
                        _rutaEquipo(equipo),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.shield_outlined, color: Colors.white38, size: 22),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _circuloFiltro({
    required Widget child,
    required bool activo,
    required VoidCallback onTap,
    required String etiqueta,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activo ? _kDorado.withOpacity(0.16) : Colors.white10,
                border: Border.all(
                  color: activo ? _kDorado : Colors.white24,
                  width: activo ? 2.5 : 1.5,
                ),
                boxShadow: activo
                    ? [BoxShadow(color: _kDorado.withOpacity(0.4), blurRadius: 8)]
                    : null,
              ),
              child: ClipOval(child: Center(child: child)),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: activo ? Colors.white : Colors.white38,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI: BANNER "VENDER REPETIDAS" ----------
  // Solo aparece si hay al menos una carta con más de 1 copia. Usa la
  // colección completa (sin filtros) para que el banner y el total
  // vendido sean consistentes sin importar qué filtro esté activo.
  Widget _buildBannerVenderRepetidas(List<Map<String, dynamic>> jugadores) {
    final repetidas = _repetidasDe(jugadores);
    if (repetidas.isEmpty) return const SizedBox.shrink();

    final totalCopias = _totalCopiasRepetidas(repetidas);
    final totalGanado = _totalGananciaRepetidas(repetidas);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: GestureDetector(
        onTap: () => _confirmarVenderTodasLasRepetidas(repetidas),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _kDorado.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kDorado.withOpacity(0.55), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.sell, color: _kDorado, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tienes $totalCopias cartas repetidas · véndelas todas por \$$totalGanado',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: _kDorado),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonOvr() {
    final activo = _ordenOvr != _OrdenOvr.ninguno;
    final icono = switch (_ordenOvr) {
      _OrdenOvr.ascendente => Icons.arrow_upward,
      _OrdenOvr.descendente => Icons.arrow_downward,
      _OrdenOvr.ninguno => Icons.swap_vert,
    };

    return GestureDetector(
      onTap: _alternarOrdenOvr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? _kDorado : Colors.white10,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: activo ? _kDorado : Colors.white24, width: 1.5),
          boxShadow: activo
              ? [BoxShadow(color: _kDorado.withOpacity(0.4), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OVR',
              style: TextStyle(
                color: activo ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icono, size: 16, color: activo ? Colors.black : Colors.white70),
          ],
        ),
      ),
    );
  }
}