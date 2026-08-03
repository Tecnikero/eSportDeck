import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<int> _recompensasPorDiaDeRacha = [50, 60, 75, 90, 110, 140, 250];

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

  Future<void> cargar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

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

      await _cargarSobresPendientes(userId);
    } catch (e) {
      debugPrint('Error al cargar el perfil: $e');
      _error = 'No se pudo cargar tu saldo.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
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

    try {
      await _supabase.from('profiles').update({'pity': _pity}).eq('id', userId);
    } catch (e) {
      debugPrint('Error al guardar pity: $e');
    }
    notifyListeners();
  }

  Future<void> _cargarSobresPendientes(String userId) async {
    try {
      final filas = await _supabase
          .from('sobres_pendientes')
          .select('sobre_id, cantidad')
          .eq('user_id', userId);

      final mapa = <String, int>{};
      for (final fila in (filas as List)) {
        final id = '${fila['sobre_id']}';
        final cantidad = (fila['cantidad'] ?? 0) as int;
        if (cantidad > 0) mapa[id] = cantidad;
      }
      _sobresPendientes = mapa;
    } catch (e) {
      debugPrint('Error al cargar sobres pendientes: $e');
    }
  }

  Future<String?> agregarSobrePendienteConError(String sobreId, {int cantidad = 1}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 'No hay sesión activa (userId es null).';

    final actual = _sobresPendientes[sobreId] ?? 0;
    final nuevaCantidad = actual + cantidad;
    _sobresPendientes[sobreId] = nuevaCantidad;
    notifyListeners();

    try {
      final filas = await _supabase
          .from('sobres_pendientes')
          .select('id, cantidad')
          .eq('user_id', userId)
          .eq('sobre_id', sobreId);

      final lista = filas as List;
      if (lista.isNotEmpty) {
        final registro = lista.first;
        await _supabase
            .from('sobres_pendientes')
            .update({'cantidad': ((registro['cantidad'] ?? 0) as int) + cantidad})
            .eq('id', registro['id']);
      } else {
        await _supabase.from('sobres_pendientes').insert({
          'user_id': userId,
          'sobre_id': sobreId,
          'cantidad': cantidad,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error al guardar sobre pendiente: $e');
      final actualTrasFallo = (_sobresPendientes[sobreId] ?? cantidad) - cantidad;
      if (actualTrasFallo <= 0) {
        _sobresPendientes.remove(sobreId);
      } else {
        _sobresPendientes[sobreId] = actualTrasFallo;
      }
      notifyListeners();
      return e.toString();
    }
  }

  Future<bool> agregarSobrePendiente(String sobreId, {int cantidad = 1}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final actual = _sobresPendientes[sobreId] ?? 0;
    final nuevaCantidad = actual + cantidad;
    _sobresPendientes[sobreId] = nuevaCantidad;
    notifyListeners();

    try {
      final filas = await _supabase
          .from('sobres_pendientes')
          .select('id, cantidad')
          .eq('user_id', userId)
          .eq('sobre_id', sobreId);

      final lista = filas as List;
      if (lista.isNotEmpty) {
        final registro = lista.first;
        await _supabase
            .from('sobres_pendientes')
            .update({'cantidad': ((registro['cantidad'] ?? 0) as int) + cantidad})
            .eq('id', registro['id']);
      } else {
        await _supabase.from('sobres_pendientes').insert({
          'user_id': userId,
          'sobre_id': sobreId,
          'cantidad': cantidad,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error al guardar sobre pendiente: $e');
      final actualTrasFallo = (_sobresPendientes[sobreId] ?? cantidad) - cantidad;
      if (actualTrasFallo <= 0) {
        _sobresPendientes.remove(sobreId);
      } else {
        _sobresPendientes[sobreId] = actualTrasFallo;
      }
      notifyListeners();
      return false;
    }
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

    try {
      if (nuevaCantidad <= 0) {
        await _supabase
            .from('sobres_pendientes')
            .delete()
            .eq('user_id', userId)
            .eq('sobre_id', sobreId);
      } else {
        await _supabase
            .from('sobres_pendientes')
            .update({'cantidad': nuevaCantidad})
            .eq('user_id', userId)
            .eq('sobre_id', sobreId);
      }
    } catch (e) {
      debugPrint('Error al consumir sobre pendiente: $e');
    }
  }

  void actualizarDinero(int nuevoValor) {
    _dinero = nuevoValor;
    notifyListeners();
  }

  void limpiar() {
    _dinero = null;
    _rachaDias = 0;
    _ultimaRecompensa = null;
    _recompensaDiariaDisponible = false;
    _pity = {};
    _sobresPendientes = {};
    _error = null;
    notifyListeners();
  }
}