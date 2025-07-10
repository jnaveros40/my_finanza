import 'package:flutter/material.dart';
import '../../Service/supabase_drawer.dart';


class DashboardScreen extends StatelessWidget {
  final String email;
  const DashboardScreen({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Supabase')),
      drawer: SupabaseDrawer(userEmail: email),
      body: Center(
        child: Text('Bienvenido, $email!', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}


