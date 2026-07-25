import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_nav_screenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (supabase.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavScreen()),
        );
      });
    }
  }

  Future<void> _iniciarSesion() async {
    setState(() => _cargando = true);
    try {
      final username = _usuarioController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      final emailFantasma = '$username@tecnistudio.app';

      await supabase.auth.signInWithPassword(
        email: emailFantasma,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavScreen()),
      );
      return;
    } catch (e) {
      debugPrint('ERROR AL INICIAR SESION: $e');
      if (!mounted) return;
      _mostrarError('Error: Revisa tus credenciales o crea una cuenta.');
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _crearCuenta() async {
    setState(() => _cargando = true);
    try {
      final username = _usuarioController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final emailFantasma = '$username@tecnistudio.app';

      final authResponse = await supabase.auth.signUp(
        email: emailFantasma,
        password: password,
      );

      final nuevoUsuario = authResponse.user;
      if (nuevoUsuario != null) {
        await supabase.from('profiles').insert({
          'id': nuevoUsuario.id,
          'username': username,
        });
      }

      if (!mounted) return;
      _mostrarMensaje('¡Cuenta creada con éxito! Ahora inicia sesión.');
    } catch (e) {
      debugPrint('ERROR AL CREAR CUENTA: $e');
      if (!mounted) return;
      _mostrarError('Error: $e');
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: const TextStyle(color: Colors.black)), backgroundColor: Colors.greenAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_esports, size: 80, color: Color(0xFFFFD700)),
              const SizedBox(height: 20),
              const Text(
                'TECNI DECK',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2.0),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _usuarioController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.person, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 40),

              if (_cargando)
                const CircularProgressIndicator(color: Color(0xFFFFD700))
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700), // Dorado
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _iniciarSesion,
                        child: const Text('INICIAR SESIÓN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: _crearCuenta,
                      child: const Text('¿No tienes cuenta? Regístrate', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}