import 'package:flutter/material.dart';
import 'partida_rapida_screenv.dart';

// ---------- TEMA ARENA (rojo / negro), igual que Partida Rápida ----------
const Color _kFondo = Color(0xFF0A0A0A);
const Color _kFondoPanel = Color(0xFF1A0E0E);
const Color _kRojo = Color(0xFFE30425);
const Color _kDorado = Color(0xFFFFD700);

class ModoJuegoScreen extends StatelessWidget {
  const ModoJuegoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      appBar: AppBar(
        title: const Text(
          'MODOS DE JUEGO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: _kRojo),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
              const Text(
                'Elige tu modo de juego',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),

              _BotonModo(
                titulo: 'PARTIDA RÁPIDA',
                subtitulo: 'Al mejor de 5 rondas · resultado instantáneo (~1 min)',
                icono: Icons.bolt,
                activo: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PartidaRapidaScreen()),
                ),
              ),
              const SizedBox(height: 16),

              _BotonModo(
                titulo: 'TORNEO',
                subtitulo: 'Doble eliminación · Upper & Lower Bracket · Al mejor de 5 rondas',
                icono: Icons.emoji_events,
                activo: false,
              ),
              const SizedBox(height: 16),

              _BotonModo(
                titulo: 'PARTIDA COMPLETA',
                subtitulo: 'Simulación real a 13 rondas · eventos en vivo',
                icono: Icons.stadium,
                activo: false,
              ),
              const SizedBox(height: 16),

              _BotonModo(
                titulo: 'TORNEO LARGO',
                subtitulo: 'Doble eliminación · Upper & Lower Bracket · Con partidas de 13 rondas',
                icono: Icons.emoji_events,
                activo: false,
              ),
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BotonModo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool activo;
  final VoidCallback? onTap;

  const _BotonModo({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.activo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: activo ? 1.0 : 0.55,
      child: Material(
        color: _kFondoPanel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: activo ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: activo ? _kRojo : Colors.white24, width: 1.5),
              boxShadow: activo
                  ? [BoxShadow(color: _kRojo.withOpacity(0.25), blurRadius: 10)]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activo ? _kRojo.withOpacity(0.15) : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: activo ? _kRojo : Colors.white38, size: 26),
                ),
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
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitulo, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
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
      ),
    );
  }
}