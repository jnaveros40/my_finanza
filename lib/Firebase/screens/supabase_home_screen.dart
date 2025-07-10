import 'package:flutter/material.dart';

class SupabaseHomeScreen extends StatelessWidget {
  final String email;
  const SupabaseHomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Supabase')),
      body: Center(
        child: Text('Bienvenido, $email!', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
