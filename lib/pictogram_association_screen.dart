import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importamos el nuevo provider que controla la lógica del juego
import 'pictogram_provider.dart';
import 'theme_notifier.dart';
import 'auth_repository.dart';
import 'actividad_record.dart';
import 'historial_provider.dart';

class PictogramAssociationScreen extends ConsumerStatefulWidget {
  final String levelId;
  const PictogramAssociationScreen({super.key, required this.levelId});

  @override
  ConsumerState<PictogramAssociationScreen> createState() => _PictogramAssociationScreenState();
}

class _PictogramAssociationScreenState extends ConsumerState<PictogramAssociationScreen> {
  // Marca cuándo empezó la ronda, para poder medir fluidez (tiempo de
  // resolución) en el historial del tutor.
  final DateTime _fechaInicio = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Usamos un microtask para asegurarnos de que el ref esté disponible.
    Future.microtask(() {
      ref.read(pictogramProvider.notifier).seleccionarNivel(widget.levelId);
    });
  }

  void _showCompletionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¡Buen trabajo!', textAlign: TextAlign.center),
          content: const Icon(Icons.star_rounded, color: Colors.amber, size: 100),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ref.read(pictogramProvider.notifier).onDialogDismissed();
                Navigator.pop(context); // Cierra el diálogo
                Navigator.pop(context); // Vuelve al mapa
              },
              child: const Text('Volver al mapa', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos cambios en el estado para mostrar el diálogo de completado
    // sin reconstruir el widget innecesariamente.
    ref.listen(pictogramProvider, (previous, next) {
      if (next.nivelCompletado && (previous?.nivelCompletado == false)) {
        final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
        if (uid != null) {
          ref.read(historialRepositoryProvider).registrarActividad(
                uid,
                ActividadRecord(
                  idNivel: next.levelId ?? widget.levelId,
                  tipo: 'pictograma',
                  titulo: 'Pictogramas ${(next.levelId ?? widget.levelId).split('_').last}',
                  fechaInicio: _fechaInicio,
                  fechaFin: DateTime.now(),
                  precision: 100, // acertó las 3 palabras sin límite de intentos por pregunta
                ),
              );
        }
        _showCompletionDialog(context, ref);
      }
    });

    // Observamos el estado para reconstruir la UI cuando sea necesario.
    final gameState = ref.watch(pictogramProvider);
    final notifier = ref.read(pictogramProvider.notifier);
    ref.watch(themeNotifierProvider);

    // Si el nivel aún no se ha cargado, muestra un indicador de carga.
    if (gameState.preguntaActual == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asociar Palabras')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                value: (gameState.indicePregunta) / gameState.nivelActual.length,
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
                    Consumer(builder: (context, ref, _) {
                      final palabra = gameState.preguntaActual!.palabraObjetivo;
                      final imageUrlAsync = ref.watch(pictogramUrlProvider(palabra));

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: imageUrlAsync.when(
                          loading: () => SizedBox(
                            key: const ValueKey('loading'),
                            height: 150,
                            child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                          ),
                          error: (e, s) => Icon(
                            Icons.image_not_supported_outlined,
                            key: ValueKey<int>(gameState.indicePregunta),
                            size: 150,
                            color: Colors.grey.shade400,
                          ),
                          data: (imageUrl) => imageUrl != null
                              ? ColorFiltered(
                                  key: ValueKey<String>(imageUrl),
                                  colorFilter: ColorFilter.mode(
                                    gameState.mostrarExito ? Colors.lightGreen.withOpacity(0.5) : Colors.transparent,
                                    BlendMode.color,
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    height: 150,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 150,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.question_mark_rounded,
                                  key: ValueKey<int>(gameState.indicePregunta),
                                  size: 150,
                                  color: Colors.grey.shade400,
                                ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Reemplazamos AnimatedOpacity con Visibility para que el mensaje desaparezca
                    // instantáneamente al cambiar de pregunta, evitando el "spoiler".
                    Visibility(
                      visible: gameState.mostrarExito,
                      maintainState: true, // Mantiene el estado para evitar saltos de layout
                      maintainAnimation: true,
                      maintainSize: true,
                      child: Text(
                        '¡Excelente! Era "${gameState.palabraAcertada ?? ''}"',
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
              children: gameState.preguntaActual!.opciones.map((opcion) {
                return _buildOptionButton(
                  context,
                  opcion,
                  gameState,
                  notifier,
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
    PictogramState gameState,
    PictogramNotifier notifier,
  ) {
    final bool esIncorrecta = gameState.opcionesIncorrectas.contains(opcion);
    final bool esCorrectaSeleccionada =
        gameState.mostrarExito && opcion == gameState.preguntaActual!.palabraObjetivo;

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
            onPressed: (esIncorrecta || gameState.mostrarExito)
                ? null
                : () => notifier.checkAnswer(opcion),
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
