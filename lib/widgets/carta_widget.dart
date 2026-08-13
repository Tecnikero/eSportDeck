import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartaWidget extends StatelessWidget {
  final Map<String, dynamic> jugador;
  final double width;
  final bool mostrarStats;

  final double opacidadRegion;
  final double opacidadEquipo;
  final double opacidadPosicion;
  final double opacidadPais;
  final double opacidadResto;

  const CartaWidget({
    super.key,
    required this.jugador,
    this.width = 260,
    this.mostrarStats = true,
    this.opacidadRegion = 1.0,
    this.opacidadEquipo = 1.0,
    this.opacidadPosicion = 1.0,
    this.opacidadPais = 1.0,
    this.opacidadResto = 1.0,
  });

  static const double _aspectRatio = 626 / 794;

  static const double _lineaFraccion = 0.615;

  static const double _escalaFoto = 0.8;
  static const Alignment _alineacionFoto = Alignment.center;

  static const Map<String, String> _fondosPorRareza = {
    'icono': 'assets/valorant/cartas/carta_icono.png',
    'heroe': 'assets/valorant/cartas/carta_heroe.png',
  };

  static const String _fondoNormalOro = 'assets/valorant/cartas/carta_normal_oro.png';
  static const String _fondoNormalPlata = 'assets/valorant/cartas/carta_normal_plata.png';
  static const int _umbralOvrOro = 79;

  String get _rutaFondo {
    final rareza = '${jugador['rareza'] ?? 'normal'}'.toLowerCase().replaceAll(' ', '_');
    if (rareza == 'normal') {
      final ovr = (jugador['ovr'] ?? 0) as num;
      return ovr >= _umbralOvrOro ? _fondoNormalOro : _fondoNormalPlata;
    }
    return _fondosPorRareza[rareza] ?? _fondoNormalPlata;
  }

  String get _rutaBandera {
    final codigo = '${jugador['pais'] ?? ''}'.trim().toLowerCase();
    return 'assets/banderas/$codigo.png';
  }

  bool get _tieneBandera => '${jugador['pais'] ?? ''}'.trim().isNotEmpty;

  String get _rareza => '${jugador['rareza'] ?? 'normal'}'.toLowerCase().replaceAll(' ', '_');

  bool get _esIcono => _rareza == 'icono';

  bool get _esHeroe => _rareza == 'heroe';

  String get _rutaLogoEquipoEspecial {
    if (_esIcono) {
      return 'assets/valorant/equipos/logo/icono.png';
    }
    final region = '${jugador['region'] ?? 'default'}'.toLowerCase();
    return 'assets/valorant/equipos/logo/heroe_$region.png';
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
                    ),
                  ),

                  Positioned(
                    top: h * 0.092,
                    left: 0,
                    right: 0,
                    height: alturaFoto - (h * 0.035),
                    child: Opacity(
                      opacity: opacidadResto,
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
                                  stops: [0.5, 0.6, 1.0],
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
                  ),

                  Positioned(
                    top: h * 0.045,
                    right: w * 0.07,
                    width: w * 0.235,
                    height: w * 0.235,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: opacidadResto,
                            child: Text(
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
                          ),
                          Opacity(
                            opacity: opacidadPosicion,
                            child: Text(
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
                        Opacity(
                          opacity: opacidadEquipo,
                          child: (_esIcono || _esHeroe)
                              ? _logoWidget(
                                  imagePath: _rutaLogoEquipoEspecial,
                                  label: _esIcono ? 'Icono' : 'Héroe · ${jugador['region'] ?? 'Region'}',
                                  size: w * 0.12,
                                )
                              : _logoWidget(
                                  imagePath: 'assets/valorant/equipos/${(jugador['region'] ?? 'default').toString().toLowerCase()}/${(jugador['equipo'] ?? 'default').toString().toLowerCase()}.png',
                                  label: '${jugador['equipo'] ?? 'Equipo'}',
                                  size: w * 0.12,
                                ),
                        ),
                        if (!_esHeroe && !_esIcono) ...[
                          SizedBox(height: h * 0.012),
                          Opacity(
                            opacity: opacidadRegion,
                            child: _logoWidget(
                              imagePath: 'assets/valorant/regiones/${(jugador['region'] ?? 'default').toString().toLowerCase()}.png',
                              label: '${jugador['region'] ?? 'Region'}',
                              size: w * 0.12,
                            ),
                          ),
                        ],
                        if (_tieneBandera) ...[
                          SizedBox(height: h * 0.012),
                          Opacity(
                            opacity: opacidadPais,
                            child: _banderaWidget(size: w * 0.12),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Positioned(
                    top: alturaFoto - (w * 0.7),
                    left: w * 0.08,
                    right: w * 0.08,
                    child: Opacity(
                      opacity: opacidadResto,
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
                  ),

                  if (mostrarStats)
                    Positioned(
                      top: alturaFoto + (h * 0.02),
                      left: w * 0.18,
                      right: w * 0.18,
                      bottom: h * 0.07,
                      child: Opacity(
                        opacity: opacidadResto,
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