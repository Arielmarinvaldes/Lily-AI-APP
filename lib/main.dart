// lib/main.dart

import 'package:flutter/material.dart';
import 'pages/login_page.dart';

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
      home: LoginPage(), // Establece LoginPage como la pantalla de inicio
      debugShowCheckedModeBanner: false, // Opcional: elimina la etiqueta de debug
    );
  }
}
