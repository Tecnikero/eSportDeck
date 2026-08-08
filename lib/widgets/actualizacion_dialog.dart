import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/actualizacion_provider.dart';

const Color _kDorado = Color(0xFFFFD700);
const Color _kFondoPanel = Color(0xFF11172A);
const Color _kRojo = Color(0xFFE30425);

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
