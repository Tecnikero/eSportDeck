import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartaWidget extends StatelessWidget {
  final Map<String, dynamic> jugador;
  final double width;
  final bool mostrarStats;

  const CartaWidget({super.key, required this.jugador, this.width = 260, this.mostrarStats = true});

  static const double _aspectRatio = 626 / 794;

  static const double _lineaFraccion = 0.615;

  static const double _escalaFoto = 0.8;
  static const Alignment _alineacionFoto = Alignment.center;

  static const Map<String, String> _fondosPorRareza = {
    'Normal': 'assets/valorant/cartas/carta_normal.png',
    'champions': 'assets/valorant/cartas/carta_champions.png',
    'finals_champions': 'assets/valorant/cartas/carta_finals_champions.png',
  };

  String get _rutaFondo {
    final rareza = '${jugador['rareza'] ?? 'normal'}'.toLowerCase().replaceAll(' ', '_');
    return _fondosPorRareza[rareza] ?? 'assets/valorant/cartas/carta_normal.png';
  }

  @override
  Widget build(BuildContext context) {
    final stats = <MapEntry<String, dynamic>>[
      MapEntry('AIM', jugador['aim'] ?? 0),
      MapEntry('MEN', jugador['men'] ?? 0),
      MapEntry('IMP',  jugador['imp'] ?? 0),
      MapEntry('UTI', jugador['uti'] ?? 0),
      MapEntry('REA', jugador['rea'] ?? 0),
      MapEntry('CLU', jugador['clu'] ?? 0),
    ];

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth == double.infinity) {
                return const SizedBox.shrink();
              }

              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final alturaFoto = h * _lineaFraccion;

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _rutaFondo,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.red.withOpacity(0.5),
                          child: const Center(
                            child: Text(
                              "Error:\nRevisa pubspec.yaml\no la ruta de la imagen",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    top: h * 0.035,
                    left: 0,
                    right: 0,
                    height: alturaFoto - (h * 0.035),
                    child: ClipRect(
                      child: (jugador['imagen_url'] != null &&
                              '${jugador['imagen_url']}'.isNotEmpty)
                          ? ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.7, 1.0],
                                ).createShader(rect);
                              },
                              child: Transform.scale(
                                scale: _escalaFoto,
                                alignment: _alineacionFoto,
                                child: CachedNetworkImage(
                                  imageUrl: jugador['imagen_url'],
                                  fit: BoxFit.contain,
                                  alignment: _alineacionFoto,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Icon(
                                      Icons.person,
                                      size: w * 0.4,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.person,
                                size: w * 0.4,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                    ),
                  ),

                  Positioned(
                    top: h * 0.046,
                    right: w * 0.07,
                    width: w * 0.235,
                    height: w * 0.235,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${jugador['ovr'] ?? '--'}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: w * 0.1,
                              height: 1.0,
                              shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                            ),
                          ),
                          Text(
                            '${jugador['posicion'] ?? ''}'.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              fontSize: w * 0.04,
                              letterSpacing: 0.6,
                              shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: h * 0.26,
                    left: w * 0.14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _logoWidget(
                          imagePath: 'assets/valorant/equipos/${(jugador['region'] ?? 'default').toString().toLowerCase()}/${(jugador['equipo'] ?? 'default').toString().toLowerCase()}.png',
                          label: '${jugador['equipo'] ?? 'Equipo'}',
                          size: w * 0.12,
                        ),
                        SizedBox(height: h * 0.012),
                        _logoWidget(
                          imagePath: 'assets/valorant/regiones/${(jugador['region'] ?? 'default').toString().toLowerCase()}.png',
                          label: '${jugador['region'] ?? 'Region'}',
                          size: w * 0.12,
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: alturaFoto - (w * 0.08),
                    left: w * 0.08,
                    right: w * 0.08,
                    child: Text(
                      '${jugador['nombre'] ?? 'Nombre'}'.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.07,
                        letterSpacing: 0.5,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                    ),
                  ),

                  if (mostrarStats)
                    Positioned(
                      top: alturaFoto + (h * 0.03),
                      left: w * 0.18,
                      right: w * 0.18,
                      bottom: h * 0.07,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _columnaStat(stats[0].key, stats[0].value, w),
                              _columnaStat(stats[2].key, stats[2].value, w),
                              _columnaStat(stats[4].key, stats[4].value, w),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _columnaStat(stats[1].key, stats[1].value, w),
                              _columnaStat(stats[3].key, stats[3].value, w),
                              _columnaStat(stats[5].key, stats[5].value, w),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _logoWidget({
    required String imagePath,
    required String label,
    required double size,
  }) {
    return Tooltip(
      message: label,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.image_not_supported, 
            color: Colors.white54, 
            size: size * 0.5
          ),
        ),
      ),
    );
  }
  Widget _columnaStat(String label, dynamic value, double w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: w * 0.055,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.05,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}