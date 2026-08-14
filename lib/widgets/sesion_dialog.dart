import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/perfil_provider.dart';
import '../screens/login_screen.dart';

const Color _kDorado = Color(0xFFFFD700);
const Color _kFondoPanel = Color(0xFF11172A);
const Color _kRojo = Color(0xFFE30425);

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
