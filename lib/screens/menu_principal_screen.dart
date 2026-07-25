import 'package:flutter/material.dart';
import 'login_screen.dart';

class MenuPrincipalScreen extends StatelessWidget {
  const MenuPrincipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> juegos = [
      {'nombre': 'Valorant', 'activo': true, 'logoPath': 'assets/logos/valorant.png'},
      {'nombre': 'CS2', 'activo': false, 'logoPath': 'assets/logos/cs2.png'},
      {'nombre': 'Rocket League', 'activo': false, 'logoPath': 'assets/logos/rl.png'},
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 56, 59),
      appBar: AppBar(
        title: const Text('eSports Deck', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selecciona tu especialidad:", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: juegos.length,
                itemBuilder: (context, index) {
                  final juego = juegos[index];
                  return _tarjetaJuego(context, juego);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaJuego(BuildContext context, Map<String, dynamic> juego) {
    return Opacity(
      opacity: juego['activo'] ? 1.0 : 0.5,
      child: Card(
        color: const Color.fromARGB(255, 57, 60, 63),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: juego['activo'] 
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                juego['logoPath'], 
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, color: Colors.grey, size: 50);
                },
              ),
              const SizedBox(height: 15),
              Text(juego['nombre'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (!juego['activo']) 
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text("Próximamente", style: TextStyle(color: Color.fromARGB(255, 105, 105, 105), fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}