import 'package:supabase_flutter/supabase_flutter.dart';

class UserServiceSupabase {
  static int? getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    // Asumiendo que el id de usuario está en user.id y es int en la tabla usuarios
    // Si es UUID, deberás ajustar el modelo y la base de datos
    if (user == null) return null;
    // Si tu tabla usuarios usa UUID, retorna user.id
    // Si tienes un campo int, deberás mapearlo desde el perfil
    // Aquí se asume que el id es int y está en user.userMetadata['id']
    return user.userMetadata?['id'] as int?;
  }
}
