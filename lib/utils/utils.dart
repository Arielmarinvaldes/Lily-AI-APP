import 'package:http/http.dart' as http;
import 'dart:convert';

// Función para actualizar el estado de conexión en el servidor
Future<void> actualizarEstadoConexion(String email, int estado) async {
  // final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/actualizar_estado_conexion"; // URL para actualizar estado de conexión
  final String apiUrl = "http://192.168.96.13:5001/actualizar_estado_conexion"; // URL para actualizar estado de conexión

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "conectado": estado,  // Pasamos 1 para conectado, 0 para desconectado
      }),
    );

    if (response.statusCode != 200) {
      print('Error al actualizar el estado de conexión');
    }
  } catch (e) {
    print('Error de conexión: $e');
  }
}

// Función para actualizar el estado de conexión en el servidor
Future<void> actualizarEstadoConexion_logout(String email, int estado) async {
  // final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/logout"; // URL para actualizar estado de conexión
  final String apiUrl = "http://192.168.96.13:5001/logout"; // URL para actualizar estado de conexión

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "conectado": estado,  // Pasamos 1 para conectado, 0 para desconectado
      }),
    );

    if (response.statusCode != 200) {
      print('Error al actualizar el estado de conexión');
    }
  } catch (e) {
    print('Error de conexión: $e');
  }
}

