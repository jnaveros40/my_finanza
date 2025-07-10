import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://edvvyvlouvrlvsnxecyy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkdnZ5dmxvdXZybHZzbnhlY3l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0OTc0ODYsImV4cCI6MjA2NzA3MzQ4Nn0.ysJHdL7QgwQcz7wBTZ4tZpvI3whu5KVfiFnuBk6VZvA',
  );
}
