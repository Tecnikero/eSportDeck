import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int _compararVersiones(String a, String b) {
  final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

class ActualizacionProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _versionInstalada;
  String? _versionServidor;
  String? _versionMinima;
  String? _urlApk;
  String? _notas;

  bool _revisando = false;
  bool _descargando = false;
  double _progresoDescarga = 0;
  String? _error;
  String? _rutaApkDescargado;

  bool get hayActualizacionDisponible =>
      _versionServidor != null &&
      _versionInstalada != null &&
      _compararVersiones(_versionServidor!, _versionInstalada!) > 0;

  bool get actualizacionObligatoria =>
      _versionMinima != null &&
      _versionInstalada != null &&
      _compararVersiones(_versionMinima!, _versionInstalada!) > 0;

  bool _pospuesta = false;
  bool get actualizacionPendiente => _pospuesta && hayActualizacionDisponible;

  bool get descargando => _descargando;
  double get progresoDescarga => _progresoDescarga;
  String? get notas => _notas;
  String? get error => _error;
  String? get versionServidor => _versionServidor;

  Future<void> revisar() async {
    if (_revisando) return;
    _revisando = true;
    try {
      final paquete = await PackageInfo.fromPlatform();
      _versionInstalada = paquete.version;

      final fila = await _supabase
          .from('app_config')
          .select('version_actual, version_minima, url_apk, notas')
          .eq('clave', 'app')
          .maybeSingle();

      if (fila == null) return;

      _versionServidor = fila['version_actual'] as String?;
      _versionMinima = fila['version_minima'] as String?;
      _urlApk = fila['url_apk'] as String?;
      _notas = fila['notas'] as String?;
    } catch (e) {
      debugPrint('ERROR AL REVISAR ACTUALIZACIÓN: $e');
    } finally {
      _revisando = false;
      notifyListeners();
    }
  }

  void posponer() {
    _pospuesta = true;
    notifyListeners();
  }

  Future<bool> descargarEInstalar() async {
    final url = _urlApk;
    if (url == null) return false;

    _descargando = true;
    _progresoDescarga = 0;
    _error = null;
    notifyListeners();

    try {
      final permiso = await Permission.requestInstallPackages.request();
      if (!permiso.isGranted) {
        _error = 'Necesitas dar permiso para instalar la actualización.';
        _descargando = false;
        notifyListeners();
        return false;
      }

      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final ruta = '${dir.path}/tecni_deck_actualizacion.apk';

      final dio = Dio();
      await dio.download(
        url,
        ruta,
        onReceiveProgress: (recibido, total) {
          if (total <= 0) return;
          _progresoDescarga = recibido / total;
          notifyListeners();
        },
      );

      _rutaApkDescargado = ruta;
      _descargando = false;
      _pospuesta = false;
      notifyListeners();

      await OpenFilex.open(ruta);
      return true;
    } catch (e) {
      debugPrint('ERROR AL DESCARGAR ACTUALIZACIÓN: $e');
      _error = 'No se pudo descargar la actualización.';
      _descargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> instalarDeNuevoSiYaEstaDescargado() async {
    final ruta = _rutaApkDescargado;
    if (ruta == null || !File(ruta).existsSync()) {
      await descargarEInstalar();
      return;
    }
    await OpenFilex.open(ruta);
  }
}
