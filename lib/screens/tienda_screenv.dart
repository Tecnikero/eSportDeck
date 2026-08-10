import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sobre_detalle_screenv.dart';
import '../providers/perfil_provider.dart';
import '../widgets/racha_dialog.dart';

const Color _kFondo = Color(0xFF0B0C10);
const Color _kPanel = Color(0xFF1C1E22);
const Color _kPlata = Color(0xFFC7CBD1);
const Color _kPlataOscuro = Color(0xFF3A3D42);
const Color _kDorado = Color(0xFFD9B65C);

const List<Map<String, dynamic>> _tramosBasico = [
  {'min': 79, 'max': 82, 'peso': 65, 'efecto': 'ninguno'},
  {'min': 83, 'max': 89, 'peso': 31, 'efecto': 'plata'},
  {'min': 90, 'max': 91, 'peso': 4, 'efecto': 'violeta'},
  {'min': 92, 'max': 99, 'peso': 1, 'efecto': 'dorado'},
];
const List<Map<String, dynamic>> _tramosPlata = [
  {'min': 0, 'max': 79, 'peso': 100, 'efecto': 'ninguno'},
  {'min': 80, 'max': 81, 'peso': 0, 'efecto': 'plata'},
  {'min': 82, 'max': 88, 'peso': 0, 'efecto': 'violeta'},
  {'min': 89, 'max': 99, 'peso': 0, 'efecto': 'dorado'},
];

const List<Map<String, dynamic>> tiposSobre = [
  {
    'id': 'basico',
    'nombre': 'Sobre Básico',
    'precio': 1000,
    'cantidad_cartas': 2,
    'icono': Icons.style_outlined,
    'imagen': 'assets/valorant/sobres/sobre_normal.png',
    'color': Color(0xFF4A90D9),
    'rarezas': ['Normal'],
    'tramos': _tramosBasico,
    'garantia': false,
    'descripcion': '2 cartas aleatorias de oro del catálogo.',
  },
  {
    'id': 'plata',
    'nombre': 'Sobre Plata',
    'precio': 500,
    'cantidad_cartas': 2,
    'icono': Icons.style_outlined,
    'imagen': 'assets/valorant/sobres/sobre_plata.png',
    'color': Color(0xFF4A90D9),
    'rarezas': ['Normal'],
    'tramos': _tramosPlata,
    'garantia': false,
    'descripcion': '2 cartas aleatorias de plata del catálogo.',
  },
];

const List<Map<String, dynamic>> _tramosPremium = [
  {'min': 0, 'max': 84, 'peso': 40, 'efecto': 'ninguno'},
  {'min': 85, 'max': 88, 'peso': 35, 'efecto': 'plata'},
  {'min': 89, 'max': 91, 'peso': 18, 'efecto': 'violeta'},
  {'min': 92, 'max': 99, 'peso': 7, 'efecto': 'dorado'},
];

final Map<String, Map<String, dynamic>> _todosLosSobres = {
  for (final s in tiposSobre) s['id'] as String: s,
  ...sobresGanables,
};

const Map<String, Map<String, dynamic>> sobresGanables = {
  'premium_torneo': {
    'id': 'premium_torneo',
    'nombre': 'Sobre Premium',
    'precio': 0,
    'cantidad_cartas': 3,
    'icono': Icons.emoji_events,
    'imagen': 'assets/valorant/sobres/sobre_torneo.png',
    'color': Color(0xFF4A90D9),
    'rarezas': ['Normal', 'champions', 'finals_champions'],
    'tramos': _tramosPremium,
    'garantia': true,
    'descripcion':
        '3 cartas con mucha mejor probabilidad de rareza alta.\nSe gana siendo campeón del Torneo.',
  },
};

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

enum _PestanaTienda { sobres, misSobres }

class _TiendaScreenState extends State<TiendaScreen> {
  _PestanaTienda _pestana = _PestanaTienda.sobres;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PerfilProvider>().cargar();
      if (!mounted) return;
      await mostrarRachaDiariaSiCorresponde(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text('Tienda',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<PerfilProvider>(
            builder: (context, perfil, _) {
              final dinero = perfil.dinero;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _chipMetalico(
                  icono: Icons.monetization_on,
                  valor: dinero == null ? '...' : '$dinero',
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kFondo, Color(0xFF060708)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _barraPestanas(),
              const SizedBox(height: 16),
              Expanded(
                child: _pestana == _PestanaTienda.sobres
                    ? _vistaSobres()
                    : _vistaMisSobres(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraPestanas() {
    return Row(
      children: [
        _tabItem('SOBRES', _PestanaTienda.sobres),
        const SizedBox(width: 22),
        _tabItem('MIS SOBRES', _PestanaTienda.misSobres),
      ],
    );
  }

  Widget _tabItem(String texto, _PestanaTienda valor) {
    final activo = _pestana == valor;
    return GestureDetector(
      onTap: () => setState(() => _pestana = valor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: TextStyle(
              color: activo ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2.5,
            width: activo ? (texto.length * 8.0 + 4) : 0,
            decoration: BoxDecoration(
              color: _kDorado,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaSobres() {
    return ListView(
      children: [
        _bannerRacha(),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'DISPONIBLES HOY',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...tiposSobre.map(
          (sobre) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _tarjetaSobre(sobre),
          ),
        ),
      ],
    );
  }

  Widget _vistaMisSobres() {
    return Consumer<PerfilProvider>(
      builder: (context, perfil, _) {
        final pendientes = perfil.sobresPendientes;

        if (pendientes.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'No tienes sobres pendientes.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gánalos jugando torneos o cómpralos en la tienda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return ListView(
          children: pendientes.entries.map((entrada) {
            final definicion = _todosLosSobres[entrada.key];
            if (definicion == null) return const SizedBox.shrink();
            final cantidad = entrada.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _tarjetaSobrePendiente(definicion, cantidad),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _tarjetaSobrePendiente(Map<String, dynamic> definicion, int cantidad) {
    return _panelMetalico(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${definicion['nombre']}  x$cantidad',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    definicion['descripcion'] as String,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  _botonMetalico('ABRIR', () => _abrirSobrePendiente(definicion)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              height: 110,
              child: Image.asset(
                definicion['imagen'] as String,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _iconoMetalico(definicion['icono'] as IconData, size: 34),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipMetalico({required IconData icono, required String valor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2D32), Color(0xFF17181B)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: _kDorado, size: 16),
          const SizedBox(width: 6),
          Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _panelMetalico({
    required Widget child,
    VoidCallback? onTap,
    double borderRadius = 16,
    Color bordeAcento = Colors.white,
    double bordeOpacidad = 0.10,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.08), _kPanel.withOpacity(0.55)],
            ),
            border: Border.all(color: bordeAcento.withOpacity(bordeOpacidad), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onTap,
              splashColor: _kPlata.withOpacity(0.08),
              highlightColor: Colors.white.withOpacity(0.03),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerRacha() {
    return Consumer<PerfilProvider>(
      builder: (context, perfil, _) {
        return _panelMetalico(
          borderRadius: 14,
          bordeAcento: perfil.recompensaDiariaDisponible ? _kDorado : Colors.white,
          bordeOpacidad: perfil.recompensaDiariaDisponible ? 0.55 : 0.10,
          onTap: perfil.recompensaDiariaDisponible
              ? () => mostrarRachaDiariaSiCorresponde(context)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: _kDorado, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    perfil.recompensaDiariaDisponible
                        ? '¡Tu recompensa diaria te espera!'
                        : 'Racha activa: ${perfil.rachaDias} día${perfil.rachaDias == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (perfil.recompensaDiariaDisponible)
                  const Icon(Icons.chevron_right, color: _kDorado),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirSobrePendiente(Map<String, dynamic> definicion) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => SobreDetalleScreen(sobre: definicion, esPendiente: true)),
    );
    if (resultado == true && context.mounted) {
      final perfil = context.read<PerfilProvider>();
      await perfil.consumirSobrePendiente(definicion['id'] as String);
      await perfil.cargar();
    }
  }

  Widget _iconoMetalico(IconData icono, {double size = 26}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPlata, _kPlataOscuro],
        ),
      ),
      child: Icon(icono, color: const Color(0xFF17181B), size: size),
    );
  }

  Widget _botonMetalico(String texto, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: [_kPlata, _kPlataOscuro]),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(texto,
              style: const TextStyle(color: Color(0xFF17181B), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _tarjetaSobre(Map<String, dynamic> sobre) {
    return _panelMetalico(
      borderRadius: 18,
      onTap: () async {
        final resultado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => SobreDetalleScreen(sobre: sobre)),
        );
        if (resultado == true && context.mounted) {
          context.read<PerfilProvider>().cargar();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sobre['nombre'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sobre['descripcion'],
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  //_indicadorPity(sobre['id'] as String),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(colors: [_kPlata, _kPlataOscuro]),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFF17181B), size: 15),
                        const SizedBox(width: 5),
                        Text('${sobre['precio']}',
                            style: const TextStyle(
                                color: Color(0xFF17181B), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              height: 110,
              child: Image.asset(
                sobre['imagen'] as String,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _iconoMetalico(sobre['icono'] as IconData, size: 34),
              ),
            ),
          ],
        ),
      ),
    );
  }

}