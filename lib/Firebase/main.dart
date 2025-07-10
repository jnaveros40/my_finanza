// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Importar el paquete provider
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/supabase_login_screen.dart';
import 'supabase/supabase_init.dart';
import 'screens/core/main_app_screen.dart';
import 'services/push_notification_service.dart';

// Clase para manejar el estado del tema (claro/oscuro y ahora el acento de color)
class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Tema por defecto: el del sistema
  Color _accentColor = Colors.black; // Color de acento por defecto
  bool _isHighContrastMode = false; // Modo de alto contraste

  ThemeManager() {
    _loadThemeFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrastMode => _isHighContrastMode;
    // Getter que devuelve el color efectivo basado en el modo de contraste
  Color get accentColor {
    if (_isHighContrastMode) {
      // En modo alto contraste, usar negro para tema claro y blanco para tema oscuro
      if (_themeMode == ThemeMode.dark) {
        return Colors.white;
      } else if (_themeMode == ThemeMode.light) {
        return Colors.black;
      } else {
        // Para ThemeMode.system, usar negro como default pero esto se podría mejorar
        // con context awareness del brillo del sistema
        return Colors.black;
      }
    }
    return _accentColor;
  }

  // Método helper para obtener el color efectivo con context del sistema
  Color getEffectiveAccentColor(BuildContext context) {
    if (_isHighContrastMode) {
      final brightness = _themeMode == ThemeMode.system 
          ? MediaQuery.of(context).platformBrightness 
          : (_themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
      
      return brightness == Brightness.dark ? Colors.white : Colors.black;
    }
    return _accentColor;
  }

  // Getter para obtener el color base sin aplicar alto contraste
  Color get baseAccentColor => _accentColor;

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    final accentColorValue = prefs.getInt('accentColor') ?? Colors.teal.value;
    final highContrastMode = prefs.getBool('isHighContrastMode') ?? false;
    
    _themeMode = ThemeMode.values[themeIndex];
    _accentColor = Color(accentColorValue);
    _isHighContrastMode = highContrastMode;
    notifyListeners();
  }

  // Método para cambiar el tema
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  // Método para cambiar el color de acento base
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', color.value);
  }

  // Método para alternar el modo de alto contraste
  Future<void> setHighContrastMode(bool enabled) async {
    _isHighContrastMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHighContrastMode', enabled);
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Inicializar Supabase
  await initSupabase();

  // Inicialización de notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Inicializar notificaciones push
  await PushNotificationService.initialize();

  // Envolver MyApp con ChangeNotifierProvider para proveer ThemeManager
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeManager(), // Crear una instancia de ThemeManager
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener la instancia de ThemeManager proporcionada por el Provider
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      title: 'JNFinanza_app',
      // --- LOCALIZACIÓN ---
      locale: const Locale('es'), // Español por defecto
      supportedLocales: const [
        Locale('es'), // Español
        Locale('en'), // Inglés (opcional, puedes quitarlo si solo quieres español)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Definir el tema claro
      theme: ThemeData(
        // Usar el accentColor del ThemeManager como color semilla para el tema claro
        primarySwatch: MaterialColor(themeManager.accentColor.value, {
          50: themeManager.accentColor.withOpacity(0.1),
          100: themeManager.accentColor.withOpacity(0.2),
          200: themeManager.accentColor.withOpacity(0.3),
          300: themeManager.accentColor.withOpacity(0.4),
          400: themeManager.accentColor.withOpacity(0.5),
          500: themeManager.accentColor.withOpacity(0.6), // El color principal
          600: themeManager.accentColor.withOpacity(0.7),
          700: themeManager.accentColor.withOpacity(0.8),
          800: themeManager.accentColor.withOpacity(0.9),
          900: themeManager.accentColor.withOpacity(1.0),
        }),
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeManager.accentColor, // Usar el acento como color semilla
          brightness: Brightness.light,
          primary: themeManager.accentColor, // Asegurar que el primary sea el acento
          onPrimary: Colors.white, // Texto sobre el color primario
          secondary: themeManager.accentColor.withOpacity(0.7), // Un tono más suave para el secundario
          onSecondary: Colors.white,
          surface: Colors.white, // Color de las superficies
          onSurface: Colors.black87, // Texto sobre las superficies
          error: Colors.redAccent, // Color para errores
          onError: Colors.white,
          background: Colors.white, // Color de fondo
          onBackground: Colors.black87,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: themeManager.accentColor, // AppBar con el color de acento
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: themeManager.accentColor.withOpacity(0.8), // FAB con un tono del acento
          foregroundColor: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.copyWith(
          headlineLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 28),
          headlineMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 22),
          titleLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.normal, fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.normal, fontSize: 14),
          bodySmall: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.normal, fontSize: 12),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
          labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.grey[700]),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 16),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        // Quitar la segunda definición de cardTheme para evitar duplicidad
      ),
      // Definir el tema oscuro
      darkTheme: ThemeData(
        // Usar el accentColor del ThemeManager como color semilla para el tema oscuro
        primarySwatch: MaterialColor(themeManager.accentColor.value, {
          50: themeManager.accentColor.withOpacity(0.1),
          100: themeManager.accentColor.withOpacity(0.2),
          200: themeManager.accentColor.withOpacity(0.3),
          300: themeManager.accentColor.withOpacity(0.4),
          400: themeManager.accentColor.withOpacity(0.5),
          500: themeManager.accentColor.withOpacity(0.6),
          600: themeManager.accentColor.withOpacity(0.7),
          700: themeManager.accentColor.withOpacity(0.8),
          800: themeManager.accentColor.withOpacity(0.9),
          900: themeManager.accentColor.withOpacity(1.0),
        }),
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeManager.accentColor, // Usar el acento como color semilla
          brightness: Brightness.dark,
          primary: themeManager.accentColor.withOpacity(0.8), // Un tono del acento para el primario en oscuro
          onPrimary: Colors.white,
          secondary: themeManager.accentColor.withOpacity(0.6),
          onSecondary: Colors.white,
          surface: Color(0xFF1D1D1D), // Gris muy oscuro para superficies
          onSurface: Colors.white70,
          error: Colors.redAccent, // Rojo claro para errores
          onError: Colors.white,
          background: Colors.black, // Fondo negro
          onBackground: Colors.white70,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF121212), // Negro/gris muy oscuro para AppBar
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: themeManager.accentColor.withOpacity(0.8), // FAB con un tono del acento
          foregroundColor: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          headlineLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 28),
          headlineMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 22),
          titleLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.normal, fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.normal, fontSize: 14),
          bodySmall: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.normal, fontSize: 12),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Color(0xFF232323),
          labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.grey[300]),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 16),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        // Quitar la segunda definición de cardTheme para evitar duplicidad
      ),
      // Usar el themeMode del ThemeManager para controlar qué tema se aplica
      themeMode: themeManager.themeMode,
      // Pantalla de login aislada para Supabase
      home: SupabaseLoginScreen(),
    );
  }
}

// Widget para verificar el estado de autenticación y mostrar la pantalla correcta
class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }        // Si hay usuario autenticado, ir a la pantalla principal con la navegación inferior
        if (snapshot.hasData) {
          return MainAppScreen(initialIndex: 0); // Navegar a MainAppScreen iniciando en Dashboard (índice 0)
        }

        // Si no hay usuario autenticado
        return LoginScreen();
      },
    );
  }
}
