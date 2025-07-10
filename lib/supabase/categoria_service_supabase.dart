import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria.dart';

class CategoriaServiceSupabase {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'f_categorias';

  Future<List<Categoria>> getCategorias() async {
    final data = await _client.from(_table).select().order('id');
    return (data as List).map((e) => Categoria.fromMap(e)).toList();
  }

  Future<Categoria> addCategoria(Categoria categoria) async {
    final inserted = await _client.from(_table).insert(categoria.toMap()).select().single();
    return Categoria.fromMap(inserted);
  }

  Future<void> updateCategoria(Categoria categoria) async {
    await _client.from(_table).update(categoria.toMap()).eq('id', categoria.id ?? 0);
  }

  Future<void> deleteCategoria(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
