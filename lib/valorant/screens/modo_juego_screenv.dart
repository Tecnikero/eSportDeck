import 'dart:ui';
import 'package:flutter/material.dart';
import 'partida_rapida_screenv.dart';
import 'partida_completa_screenv.dart';
import 'modo_torneo_screenv.dart';

const Color _kFondo = Color(0xFF0B0C10);
const Color _kFondoProfundo = Color(0xFF060708);
const Color _kPanel = Color(0xFF1C1E22);
const Color _kPlata = Color(0xFFC7CBD1);
const Color _kPlataOscuro = Color(0xFF3A3D42);
const Color _kDorado = Color(0xFFD9B65C);

class ModoJuegoScreen extends StatelessWidget {
  const ModoJuegoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text(
          'Modos de juego',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kFondo, _kFondoProfundo],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ELIGE TU MODO DE JUEGO',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _tarjetaModo(
                context: context,
                titulo: 'PARTIDA RÁPIDA',
                subtitulo: 'Al mejor de 5 rondas · resultado instantáneo (~1 min)',
                icono: Icons.bolt,
                activo: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PartidaRapidaScreen()),
                ),
              ),
              const SizedBox(height: 14),

              _tarjetaModo(
                context: context,
                titulo: 'TORNEO',
                subtitulo: 'Doble eliminación · Upper & Lower Bracket · Al mejor de 5 rondas',
                icono: Icons.emoji_events,
                activo: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TorneoDraftScreen()),
                ),
              ),
              const SizedBox(height: 14),

              _tarjetaModo(
                context: context,
                titulo: 'PARTIDA COMPLETA',
                subtitulo: 'Simulación real a 13 rondas · eventos en vivo',
                icono: Icons.stadium,
                activo: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PartidaCompletaScreen()),
                ),
              ),
              const SizedBox(height: 14),

              _tarjetaModo(
                context: context,
                titulo: 'TORNEO LARGO',
                subtitulo: 'Doble eliminación · Upper & Lower Bracket · Con partidas de 13 rondas',
                icono: Icons.emoji_events,
                activo: false,
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelMetalico({
    required Widget child,
    VoidCallback? onTap,
    double borderRadius = 18,
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

  Widget _iconoMetalico(IconData icono, {double size = 26, bool activo = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: activo ? [_kPlata, _kPlataOscuro] : [Colors.white24, Colors.white10],
        ),
      ),
      child: Icon(icono, color: activo ? const Color(0xFF17181B) : Colors.white38, size: size),
    );
  }

  Widget _tarjetaModo({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required bool activo,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: activo ? 1.0 : 0.55,
      child: _panelMetalico(
        onTap: activo ? onTap : null,
        bordeAcento: activo ? _kPlata : Colors.white,
        bordeOpacidad: activo ? 0.18 : 0.10,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _iconoMetalico(icono, size: 26, activo: activo),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: activo ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    if (!activo)
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Próximamente',
                          style: TextStyle(color: _kDorado, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              if (activo) const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}