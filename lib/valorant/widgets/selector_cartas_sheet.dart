import 'package:flutter/material.dart';
import '../core/tema_juego.dart';
import 'carta_mini_widget.dart';

/// Bottom sheet para elegir una carta de entre 4 opciones durante el draft.
/// Antes duplicado en partida_rapida y partida_completa.
///
/// [quimicaPreview] es opcional: si se pasa, se muestran los puntitos de
/// química debajo de cada carta (partida_completa y torneo). Si es null
/// (p.ej. partida rápida, que ya no usa química) no se muestra nada.
class SelectorCartasSheet extends StatefulWidget {
  final List<Map<String, dynamic>> opciones;
  final void Function(Map<String, dynamic>) onElegir;
  final int Function(Map<String, dynamic>)? quimicaPreview;

  const SelectorCartasSheet({
    super.key,
    required this.opciones,
    required this.onElegir,
    this.quimicaPreview,
  });

  @override
  State<SelectorCartasSheet> createState() => _SelectorCartasSheetState();
}

class _SelectorCartasSheetState extends State<SelectorCartasSheet> {
  final List<bool> _visibles = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _visibles.length; i++) {
      Future.delayed(Duration(milliseconds: 160 * i), () {
        if (!mounted) return;
        setState(() => _visibles[i] = true);
      });
    }
  }

  Widget _puntitosPreview(int valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final activo = i < valor;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activo ? TemaJuego.dorado : Colors.transparent,
              border: Border.all(color: activo ? TemaJuego.dorado : Colors.white30, width: 1),
              boxShadow: activo ? [BoxShadow(color: TemaJuego.dorado.withOpacity(0.6), blurRadius: 4)] : null,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anchoDisponible = MediaQuery.of(context).size.width - 32;
    final anchoTarjeta = (anchoDisponible - 12) / 2;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 20, 16, 30 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: TemaJuego.fondoPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: TemaJuego.rojo, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: TemaJuego.rojo, size: 28),
          const SizedBox(height: 6),
          const Text(
            'ELIGE TU JUGADOR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca una carta para agregarla a tu equipo',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _opcionCarta(0, anchoTarjeta),
              _opcionCarta(1, anchoTarjeta),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _opcionCarta(2, anchoTarjeta),
              _opcionCarta(3, anchoTarjeta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcionCarta(int index, double ancho) {
    final carta = widget.opciones[index];
    final visible = _visibles[index];
    final preview = widget.quimicaPreview;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.18),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: visible ? () => widget.onElegir(carta) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TemaJuego.rojo.withOpacity(0.5), width: 1.5),
                ),
                child: SizedBox(
                  width: ancho,
                  child: AspectRatio(
                    aspectRatio: 626 / 794,
                    child: CartaMiniWidget(jugador: carta),
                  ),
                ),
              ),
              if (preview != null) ...[
                const SizedBox(height: 6),
                _puntitosPreview(preview(carta)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
