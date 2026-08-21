import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coleccion_screenv.dart';
import 'galeria_cartas_screenv.dart';
import 'tienda_screenv.dart';
import 'modo_juego_screenv.dart';
import '../providers/perfil_provider.dart';
import '../widgets/sheets_partida.dart' hide BotonCerrarSesion;
import '../widgets/dialogos_cuenta.dart';
import '../widgets/panel_pincelado.dart';

const Color _kFondo = Color(0xFF0B0C10);
const Color _kFondoProfundo = Color(0xFF060708);
const Color _kPanel = Color(0xFF1C1E22);
const Color _kPlata = Color(0xFFC7CBD1);
const Color _kPlataOscuro = Color(0xFF3A3D42);
const Color _kDorado = Color(0xFFD9B65C);
const Color _kRojo = Color(0xFFB3222E);

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await mostrarActualizacionSiCorresponde(context);
      if (!mounted) return;

      await context.read<PerfilProvider>().cargar();
      if (!mounted) return;
      await mostrarRachaDiariaSiCorresponde(context);
    });
  }

  void _ir(Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      floatingActionButton: const BotonActualizacionPendiente(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kFondo, _kFondoProfundo],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: _kDorado,
            backgroundColor: _kPanel,
            onRefresh: () => context.read<PerfilProvider>().cargar(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _barraSuperior(),
                const SizedBox(height: 22),
                _bannerDraft(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _cardGrande(
                        titulo: 'SOBRES',
                        subtitulo: 'Abre tu tienda                      ',
                        icono: Icons.style,
                        onTap: () => _ir(const TiendaScreen()),
                        badge: _badgeSobresPendientes(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _cardGrande(
                        titulo: 'JUGAR',
                        subtitulo: 'Modos de juego                      ',
                        icono: Icons.sports_esports,
                        onTap: () => _ir(const ModoJuegoScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _cardAncha(
                  titulo: 'COLECCIÓN',
                  subtitulo: 'Revisa todas tus cartas',
                  icono: Icons.collections_bookmark,
                  onTap: () => _ir(const ColeccionScreen()),
                ),
                const SizedBox(height: 14),
                _cardAncha(
                  titulo: 'GALERÍA',
                  subtitulo: 'Descubre todas las cartas que existen',
                  icono: Icons.grid_view_rounded,
                  onTap: () => _ir(const GaleriaCartasScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _barraSuperior() {
    return Consumer<PerfilProvider>(
      builder: (context, perfil, _) {
        final dinero = perfil.dinero;
        return Row(
          children: [
            _chipMetalico(
              icono: Icons.monetization_on,
              valor: dinero == null ? '...' : '$dinero',
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: perfil.recompensaDiariaDisponible
                  ? () => mostrarRachaDiariaSiCorresponde(context)
                  : null,
              child: _chipMetalico(
                icono: Icons.local_fire_department,
                valor: '${perfil.rachaDias} día${perfil.rachaDias == 1 ? '' : 's'}',
                acento: perfil.recompensaDiariaDisponible ? _kRojo : _kDorado,
              ),
            ),
            const Spacer(),
            const BotonCerrarSesion(),
          ],
        );
      },
    );
  }

  Widget _chipMetalico({
    required IconData icono,
    required String valor,
    Color acento = _kDorado,
  }) {
    return PanelPincelado(
      colorBase: const Color(0xFF202226),
      colorAcento: acento,
      corte: 9,
      grosorBorde: 1.6,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: acento, size: 16),
          const SizedBox(width: 6),
          Text(
            valor,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _bannerDraft() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23262B), Color(0xFF141518)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 2.0),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valorant Champions Draft 2026',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Abre sobres, arma tu equipo y compite',
            style: TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget? _badgeSobresPendientes() {
    return Consumer<PerfilProvider>(
      builder: (context, perfil, _) {
        final total = perfil.totalSobresPendientes;
        if (total <= 0) return const SizedBox.shrink();
        return Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _kRojo,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _kFondo, width: 2.5),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tarjetaMetalica({
    required Widget child,
    required VoidCallback onTap,
    double borderRadius = 22,
  }) {
    return PanelPincelado(
      onTap: onTap,
      colorBase: _kPanel,
      colorAcento: _kPlata,
      corte: 20,
      grosorBorde: 2.4,
      child: child,
    );
  }

  Widget _iconoMetalico(IconData icono, {double size = 28}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kPlataOscuro.withOpacity(0.5),
        border: Border.all(color: _kPlata.withOpacity(0.3), width: 2.0),
      ),
      child: Icon(icono, color: _kPlata, size: size),
    );
  }

  Widget _cardGrande({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return AspectRatio(
      aspectRatio: 0.95,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _tarjetaMetalica(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconoMetalico(icono),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (badge != null) badge,
        ],
      ),
    );
  }

  Widget _cardAncha({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return _tarjetaMetalica(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _iconoMetalico(icono, size: 30),
            const SizedBox(width: 19),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}