import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/actualizacion_provider.dart';
import '../providers/perfil_provider.dart';
import '../../main/login_screen.dart';

const Color _kDorado = Color(0xFFFFD700);
const Color _kFondoPanel = Color(0xFF11172A);
const Color _kRojo = Color(0xFFE30425);

// ============================================================================
// ACTUALIZACIÓN
// ============================================================================
Future<void> mostrarActualizacionSiCorresponde(BuildContext context) async {
  final actualizacion = context.read<ActualizacionProvider>();
  await actualizacion.revisar();
  if (!context.mounted) return;
  if (!actualizacion.hayActualizacionDisponible) return;

  await showDialog(
    context: context,
    barrierDismissible: !actualizacion.actualizacionObligatoria,
    builder: (context) => const _ActualizacionDialog(),
  );
}

class _ActualizacionDialog extends StatefulWidget {
  const _ActualizacionDialog();

  @override
  State<_ActualizacionDialog> createState() => _ActualizacionDialogState();
}

class _ActualizacionDialogState extends State<_ActualizacionDialog> {
  Future<void> _actualizar() async {
    final actualizacion = context.read<ActualizacionProvider>();
    await actualizacion.descargarEInstalar();
  }

  void _ahoraNo() {
    context.read<ActualizacionProvider>().posponer();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final actualizacion = context.watch<ActualizacionProvider>();
    final obligatoria = actualizacion.actualizacionObligatoria;

    return PopScope(
      canPop: !obligatoria,
      child: Dialog(
        backgroundColor: _kFondoPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, color: _kDorado, size: 40),
              const SizedBox(height: 8),
              Text(
                obligatoria ? 'Actualización requerida' : '¡Nueva actualización!',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                actualizacion.notas ??
                    (obligatoria
                        ? 'Necesitas actualizar para seguir jugando.'
                        : 'Hay una nueva versión disponible.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              if (actualizacion.descargando) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: actualizacion.progresoDescarga > 0 ? actualizacion.progresoDescarga : null,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(_kDorado),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(actualizacion.progresoDescarga * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ] else ...[
                if (actualizacion.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(actualizacion.error!,
                        style: const TextStyle(color: _kRojo, fontSize: 12.5), textAlign: TextAlign.center),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kDorado,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _actualizar,
                    child: const Text('ACTUALIZAR AHORA',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                if (!obligatoria) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _ahoraNo,
                    child: const Text('Ahora no', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BotonActualizacionPendiente extends StatelessWidget {
  const BotonActualizacionPendiente({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActualizacionProvider>(
      builder: (context, actualizacion, _) {
        if (!actualizacion.actualizacionPendiente) return const SizedBox.shrink();
        return IconButton(
          tooltip: 'Actualización disponible',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.download, color: _kDorado),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: _kRojo, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          onPressed: () => mostrarActualizacionSiCorresponde(context),
        );
      },
    );
  }
}

// ============================================================================
// RACHA DIARIA
// ============================================================================
const List<int> _recompensasVisibles = [250, 400, 500, 700, 1000, 1500, 2000];

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

// ============================================================================
// CERRAR SESIÓN
// ============================================================================
Future<void> confirmarYCerrarSesion(BuildContext context) async {
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
            const Icon(Icons.logout, color: _kDorado, size: 36),
            const SizedBox(height: 10),
            const Text(
              '¿Cerrar sesión?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Podrás volver a iniciar sesión o registrar otra cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12.5),
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
                      backgroundColor: _kRojo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Cerrar sesión',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmar != true || !context.mounted) return;

  try {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.read<PerfilProvider>().limpiar();
  } catch (e) {
    debugPrint('ERROR AL CERRAR SESIÓN: $e');
  }

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
}

class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout, color: Colors.white70),
      onPressed: () => confirmarYCerrarSesion(context),
    );
  }
}