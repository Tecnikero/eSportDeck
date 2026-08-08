import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartaMiniWidget extends StatelessWidget {
  final Map<String, dynamic> jugador;
  final double width;

  const CartaMiniWidget({
    super.key,
    required this.jugador,
    this.width = 260,
  });

  static const double _aspectRatio = 400 / 450;

  static const double _fotoTop = 0.124;
  static const double _fotoAltura = 0.62;
  static const double _escalaFoto = 0.85;
  static const Alignment _alineacionFoto = Alignment.center;
  static const double _nombreTop = 0.1;

  static const Map<String, String> _fondosPorRareza = {
    'champions': 'assets/valorant/cartas/carta_champions_mini.png',
    'finals_champions': 'assets/valorant/cartas/carta_finals_champions_mini.png',
  };

  static const String _fondoNormalOroMini = 'assets/valorant/cartas/carta_normal_oro_mini.png';
  static const String _fondoNormalPlataMini = 'assets/valorant/cartas/carta_normal_plata_mini.png';
  static const int _umbralOvrOro = 79;

  String get _rutaBandera {
    final codigo = '${jugador['pais'] ?? ''}'.trim().toLowerCase();
    return 'assets/banderas/$codigo.png';
  }

  bool get _tieneBandera => '${jugador['pais'] ?? ''}'.trim().isNotEmpty;

  String get _rutaFondo {
    final rareza = '${jugador['rareza'] ?? 'normal'}'.toLowerCase().replaceAll(' ', '_');
    if (rareza == 'normal') {
      final ovr = (jugador['ovr'] ?? 0) as num;
      return ovr >= _umbralOvrOro ? _fondoNormalOroMini : _fondoNormalPlataMini;
    }
    return _fondosPorRareza[rareza] ?? _fondoNormalPlataMini;
  }

  @override
  Widget build(BuildContext context) {
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

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _rutaFondo,
                      fit: BoxFit.fill,
                    ),
                  ),

                  Positioned(
                    top: h * _fotoTop,
                    left: 0,
                    right: 0,
                    height: h * _fotoAltura,
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
                                  stops: [0.0, 0.75, 1.0],
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
                    top: h * 0.08,
                    right: w * 0.65,
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
                              fontSize: w * 0.12,
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
                    top: h * 0.76,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _logoWidget(
                          imagePath: 'assets/valorant/equipos/${(jugador['region'] ?? 'default').toString().toLowerCase()}/${(jugador['equipo'] ?? 'default').toString().toLowerCase()}.png',
                          label: '${jugador['equipo'] ?? 'Equipo'}',
                          size: w * 0.15,
                        ),
                        SizedBox(width: w * 0.09),
                        _logoWidget(
                          imagePath: 'assets/valorant/regiones/${(jugador['region'] ?? 'default').toString().toLowerCase()}.png',
                          label: '${jugador['region'] ?? 'Region'}',
                          size: w * 0.15,
                        ),
                        if (_tieneBandera) ...[
                          SizedBox(width: w * 0.09),
                          _banderaWidget(size: w * 0.15),
                        ],
                      ],
                    ),
                  ),

                  Positioned(
                    top: h * _nombreTop,
                    left: w * 0.2,
                    right: w * 0,
                    child: Text(
                      '${jugador['nombre'] ?? 'Nombre'}'.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.065,
                        letterSpacing: 0.5,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
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

  Widget _banderaWidget({required double size}) {
    return Tooltip(
      message: '${jugador['pais'] ?? ''}'.toUpperCase(),
      child: Container(
        width: size,
        height: size * 0.7,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
        ),
        child: Image.asset(
          _rutaBandera,
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
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}