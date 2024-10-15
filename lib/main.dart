import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ChatPage.dart';
import 'register_page.dart';
import 'gradient_background.dart';
import 'sphere3dview.dart'; // Importa la esfera 3D desde el archivo separado

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inicio de Sesión',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = ''; // Variable para almacenar el mensaje de error
  int numCuentas = 0; // Almacenará el número de cuentas

  @override
  void initState() {
    super.initState();
    _fetchCuentas(); // Llamada para obtener el número de cuentas activas al inicio
  }

  // Función para obtener el número de cuentas del servidor
  Future<void> _fetchCuentas() async {
    final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/get_cuentas"; // Ajusta tu URL

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          numCuentas = data['num_cuentas']; // Establece el número de cuentas
        });
      } else {
        setState(() {
          errorMessage = 'Error: No se pudo obtener el número de cuentas';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión: No se pudo conectar con el servidor.';
      });
    }
  }

  // Función para manejar el inicio de sesión
  Future<void> login() async {
    final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/login"; // Asegúrate de que sea la IP correcta

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Si el inicio de sesión es exitoso, navega a la pantalla de chat y pasas el número de cuentas registradas
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatPage(userEmail: data['message'], numCuentas: numCuentas)), // Aquí pasas numCuentas
        );
      } else {
        // Si el servidor responde pero con error, mostramos el mensaje de error
        setState(() {
          errorMessage = 'Error: ${response.body}';
        });
      }
    } catch (e) {
      // Si ocurre algún error durante la solicitud (problemas de red, etc.)
      setState(() {
        errorMessage = 'Error de conexión: No se pudo conectar con el servidor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Colocar la esfera 3D en la parte superior
            Sphere3DView(activePointsCount: numCuentas), // Pasamos el número de cuentas activas a la esfera
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Correo electrónico'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: login,
                      child: Text('Iniciar Sesión'),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterPage()),
                        );
                      },
                      child: Text('¿No tienes cuenta? Regístrate'),
                    ),
                    SizedBox(height: 16),
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 16), // Mensaje en rojo
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
