import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'theme_notifier.dart';
import 'progress_notifier.dart';
import 'auth_repository.dart';
import 'actividad_record.dart';
import 'historial_provider.dart';

class LetterDrawingScreen extends ConsumerStatefulWidget {
  final String letra;
  final String idNivel;

  const LetterDrawingScreen({
    super.key,
    required this.letra,
    required this.idNivel,
  });

  @override
  ConsumerState<LetterDrawingScreen> createState() => _LetterDrawingScreenState();
}

class _LetterDrawingScreenState extends ConsumerState<LetterDrawingScreen> {
  List<Offset?> _points = [];
  final FlutterTts flutterTts = FlutterTts();

  // Se usan para las métricas del historial (fluidez) y para calcular la
  // precisión del trazo. `_fechaInicio` se fija apenas se monta la pantalla.
  final DateTime _fechaInicio = DateTime.now();
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("es-ES");
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  /// Estima qué tan bien el niño trazó dentro del área de la letra.
  ///
  /// Enfoque simple y explícitamente permitido por el diseño original:
  /// calculamos el rectángulo que ocupa la letra de fondo (mismo tamaño y
  /// posición con que se dibuja en pantalla) con un margen de tolerancia,
  /// y medimos qué porcentaje de los puntos trazados cae dentro de ese
  /// rectángulo. No es geometría exacta del glifo, pero es una señal
  /// razonable sin tener que rasterizar la fuente pixel por pixel.
  int _calcularPrecision() {
    final puntosValidos = _points.whereType<Offset>().toList();
    if (puntosValidos.isEmpty || _canvasSize == Size.zero) return 0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.letra,
        style: const TextStyle(fontSize: 350, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    const tolerancia = 40.0;
    final letraRect = Rect.fromCenter(
      center: center,
      width: textPainter.width,
      height: textPainter.height,
    ).inflate(tolerancia);

    final dentro = puntosValidos.where((p) => letraRect.contains(p)).length;
    return ((dentro / puntosValidos.length) * 100).round();
  }

  void _finishDrawing() async {
    final precision = _calcularPrecision();

    // Feedback Zen: siempre positivo para el niño, sin importar el
    // resultado real del cálculo. La precisión solo la ve el tutor.
    await flutterTts.speak('¡Muy bien! Letra ${widget.letra}');
    ref.read(progressNotifierProvider.notifier).marcarCompletado(widget.idNivel);

    // Registro para el panel del tutor (Firestore, por cuenta de usuario).
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid != null) {
      ref.read(historialRepositoryProvider).registrarActividad(
            uid,
            ActividadRecord(
              idNivel: widget.idNivel,
              tipo: 'letra',
              titulo: 'Letra ${widget.letra}',
              fechaInicio: _fechaInicio,
              fechaFin: DateTime.now(),
              precision: precision,
            ),
          );
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Logrado!', textAlign: TextAlign.center),
        content: const Icon(Icons.star, color: Colors.amber, size: 80),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra diálogo
              Navigator.pop(context); // Vuelve al menú
            },
            child: const Text('Volver al mapa', style: TextStyle(fontSize: 18)),
          )
        ],
      ),
    );
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
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (context, constraints) {
                // Guardamos el tamaño real del lienzo para poder calcular
                // la precisión más adelante en _finishDrawing().
                _canvasSize = constraints.biggest;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Letra de fondo dinámica
                    Text(
                      widget.letra,
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
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _finishDrawing,
              child: const Text('¡Terminé!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
