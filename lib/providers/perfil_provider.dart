import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recompensas de dinero por día de racha (día 7 = jackpot, luego reinicia el ciclo).
const List<int> _recompensasPorDiaDeRacha = [50, 60, 75, 90, 110, 140, 250];

class PerfilProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  int? _dinero;
  bool _cargando = false;
  String? _error;

  // ---------- RACHA / RECOMPENSA DIARIA ----------
  int _rachaDias = 0;
  DateTime? _ultimaRecompensa;
  bool _recompensaDiariaDisponible = false;

  // ---------- PITY (protección contra mala suerte en sobres) ----------
  // sobreId -> {'violeta': contador, 'dorado': contador}
  Map<String, Map<String, int>> _pity = {};

  int? get dinero => _dinero;
  bool get cargando => _cargando;
  String? get error => _error;
  int get rachaDias => _rachaDias;
  bool get recompensaDiariaDisponible => _recompensaDiariaDisponible;
  int get proximaRecompensa {
    final diaObjetivo = (_rachaDias % 7); // si hoy reclamo, seguiría este día (0-indexed -> día siguiente)
    return _recompensasPorDiaDeRacha[diaObjetivo];
  }

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

  /// Reclama la recompensa diaria. Devuelve el monto ganado, o null si ya se reclamó hoy.
  Future<int?> reclamarRecompensaDiaria() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || !_recompensaDiariaDisponible) return null;

    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    final esConsecutivo = _ultimaRecompensa != null && _mismoDia(_ultimaRecompensa!, ayer);

    final nuevaRacha = esConsecutivo ? (_rachaDias % 7) + 1 : 1;
    final recompensa = _recompensasPorDiaDeRacha[nuevaRacha - 1];
    final nuevoDinero = (_dinero ?? 0) + recompensa;

    try {
      await _supabase.from('profiles').update({
        'dinero': nuevoDinero,
        'racha_dias': nuevaRacha,
        'ultima_recompensa': hoy.toIso8601String().substring(0, 10),
      }).eq('id', userId);

      _dinero = nuevoDinero;
      _rachaDias = nuevaRacha;
      _ultimaRecompensa = hoy;
      _recompensaDiariaDisponible = false;
      notifyListeners();
      return recompensa;
    } catch (e) {
      debugPrint('Error al reclamar recompensa diaria: $e');
      return null;
    }
  }

  // ---------- PITY ----------

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
    _error = null;
    notifyListeners();
  }
}