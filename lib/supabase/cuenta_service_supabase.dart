import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cuenta.dart';

class CuentaServiceSupabase {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'cuentas';

  Future<List<Cuenta>> getCuentas() async {
    final data = await _client.from(_table).select().order('id');
    return (data as List).map((e) => Cuenta.fromMap(e)).toList();
  }

  Future<Cuenta> addCuenta(Cuenta cuenta) async {
    final inserted = await _client.from(_table).insert(cuenta.toMap()).select().single();
    return Cuenta.fromMap(inserted);
  }

  Future<void> updateCuenta(Cuenta cuenta) async {
    await _client.from(_table).update(cuenta.toMap()).eq('id', cuenta.id ?? 0);
  }

  Future<void> deleteCuenta(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
