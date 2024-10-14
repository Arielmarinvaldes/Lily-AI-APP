import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode; // Bandera para modo oscuro

  GradientBackground({required this.child, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Color(0xFF47614A), Color(0xFF26343A)] // Colores del modo oscuro
              : [Color(0xFFA8E6CF), Color(0xFFDCEDC1)], // Colores del modo claro
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          transform: GradientRotation(270 * 3.1416 / 180), // Rotación de 270 grados
        ),
      ),
      child: child,
    );
  }
}
