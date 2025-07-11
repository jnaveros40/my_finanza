import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/presupuesto.dart';

class PresupuestoServiceSupabase {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'f_presupuestos';

  Future<List<Presupuesto>> getPresupuestos() async {
    final data = await _client.from(_table)
      .select()
      .order('periodo_anio', ascending: false)
      .order('periodo_mes', ascending: false);
    return (data as List).map((e) => Presupuesto.fromMap(e)).toList();
  }

  Future<Presupuesto> addPresupuesto(Presupuesto presupuesto) async {
    print('Insertando en Supabase: ${presupuesto.toMap()}');
    final inserted = await _client.from(_table).insert(presupuesto.toMap()).select().single();
    print('Respuesta Supabase: $inserted');
    return Presupuesto.fromMap(inserted);
  }

  Future<void> updatePresupuesto(Presupuesto presupuesto) async {
    print('Actualizando en Supabase: ${presupuesto.toMap()}');
    await _client.from(_table).update(presupuesto.toMap()).eq('id', presupuesto.id ?? 0);
  }

  Future<void> deletePresupuesto(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
