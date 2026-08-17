import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/perfil_provider.dart';

const Color _kDorado = Color(0xFFFFD700);
const Color _kFondoPanel = Color(0xFF11172A);
const List<int> _recompensasVisibles = [50, 60, 75, 90, 110, 140, 250];

Future<void> mostrarRachaDiariaSiCorresponde(BuildContext context) async {
  final perfil = context.read<PerfilProvider>();
  if (!perfil.recompensaDiariaDisponible) return;
  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _RachaDialog(),
  );
}

class _RachaDialog extends StatefulWidget {
  const _RachaDialog();

  @override
  State<_RachaDialog> createState() => _RachaDialogState();
}

class _RachaDialogState extends State<_RachaDialog> {
  bool _reclamando = false;
  int? _recompensaObtenida;

  Future<void> _reclamar() async {
    setState(() => _reclamando = true);
    final perfil = context.read<PerfilProvider>();
    final monto = await perfil.reclamarRecompensaDiaria();
    if (!mounted) return;
    setState(() {
      _reclamando = false;
      _recompensaObtenida = monto ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilProvider>();
    final diaObjetivo = _recompensaObtenida == null
        ? (perfil.rachaDias % 7) + 1
        : ((perfil.rachaDias - 1) % 7) + 1;

    return Dialog(
      backgroundColor: _kFondoPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: _kDorado, size: 40),
            const SizedBox(height: 8),
            Text(
              _recompensaObtenida == null ? '¡Recompensa diaria!' : '¡Recompensa reclamada!',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _recompensaObtenida == null
                  ? 'Vuelve cada día para acumular tu racha y ganar más monedas.'
                  : 'Vuelve mañana para no perder tu racha.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) {
                final dia = i + 1;
                final diaRef = diaObjetivo.clamp(1, 7);
                final activo = _recompensaObtenida == null && dia == diaRef;
                final completado =
                    _recompensaObtenida != null ? dia <= diaRef : dia < diaRef;
                final esJackpot = dia == 7;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activo
                              ? _kDorado
                              : (completado ? _kDorado.withOpacity(0.25) : Colors.white10),
                          border: Border.all(
                            color: esJackpot ? _kDorado : Colors.white24,
                            width: esJackpot ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          completado ? Icons.check : (esJackpot ? Icons.star : Icons.monetization_on),
                          size: 16,
                          color: activo || completado ? Colors.black : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_recompensasVisibles[dia - 1]}',
                        style: TextStyle(
                          color: activo ? _kDorado : Colors.white38,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            if (_recompensaObtenida != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: _kDorado, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '+$_recompensaObtenida monedas',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDorado,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _reclamando
                    ? null
                    : (_recompensaObtenida == null ? _reclamar : () => Navigator.of(context).pop()),
                child: _reclamando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        _recompensaObtenida == null ? 'RECLAMAR' : 'CONTINUAR',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}