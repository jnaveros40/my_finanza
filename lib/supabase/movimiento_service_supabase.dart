import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento.dart';

class MovimientoServiceSupabase {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'movimientos';

  Future<List<Movimiento>> getMovimientos() async {
    final data = await _client.from(_table).select().order('fecha', ascending: false);
    return (data as List).map((e) => Movimiento.fromMap(e)).toList();
  }

  Future<Movimiento> addMovimiento(Movimiento movimiento) async {
    final inserted = await _client.from(_table).insert(movimiento.toMap()).select().single();
    return Movimiento.fromMap(inserted);
  }

  Future<void> updateMovimiento(Movimiento movimiento) async {
    await _client.from(_table).update(movimiento.toMap()).eq('id', movimiento.id ?? 0);
  }

  Future<void> deleteMovimiento(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
