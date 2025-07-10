import 'package:flutter/material.dart';
import '../supabase/auth_service_supabase.dart';
import '../screens/Auth/login_screen.dart';
import '../screens/cuentas/cuentas_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/categorias/categorias_screen.dart';
import '../screens/gastos_recurrentes/gastos_recurrentes_screen.dart';

class SupabaseDrawer extends StatelessWidget {
  final String? userEmail;
  const SupabaseDrawer({Key? key, this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Usuario'),
            accountEmail: Text(userEmail ?? ''),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person, size: 32),
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Dashboard', 0),
          _buildDrawerItem(context, Icons.account_balance, 'Cuentas', 1),
          _buildDrawerItem(context, Icons.swap_horiz, 'Movimientos', 2),
          _buildDrawerItem(context, Icons.pie_chart, 'Presupuestos', 3),
          _buildDrawerItem(context, Icons.trending_up, 'Inversiones', 4),
          _buildDrawerItem(context, Icons.money_off, 'Deudas', 5),
          _buildDrawerItem(context, Icons.category, 'Categorías', 6),
          _buildDrawerItem(context, Icons.repeat, 'Gastos Recurrentes', 10),
          const Divider(),
          _buildDrawerItem(context, Icons.settings, 'Configuración', 7),
          _buildDrawerItem(context, Icons.notifications, 'Notificaciones', 8),
          _buildDrawerItem(context, Icons.update, 'Actualización de inversiones', 9),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await SupabaseAuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SupabaseLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Cierra el drawer
        switch (title) {
          case 'Dashboard':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => DashboardScreen(email: userEmail ?? '')),
            );
            break;
          case 'Cuentas':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CuentasScreen()),
            );
            break;
          case 'Categorías':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CategoriasScreen()),
            );
            break;
          case 'Gastos Recurrentes':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const GastosRecurrentesScreen()),
            );
            break;
          // Aquí puedes agregar navegación para otras secciones
        }
      },
    );
  }
}
