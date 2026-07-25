import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  int? _dinero;
  bool _cargando = false;
  String? _error;

  int? get dinero => _dinero;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final fila = await _supabase
          .from('profiles')
          .select('dinero')
          .eq('id', userId)
          .single();
      _dinero = (fila['dinero'] ?? 0) as int;
    } catch (e) {
      debugPrint('Error al cargar el perfil: $e');
      _error = 'No se pudo cargar tu saldo.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void actualizarDinero(int nuevoValor) {
    _dinero = nuevoValor;
    notifyListeners();
  }

  void limpiar() {
    _dinero = null;
    _error = null;
    notifyListeners();
  }
}
