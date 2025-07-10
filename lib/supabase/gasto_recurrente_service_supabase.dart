import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gasto_recurrente.dart';

class GastoRecurrenteServiceSupabase {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'gastos_recurrentes';

  Future<List<GastoRecurrente>> getGastos() async {
    final data = await _client.from(_table).select().order('id');
    return (data as List).map((e) => GastoRecurrente.fromMap(e)).toList();
  }

  Future<GastoRecurrente> addGasto(GastoRecurrente gasto) async {
    final inserted = await _client.from(_table).insert(gasto.toMap()).select().single();
    return GastoRecurrente.fromMap(inserted);
  }

  Future<void> updateGasto(GastoRecurrente gasto) async {
    await _client.from(_table).update(gasto.toMap()).eq('id', gasto.id ?? 0);
  }

  Future<void> deleteGasto(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
