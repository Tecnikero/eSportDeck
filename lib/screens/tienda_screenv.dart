import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sobre_detalle_screenv.dart';
import '../providers/perfil_provider.dart';


const List<Map<String, dynamic>> tiposSobre = [
  {
    'id': 'basico',
    'nombre': 'Sobre Básico',
    'precio': 100,
    'icono': Icons.style_outlined,
    'imagen': 'assets/valorant/sobres/sobres-beta.png',
    'color': Color(0xFF4A90D9),
    'rarezas': ['Normal'],
    'descripcion': '2 cartas aleatorias del catálogo.',
  },
  {
    'id': 'champions',
    'nombre': 'Sobre Champions',
    'precio': 400,
    'icono': Icons.auto_awesome,
    'imagen': 'assets/valorant/sobres/sobres-beta.png',
    'color': Color(0xFF9B59B6),
    'rarezas': ['Normal', 'Champions'],
    'descripcion': 'Mayor probabilidad de cartas edición Champions.',
  },
  {
    'id': 'finals_champions',
    'nombre': 'Sobre Finals Champions',
    'precio': 900,
    'icono': Icons.workspace_premium,
    'imagen': 'assets/valorant/sobres/sobres-beta.png',
    'color': Color(0xFFFFD700),
    'rarezas': ['Champions', 'Finals_Champions'],
    'descripcion': 'Cartas garantizadas de las ediciones más altas.',
  },
];

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerfilProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        title: const Text('Tienda',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<PerfilProvider>(
            builder: (context, perfil, _) {
              final dinero = perfil.dinero;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      dinero == null ? '...' : '$dinero',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: tiposSobre.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) => _tarjetaSobre(tiposSobre[index]),
        ),
      ),
    );
  }

  Widget _tarjetaSobre(Map<String, dynamic> sobre) {
    final color = sobre['color'] as Color;
    return GestureDetector(
      onTap: () async {
        final resultado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => SobreDetalleScreen(sobre: sobre)),
        );
        if (resultado == true && context.mounted) {
          context.read<PerfilProvider>().cargar();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.35), const Color(0xFF11172A)],
          ),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 90,
              child: Image.asset(
                sobre['imagen'] as String,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(sobre['icono'] as IconData, size: 64, color: color),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              sobre['nombre'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 15),
                const SizedBox(width: 3),
                Text('${sobre['precio']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}