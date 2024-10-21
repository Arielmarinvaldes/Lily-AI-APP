import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/gradient_background.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Función para hacer la solicitud POST a la API de Flask
  Future<void> register() async {
    // final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/register"; // Cambia la URL por la correcta
    final String apiUrl = "http://192.168.172.86:5001/register";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_name": nameController.text,
        "email": emailController.text,
        "password": passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registro exitoso: ${data['message']}')));

      // Después de mostrar el mensaje, redirigir a la pantalla de inicio de sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      final error = jsonDecode(response.body)['error'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            // Botón de retroceso en la esquina superior izquierda
            Positioned(
              top: 40, // Ajusta la posición si es necesario
              left: 16,
              child: IconButton(
                icon: Icon(Icons.chevron_left, color: Colors.black, size: 30), // Color negro para que destaque
                onPressed: () {
                  Navigator.pop(context); // Volver a la pantalla anterior
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Nombre'),
                  ),
                  SizedBox(height: 16),
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
                    onPressed: register,
                    child: Text('Registrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}