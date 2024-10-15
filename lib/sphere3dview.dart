import 'package:flutter/material.dart';
import 'dart:math'; // Para el cálculo de puntos 3D

// Clase para representar un punto 3D
class Point3D {
  final double x;
  final double y;
  final double z;

  Point3D(this.x, this.y, this.z);
}

class Sphere3DView extends StatefulWidget {
  final List<int> connectionStates; // Lista de estados de conexión (1 = conectado, 0 = desconectado)
  final int pointCount; // Cantidad de puntos totales en la esfera
  final double pointSize; // Tamaño de los puntos

  const Sphere3DView({
    Key? key,

    required this.connectionStates, // Lista de estados de conexión
    this.pointCount = 300, // Valor predeterminado de 300 puntos
    this.pointSize = 2.0, // Tamaño predeterminado de los puntos
  }) : super(key: key);

  @override
  _Sphere3DViewState createState() => _Sphere3DViewState();
}

class _Sphere3DViewState extends State<Sphere3DView> with SingleTickerProviderStateMixin {
  List<Point3D> points = [];
  late AnimationController _controller;
  double rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    generatePoints(); // Genera los puntos de la esfera
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 60))
      ..repeat(); // Repite la animación continuamente

    _controller.addListener(() {
      setState(() {
        rotationAngle += 0.01; // Incrementa el ángulo de rotación
      });
    });
  }

  @override
  void didUpdateWidget(Sphere3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si se actualizan los estados de conexión, también actualizamos la esfera
    if (oldWidget.connectionStates != widget.connectionStates) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Generar puntos 3D aleatorios en la esfera
  void generatePoints() {
    points.clear();
    for (int i = 0; i < widget.pointCount; i++) {
      final theta = Random().nextDouble() * 2 * pi;
      final phi = acos(2 * Random().nextDouble() - 1);
      final x = cos(theta) * sin(phi);
      final y = sin(theta) * sin(phi);
      final z = cos(phi);
      points.add(Point3D(x, y, z));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: Sphere3DPainter(points, rotationAngle, widget.connectionStates, widget.pointSize),
      child: Container(
        height: 250, // Ajustar la altura de la esfera
        width: double.infinity,
      ),
    );
  }
}

// Pintor personalizado para dibujar la esfera 3D
class Sphere3DPainter extends CustomPainter {
  final List<Point3D> points;
  final double rotationAngle;
  final List<int> connectionStates; // Lista de estados de conexión
  final double pointSize;

  Sphere3DPainter(this.points, this.rotationAngle, this.connectionStates, this.pointSize);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(size.width, size.height) / 1.6;

    // Centrar la esfera
    canvas.translate(size.width / 2, size.height / 1);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Aplicar la rotación en el eje Z
      final rotatedX = point.x * cos(rotationAngle) - point.z * sin(rotationAngle);
      final rotatedZ = point.x * sin(rotationAngle) + point.z * cos(rotationAngle);

      // Coordenadas en pantalla
      final screenX = rotatedX * radius;
      final screenY = point.y * radius;

      // Determinar el color del punto:
      // - Verde si el usuario está conectado (connectionStates[i] == 1)
      // - Rojo si es una cuenta registrada pero está desconectada (connectionStates[i] == 0)
      // - Blanco para el resto de los puntos
      final paint = Paint()
        ..color = (i < connectionStates.length)
            ? (connectionStates[i] == 1
            ? Colors.green  // Conectado (verde)
            : Colors.red)   // Registrado pero desconectado (rojo)
            : Colors.white;     // No registrado (blanco)

      // Dibujar el punto con el tamaño especificado
      canvas.drawCircle(Offset(screenX, screenY), pointSize, paint);
    }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
