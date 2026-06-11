import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';

class LetterDrawingScreen extends ConsumerStatefulWidget {
  const LetterDrawingScreen({super.key});

  @override
  ConsumerState<LetterDrawingScreen> createState() => _LetterDrawingScreenState();
}

class _LetterDrawingScreenState extends ConsumerState<LetterDrawingScreen> {
  List<Offset?> _points = [];

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dibujar Letras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Borrar todo',
            onPressed: _clearCanvas,
          ),
        ],
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Letra de fondo (guía tenue)
            Text(
              'A',
              style: TextStyle(
                fontSize: 350,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withOpacity(0.15),
              ),
            ),
            // Lienzo interactivo
            GestureDetector(
              onPanUpdate: (details) => setState(() => _points.add(details.localPosition)),
              onPanEnd: (details) => setState(() => _points.add(null)),
              child: Container(
                color: Colors.transparent, // Necesario para atrapar gestos en toda la pantalla
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: _DrawingPainter(points: _points, color: appTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  _DrawingPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}