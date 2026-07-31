import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coleccion_screenv.dart'; 
import 'tienda_screenv.dart';
import 'modo_juego_screenv.dart';
import '../providers/perfil_provider.dart';
import '../widgets/racha_dialog.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PerfilProvider>().cargar();
      if (!mounted) return;
      await mostrarRachaDiariaSiCorresponde(context);
    });
  }

  final List<Widget> _pantallas = [
    const TiendaScreen(),

    const ModoJuegoScreen(),

    const ColeccionScreen(), 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      body: _pantallas[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B222E),
        selectedItemColor: const Color.fromARGB(255, 255, 70, 85),
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            activeIcon: Icon(Icons.style),
            label: 'Sobres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_outlined),
            activeIcon: Icon(Icons.sports_esports),
            label: 'Jugar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark_outlined),
            activeIcon: Icon(Icons.collections_bookmark),
            label: 'Colección',
          ),
        ],
      ),
    );
  }
}