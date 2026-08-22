import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<int> _recompensasPorDiaDeRacha = [100, 150, 300, 500, 700, 1500, 2500];

const Duration _ttlCache = Duration(minutes: 3);

const String _kPrefsPrefix = 'perfil_cache_';

const int _horaReinicioDiario = 12;

class PerfilProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  int? _dinero;
  bool _cargando = false;
  String? _error;

  int _rachaDias = 0;
  DateTime? _ultimaRecompensa;
  bool _recompensaDiariaDisponible = false;

  Map<String, Map<String, int>> _pity = {};

  Map<String, int> _sobresPendientes = {};

  Map<String, List<DateTime>> _comprasPorSobre = {};

  DateTime? _ultimaCargaExitosa;
  bool _cacheLocalCargado = false;
  String? _userIdCacheado;

  int? get dinero => _dinero;
  bool get cargando => _cargando;
  String? get error => _error;
  int get rachaDias => _rachaDias;
  bool get recompensaDiariaDisponible => _recompensaDiariaDisponible;
  int get proximaRecompensa {
    final diaObjetivo = (_rachaDias % 7);
    return _recompensasPorDiaDeRacha[diaObjetivo];
  }

  Map<String, int> get sobresPendientes => Map.unmodifiable(_sobresPendientes);
  int get totalSobresPendientes => _sobresPendientes.values.fold(0, (s, c) => s + c);
  int cantidadSobrePendiente(String sobreId) => _sobresPendientes[sobreId] ?? 0;

  DateTime _inicioCicloActual([DateTime? ahora]) {
    final now = ahora ?? DateTime.now();
    final hoyReinicio = DateTime(now.year, now.month, now.day, _horaReinicioDiario);
    return now.isBefore(hoyReinicio) ? hoyReinicio.subtract(const Duration(days: 1)) : hoyReinicio;
  }

  DateTime _finCicloActual([DateTime? ahora]) =>
      _inicioCicloActual(ahora).add(const Duration(days: 1));

  List<DateTime> _comprasVigentes(String sobreId) {
    final lista = _comprasPorSobre[sobreId];
    if (lista == null || lista.isEmpty) return const [];
    final inicio = _inicioCicloActual();
    final vigentes = lista.where((t) => !t.isBefore(inicio)).toList()..sort();
    if (vigentes.length != lista.length) {
      _comprasPorSobre[sobreId] = vigentes;
    }
    return vigentes;
  }

  int comprasRecientes(String sobreId) => _comprasVigentes(sobreId).length;

  DateTime? proximaDisponible(String sobreId) {
    if (_comprasVigentes(sobreId).isEmpty) return null;
    return _finCicloActual();
  }

  bool puedeComprar(String sobreId, int? limiteDiario) {
    if (limiteDiario == null) return true;
    return comprasRecientes(sobreId) < limiteDiario;
  }

  Duration? tiempoRestante(String sobreId) {
    final proxima = proximaDisponible(sobreId);
    if (proxima == null) return null;
    final restante = proxima.difference(DateTime.now());
    return restante.isNegative ? null : restante;
  }

  bool get _cacheVigente =>
      _ultimaCargaExitosa != null &&
      DateTime.now().difference(_ultimaCargaExitosa!) < _ttlCache;

  Future<void> cargar({bool forzar = false}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (!_cacheLocalCargado || _userIdCacheado != userId) {
      await _cargarDesdeDisco(userId);
      _cacheLocalCargado = true;
      _userIdCacheado = userId;
      notifyListeners();
    }

    if (!forzar && _cacheVigente) return;

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final fila = await _supabase
          .from('profiles')
          .select('dinero, racha_dias, ultima_recompensa, pity')
          .eq('id', userId)
          .single();

      _dinero = (fila['dinero'] ?? 0) as int;
      _rachaDias = (fila['racha_dias'] ?? 0) as int;

      final ultimaCruda = fila['ultima_recompensa'];
      _ultimaRecompensa = ultimaCruda != null ? DateTime.tryParse('$ultimaCruda') : null;

      _pity = _parsearPity(fila['pity']);

      _recompensaDiariaDisponible = _calcularSiHayRecompensaDisponible();

      _ultimaCargaExitosa = DateTime.now();
      await _guardarEnDisco(userId);
    } catch (e) {
      debugPrint('Error al cargar el perfil: $e');
      _error = 'No se pudo cargar tu saldo.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<ResultadoCompraSobre> comprarSobre({
    required String sobreId,
    required int precio,
    int? limiteDiario,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return ResultadoCompraSobre(ok: false, motivo: MotivoFalloCompra.sinSesion);
    }

    if (!puedeComprar(sobreId, limiteDiario)) {
      return ResultadoCompraSobre(
        ok: false,
        motivo: MotivoFalloCompra.limiteDiario,
        proximaDisponible: proximaDisponible(sobreId),
      );
    }

    try {
      final resultado = await _supabase.rpc('fn_comprar_sobre', params: {
        'p_sobre_id': sobreId,
        'p_precio': precio,
      }) as Map<String, dynamic>;

      final ok = resultado['ok'] == true;
      if (ok) {
        _dinero = (resultado['dinero'] as num).toInt();
        _registrarCompraLocal(sobreId);
        notifyListeners();
        unawaited(_guardarEnDisco(userId));
        return ResultadoCompraSobre(ok: true);
      }

      return ResultadoCompraSobre(ok: false, motivo: MotivoFalloCompra.sinDinero);
    } catch (e) {
      debugPrint('Error al comprar sobre: $e');
      return ResultadoCompraSobre(ok: false, motivo: MotivoFalloCompra.error);
    }
  }

  Future<ResultadoCompraSobre> reclamarSobreAnuncio({
    required String sobreId,
    int limiteDiario = 1,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return ResultadoCompraSobre(ok: false, motivo: MotivoFalloCompra.sinSesion);
    }

    if (!puedeComprar(sobreId, limiteDiario)) {
      return ResultadoCompraSobre(
        ok: false,
        motivo: MotivoFalloCompra.limiteDiario,
        proximaDisponible: proximaDisponible(sobreId),
      );
    }

    _registrarCompraLocal(sobreId);
    notifyListeners();
    unawaited(_guardarEnDisco(userId));
    return ResultadoCompraSobre(ok: true);
  }

  void _registrarCompraLocal(String sobreId) {
    final lista = _comprasPorSobre.putIfAbsent(sobreId, () => []);
    lista.add(DateTime.now());
  }

  Map<String, Map<String, int>> _parsearPity(dynamic crudo) {
    if (crudo == null) return {};
    try {
      final mapa = Map<String, dynamic>.from(crudo as Map);
      return mapa.map((sobreId, valor) {
        final interno = Map<String, dynamic>.from(valor as Map);
        return MapEntry(sobreId, interno.map((k, v) => MapEntry(k, (v as num).toInt())));
      });
    } catch (e) {
      debugPrint('Error al parsear pity: $e');
      return {};
    }
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _calcularSiHayRecompensaDisponible() {
    if (_ultimaRecompensa == null) return true;
    return !_mismoDia(_ultimaRecompensa!, DateTime.now());
  }

  Future<int?> reclamarRecompensaDiaria() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || !_recompensaDiariaDisponible) return null;

    try {
      final resultado = await _supabase.rpc('fn_reclamar_recompensa_diaria') as Map<String, dynamic>;
      final recompensa = (resultado['recompensa'] as num).toInt();

      _dinero = (resultado['dinero'] as num).toInt();
      _rachaDias = (resultado['racha_dias'] as num).toInt();
      _ultimaRecompensa = DateTime.now();
      _recompensaDiariaDisponible = false;
      notifyListeners();
      unawaited(_guardarEnDisco(userId));
      return recompensa;
    } catch (e) {
      debugPrint('Error al reclamar recompensa diaria: $e');
      return null;
    }
  }

  int obtenerPity(String sobreId, String tier) => _pity[sobreId]?[tier] ?? 0;

  Future<void> actualizarPity(String sobreId, Map<String, int> nuevoPity) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _pity[sobreId] = nuevoPity;
    notifyListeners();
    unawaited(_guardarEnDisco(userId));

    try {
      await _supabase.from('profiles').update({'pity': _pity}).eq('id', userId);
    } catch (e) {
      debugPrint('Error al guardar pity: $e');
    }
  }

  // ============================================================================
  // Sobres pendientes
  // ============================================================================

  Future<String?> agregarSobrePendienteConError(String sobreId, {int cantidad = 1}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 'No hay sesión activa (userId es null).';

    _sobresPendientes[sobreId] = (_sobresPendientes[sobreId] ?? 0) + cantidad;
    notifyListeners();
    unawaited(_guardarEnDisco(userId));
    return null;
  }

  Future<bool> agregarSobrePendiente(String sobreId, {int cantidad = 1}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    _sobresPendientes[sobreId] = (_sobresPendientes[sobreId] ?? 0) + cantidad;
    notifyListeners();
    unawaited(_guardarEnDisco(userId));
    return true;
  }

  Future<void> consumirSobrePendiente(String sobreId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final actual = _sobresPendientes[sobreId] ?? 0;
    if (actual <= 0) return;
    final nuevaCantidad = actual - 1;

    if (nuevaCantidad <= 0) {
      _sobresPendientes.remove(sobreId);
    } else {
      _sobresPendientes[sobreId] = nuevaCantidad;
    }
    notifyListeners();
    unawaited(_guardarEnDisco(userId));
  }

  Future<void> actualizarDinero(int nuevoValor) async {
    final anterior = _dinero;
    _dinero = nuevoValor;
    notifyListeners();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    unawaited(_guardarEnDisco(userId));

    try {
      await _supabase.from('profiles').update({'dinero': nuevoValor}).eq('id', userId);
    } catch (e) {
      debugPrint('Error al guardar dinero: $e');
      _dinero = anterior;
      notifyListeners();
      if (userId.isNotEmpty) unawaited(_guardarEnDisco(userId));
    }
  }

  // ============================================================================
  // almacenamiento local
  // ============================================================================

  String _clave(String userId) => '$_kPrefsPrefix$userId';

  Future<void> _cargarDesdeDisco(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final crudo = prefs.getString(_clave(userId));
      if (crudo == null) return;

      final mapa = jsonDecode(crudo) as Map<String, dynamic>;

      _dinero = mapa['dinero'] as int?;
      _rachaDias = (mapa['rachaDias'] ?? 0) as int;
      final ultimaCruda = mapa['ultimaRecompensa'] as String?;
      _ultimaRecompensa = ultimaCruda != null ? DateTime.tryParse(ultimaCruda) : null;
      _recompensaDiariaDisponible = _calcularSiHayRecompensaDisponible();

      _sobresPendientes = Map<String, int>.from(mapa['sobresPendientes'] ?? {});

      final comprasCrudas = Map<String, dynamic>.from(mapa['comprasPorSobre'] ?? {});
      _comprasPorSobre = comprasCrudas.map((k, v) {
        final lista = (v as List).map((s) => DateTime.parse(s as String)).toList();
        return MapEntry(k, lista);
      });

      final ultimaCargaCruda = mapa['ultimaCargaExitosa'] as String?;
      _ultimaCargaExitosa = ultimaCargaCruda != null ? DateTime.tryParse(ultimaCargaCruda) : null;
    } catch (e) {
      debugPrint('Error al leer caché local del perfil: $e');
    }
  }

  Future<void> _guardarEnDisco(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapa = <String, dynamic>{
        'dinero': _dinero,
        'rachaDias': _rachaDias,
        'ultimaRecompensa': _ultimaRecompensa?.toIso8601String(),
        'sobresPendientes': _sobresPendientes,
        'comprasPorSobre': _comprasPorSobre.map(
          (k, v) => MapEntry(k, v.map((t) => t.toIso8601String()).toList()),
        ),
        'ultimaCargaExitosa': _ultimaCargaExitosa?.toIso8601String(),
      };
      await prefs.setString(_clave(userId), jsonEncode(mapa));
    } catch (e) {
      debugPrint('Error al guardar caché local del perfil: $e');
    }
  }

  Future<void> _borrarDisco() async {
    final userId = _userIdCacheado;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave(userId));
    } catch (e) {
      debugPrint('Error al borrar caché local del perfil: $e');
    }
  }

  void limpiar() {
    unawaited(_borrarDisco());
    _dinero = null;
    _rachaDias = 0;
    _ultimaRecompensa = null;
    _recompensaDiariaDisponible = false;
    _pity = {};
    _sobresPendientes = {};
    _comprasPorSobre = {};
    _error = null;
    _ultimaCargaExitosa = null;
    _cacheLocalCargado = false;
    _userIdCacheado = null;
    notifyListeners();
  }
}

void unawaited(Future<void> future) {}

enum MotivoFalloCompra { sinDinero, limiteDiario, sinSesion, error }

class ResultadoCompraSobre {
  final bool ok;
  final MotivoFalloCompra? motivo;
  final DateTime? proximaDisponible;

  ResultadoCompraSobre({required this.ok, this.motivo, this.proximaDisponible});
}