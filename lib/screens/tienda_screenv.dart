import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sobre_detalle_screenv.dart';
import '../providers/perfil_provider.dart';
import '../widgets/racha_dialog.dart';


const List<Map<String, dynamic>> _tramosBasico = [
  {'min': 0, 'max': 80, 'peso': 70, 'efecto': 'ninguno'},
  {'min': 81, 'max': 88, 'peso': 24, 'efecto': 'plata'},
  {'min': 89, 'max': 91, 'peso': 5, 'efecto': 'violeta'},
  {'min': 92, 'max': 99, 'peso': 1, 'efecto': 'dorado'},
];


const List<Map<String, dynamic>> tiposSobre = [
  {
    'id': 'basico',
    'nombre': 'Sobre Básico',
    'precio': 1000,
    'cantidad_cartas': 2,
    'icono': Icons.style_outlined,
    'imagen': 'assets/valorant/sobres/sobres-beta.png',
    'color': Color(0xFF4A90D9),
    'rarezas': ['Normal', 'champions', 'finals_champions'],
    'tramos': _tramosBasico,
    'garantia': false,
    'descripcion': '2 cartas aleatorias del catálogo.\nComún 70% · Rara 24% · Épica 5% · Legendaria 1%.',
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PerfilProvider>().cargar();
      if (!mounted) return;
      await mostrarRachaDiariaSiCorresponde(context);
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
        child: Column(
          children: [
            _bannerRacha(),
            const SizedBox(height: 14),
            Expanded(
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
          ],
        ),
      ),
    );
  }

  Widget _bannerRacha() {
    return Consumer<PerfilProvider>(
      builder: (context, perfil, _) {
        return GestureDetector(
          onTap: perfil.recompensaDiariaDisponible
              ? () => mostrarRachaDiariaSiCorresponde(context)
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(perfil.recompensaDiariaDisponible ? 0.7 : 0.25),
                width: perfil.recompensaDiariaDisponible ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Color(0xFFFFD700), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    perfil.recompensaDiariaDisponible
                        ? '¡Tu recompensa diaria te espera!'
                        : 'Racha activa: ${perfil.rachaDias} día${perfil.rachaDias == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (perfil.recompensaDiariaDisponible)
                  const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
              ],
            ),
          ),
        );
      },
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
            const SizedBox(height: 6),
            _indicadorPity(sobre['id'] as String),
          ],
        ),
      ),
    );
  }

  // La legendaria ya no tiene pity (es 100% suerte), así que este
  // indicador ahora muestra el progreso hacia la épica garantizada.
  Widget _indicadorPity(String sobreId) {
    const epicaMax = 8;
    return Consumer<PerfilProvider>(
      builder: (context, perfil, _) {
        final pityEpica = perfil.obtenerPity(sobreId, 'violeta');
        final faltan = (epicaMax - pityEpica).clamp(0, epicaMax);
        return Text(
          faltan <= 2 ? '¡Épica a $faltan sobres!' : 'Épica en $faltan',
          style: TextStyle(
            color: faltan <= 2 ? const Color(0xFF9B59B6) : Colors.white38,
            fontSize: 10.5,
            fontWeight: faltan <= 2 ? FontWeight.bold : FontWeight.normal,
          ),
        );
      },
    );
  }
}