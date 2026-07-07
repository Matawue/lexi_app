import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';
import 'progress_notifier.dart';

class Pregunta {
  final IconData icono;
  final String palabraCorrecta;
  final List<String> opciones;

  Pregunta(this.icono, this.palabraCorrecta, this.opciones);
}

class PictogramAssociationScreen extends ConsumerStatefulWidget {
  const PictogramAssociationScreen({super.key});

  @override
  ConsumerState<PictogramAssociationScreen> createState() =>
      _PictogramAssociationScreenState();
}

class _PictogramAssociationScreenState
    extends ConsumerState<PictogramAssociationScreen> {
  int indiceActual = 0;
  final Set<String> _opcionesIncorrectas = {};
  bool _mostrarExito = false;

  final List<Pregunta> _preguntas = [
    Pregunta(Icons.pets, 'Perro', ['Gato', 'Perro', 'Pájaro']),
    Pregunta(Icons.home, 'Casa', ['Escuela', 'Casa', 'Hospital']),
    Pregunta(Icons.star, 'Estrella', ['Luna', 'Sol', 'Estrella']),
  ];

  void _checkAnswer(String selected) {
    if (_mostrarExito) return; // Evitar múltiples clics

    if (selected == _preguntas[indiceActual].palabraCorrecta) {
      setState(() {
        _mostrarExito = true;
      });

      // Aumentamos el tiempo a 2.5 segundos para que el niño alcance a leer el mensaje
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;

        if (indiceActual == _preguntas.length - 1) {
          // Marcar como superado el Nivel 1
          ref.read(progressNotifierProvider.notifier).marcarCompletado('pic_1');
          _showCompletionDialog();
        } else {
          setState(() {
            indiceActual++;
            _mostrarExito = false;
            _opcionesIncorrectas.clear();
          });
        }
      });
    } else {
      setState(() {
        _opcionesIncorrectas.add(selected);
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('¡Buen trabajo!', textAlign: TextAlign.center),
          content: const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 100,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.pop(context); // Vuelve al mapa
              },
              child: const Text(
                'Volver al mapa',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeNotifierProvider);
    final currentQuestion = _preguntas[indiceActual];

    return Scaffold(
      appBar: AppBar(title: const Text('Asociar Palabras')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Barra de progreso redondeada y gruesa
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value:
                    (indiceActual) / _preguntas.length, // Se llena gradualmente
                minHeight: 16,
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: Icon(
                        currentQuestion.icono,
                        key: ValueKey<int>(indiceActual),
                        size: 150,
                        // Si es correcto brilla sutilmente en verde pastel, si no, usa el color primario
                        color: _mostrarExito
                            ? Colors.lightGreen
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Mensaje de refuerzo que confirma cuál era la palabra correcta
                    AnimatedOpacity(
                      opacity: _mostrarExito ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        '¡Excelente! Era "${currentQuestion.palabraCorrecta}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF43A047), // Verde legible y amigable
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: currentQuestion.opciones.map((opcion) {
                return _buildOptionButton(
                  context,
                  opcion,
                  currentQuestion.palabraCorrecta,
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String opcion,
    String palabraCorrecta,
  ) {
    final bool esIncorrecta = _opcionesIncorrectas.contains(opcion);
    final bool esCorrectaSeleccionada =
        _mostrarExito && opcion == palabraCorrecta;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Opacity(
          opacity: esIncorrecta
              ? 0.3
              : 1.0, // Deshabilitar visualmente sin usar rojo
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Menos padding lateral para dejar espacio a la fuente ancha
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // Verde pastel si es correcto, si no, primaryColor
              backgroundColor: esCorrectaSeleccionada
                  ? Colors.lightGreen.shade300
                  : Theme.of(context).primaryColor,
              foregroundColor:
                  Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
            ),
            onPressed: (esIncorrecta || _mostrarExito)
                ? null
                : () => _checkAnswer(opcion),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                opcion,
                textAlign: TextAlign.center,
                maxLines:
                    1, // Fuerza a que la palabra completa se mantenga en una sola línea
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
