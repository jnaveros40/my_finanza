// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mis_finanza/screens/core/main_app_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Función para manejar el inicio de sesión con Google
  Future<void> _handleSignIn() async {
    print('--- INICIO DE SESIÓN CON GOOGLE ---');
    try {
      print('Iniciando flujo de GoogleSignIn...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('Resultado googleUser: $googleUser');

      if (googleUser == null) {
        print('El usuario canceló el inicio de sesión con Google.');
        return;
      }

      print('Obteniendo autenticación de Google...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Tokens obtenidos: accessToken=${googleAuth.accessToken}, idToken=${googleAuth.idToken}');

      print('Creando credencial de Firebase...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Iniciando sesión en Firebase con la credencial de Google...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      print('Resultado userCredential: $userCredential');
      print('Usuario autenticado: $user');

      if (user != null) {
        print('¡Inicio de sesión con Google exitoso para: ${user.displayName}');
        print('ID de usuario de Firebase: ${user.uid}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainAppScreen(initialIndex: 0)),
        );
      } else {
        print('Error: user es null después de signInWithCredential.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión. Inténtalo de nuevo.')),
        );
      }
    } catch (e, stack) {
      print('---------------------------------------');
      print('Error detallado en el inicio de sesión con Google: $e');
      print('Stacktrace: $stack');
      print('---------------------------------------');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error. Por favor, inténtalo de nuevo.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JNFinanza_app - Iniciar Sesión'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Bienvenido a su app personal de finanzas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              // Botón de Inicio de Sesión con Google
              ElevatedButton.icon(
                icon: Image.asset(
                  'assets/images/google_logo.png', // Necesitarás añadir un logo de Google en la carpeta assets
                  height: 24.0,
                ),
                label: const Text('Iniciar Sesión con Google'),
                onPressed: _handleSignIn, // Llama a la función de inicio de sesión
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: Theme.of(context).colorScheme.primary, // Usar el color primario del tema
                  foregroundColor: Theme.of(context).colorScheme.onPrimary, // Usar el color de texto del tema
                ),
              ),
              // Opcional: indicador de carga
              // if (_isLoading) CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}