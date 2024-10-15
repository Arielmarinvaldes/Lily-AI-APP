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
  final int activePointsCount; // Cantidad de puntos activos (cuentas registradas)
  final int pointCount; // Cantidad de puntos totales en la esfera
  final double pointSize; // Tamaño de los puntos

  const Sphere3DView({
    Key? key,
    this.activePointsCount = 0,
    this.pointCount = 300, // Valor predeterminado de 300 puntos
    this.pointSize = 2.0, // Tamaño predeterminado de los puntos
  }) : super(key: key);

  @override
  _Sphere3DViewState createState() => _Sphere3DViewState();
}

class _Sphere3DViewState extends State<Sphere3DView> with SingleTickerProviderStateMixin {
  List<Point3D> points = [];
  Set<int> activePoints = {}; // Puntos activos
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

    setActivePoints(widget.activePointsCount); // Establece los puntos activos (rojos) según las cuentas
  }

  @override
  void didUpdateWidget(Sphere3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si se actualiza el número de cuentas activas, actualizamos los puntos rojos
    if (oldWidget.activePointsCount != widget.activePointsCount) {
      setActivePoints(widget.activePointsCount);
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

  // Establecer puntos activos (rojos) según la cantidad de cuentas registradas
  void setActivePoints(int count) {
    setState(() {
      activePoints.clear(); // Limpiar puntos anteriores
      for (int i = 0; i < count.clamp(0, points.length); i++) {
        activePoints.add(i); // Añadir nuevos puntos activos (cuentas registradas)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: Sphere3DPainter(points, rotationAngle, activePoints, widget.pointSize),
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
  final Set<int> activePoints;
  final double pointSize;

  Sphere3DPainter(this.points, this.rotationAngle, this.activePoints, this.pointSize);

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

      // Colorear según el estado del punto (activo o no)
      final paint = Paint()
        ..color = activePoints.contains(i) ? Colors.red : Colors.white;

      // Dibujar el punto con el tamaño especificado
      canvas.drawCircle(Offset(screenX, screenY), pointSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
