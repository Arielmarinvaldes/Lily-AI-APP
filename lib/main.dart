import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Importar para usar Timer
import 'ChatPage.dart';
import 'register_page.dart';
import 'gradient_background.dart';
import 'sphere3dview.dart'; // Importa la esfera 3D desde el archivo separado
import 'utils.dart';  // Importar la función de conexión

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
  List<int> connectionStates = []; // Lista para almacenar los estados de conexión
  late Timer _statusUpdateTimer; // Timer para actualizar los estados

  @override
  void initState() {
    super.initState();
    _fetchConnectionStates(); // Llamada para obtener los estados de conexión al inicio
    _startStatusUpdate(); // Iniciar el Timer para actualizaciones en tiempo real
  }

  // Iniciar el Timer para actualizar los estados de conexión cada 5 segundos
  void _startStatusUpdate() {
    _statusUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _fetchConnectionStates();
    });
  }

  // Cancelar el Timer cuando se destruye el widget
  @override
  void dispose() {
    _statusUpdateTimer.cancel();
    super.dispose();
  }

  // Función para obtener los estados de conexión de las cuentas
  Future<void> _fetchConnectionStates() async {
    final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/obtener_estado_usuarios"; // Ajusta tu URL

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          // Almacenar los estados de conexión (0 o 1) en connectionStates
          connectionStates = data.map((usuario) => usuario['conectado'] as int).toList();
        });
      } else {
        _mostrarError('Error: No se pudo obtener los estados de conexión');
      }
    } catch (e) {
      _mostrarError('Error de conexión: No se pudo conectar con el servidor.');
    }
  }

  // Función para verificar el estado de una cuenta específica por email
  Future<int?> _verificarEstadoCuenta(String email) async {
    final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/obtener_estado_usuarios"; // Endpoint para obtener estados de usuarios

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> usuarios = jsonDecode(response.body);

        // Buscar el usuario por su email
        for (var usuario in usuarios) {
          if (usuario['email'] == email) {
            return usuario['conectado']; // Retorna el estado de la conexión (0 o 1)
          }
        }
      }
    } catch (e) {
      _mostrarError('Error de conexión: No se pudo verificar el estado de la cuenta.');
    }
    return null; // Retornar null si no se encuentra el usuario o hay error
  }

  // Mostrar un mensaje de error usando un Snackbar
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Función para manejar el inicio de sesión
  Future<void> login() async {
    final String email = emailController.text;

    // Verificamos si el usuario está conectado
    int? estadoCuenta = await _verificarEstadoCuenta(email);

    if (estadoCuenta == null) {
      _mostrarError('Error al verificar el estado de la cuenta.');
      return;
    }

    if (estadoCuenta == 1) {
      // Si el estado es 1 (conectado), mostramos el error y evitamos el inicio de sesión
      _mostrarError('Esta cuenta ya está conectada en otro dispositivo.');
      return;
    }

    // Si el estado es 0 (no conectado), procedemos con el inicio de sesión
    final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/login"; // Asegúrate de que sea la IP correcta

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await actualizarEstadoConexion(data['message'], 1); // Actualiza el estado a conectado (1)

        // Si el inicio de sesión es exitoso, navega a la pantalla de chat y pasas el número de cuentas registradas
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatPage(userEmail: data['message'], numCuentas: connectionStates.length)), // Aquí pasas numCuentas
        );
      } else {
        // Si el servidor responde pero con error, mostramos el mensaje de error
        _mostrarError('Error: ${response.body}');
      }
    } catch (e) {
      // Si ocurre algún error durante la solicitud (problemas de red, etc.)
      _mostrarError('Error de conexión: No se pudo conectar con el servidor.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Colocar la esfera 3D en la parte superior, pasando los estados de conexión
            Sphere3DView(connectionStates: connectionStates), // Pasamos los estados de conexión a la esfera
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
