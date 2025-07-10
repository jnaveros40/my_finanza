import 'package:flutter/material.dart';

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
          const Divider(),
          _buildDrawerItem(context, Icons.settings, 'Configuración', 7),
          _buildDrawerItem(context, Icons.notifications, 'Notificaciones', 8),
          _buildDrawerItem(context, Icons.update, 'Actualización de inversiones', 9),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // Aquí puedes manejar la navegación según el índice o el título
        Navigator.pop(context); // Cierra el drawer
        // TODO: Implementar navegación real
      },
    );
  }
}
