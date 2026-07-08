import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'story_provider.dart';
import 'pictogram_provider.dart'; // reutiliza pictogramUrlProvider (ARASAAC)
import 'theme_notifier.dart';
import 'auth_repository.dart';
import 'actividad_record.dart';
import 'historial_provider.dart';

class StoryScreen extends ConsumerStatefulWidget {
  final String idNivel;

  const StoryScreen({super.key, required this.idNivel});

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  String? _ultimoTextoLeido;
  final DateTime _fechaInicio = DateTime.now();

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('es-ES');
    Future.microtask(() {
      ref.read(storyProvider.notifier).seleccionarCuento(widget.idNivel);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _leerEnVozAlta(String texto) async {
    if (_ultimoTextoLeido == texto) return;
    _ultimoTextoLeido = texto;
    await _flutterTts.stop();
    await _flutterTts.speak(texto);
  }

  void _mostrarDialogoCierre(BuildContext context, bool acerto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          acerto ? '¡Genial, lo lograste!' : '¡Buen intento!',
          textAlign: TextAlign.center,
        ),
        // Sin colores de alerta ni sonidos de error: mismo cierre cálido
        // se acierte o no (Idea #4: preguntas "Zen" sin castigo).
        content: Icon(
          acerto ? Icons.star_rounded : Icons.favorite_rounded,
          color: acerto ? Colors.amber : Colors.pink.shade200,
          size: 90,
        ),
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
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Vuelve al mapa
            },
            child: const Text('Volver al mapa', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeNotifierProvider);

    // Escucha el momento exacto en que se completa el cuento para
    // mostrar el diálogo de cierre una sola vez.
    ref.listen(storyProvider, (previous, next) {
      if (next.cuentoCompletado && (previous?.cuentoCompletado != true)) {
        final acerto = next.cuento != null &&
            next.respuestaSeleccionada == next.cuento!.preguntaFinal.opcionCorrecta;

        final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
        if (uid != null && next.cuento != null) {
          ref.read(historialRepositoryProvider).registrarActividad(
                uid,
                ActividadRecord(
                  idNivel: next.cuento!.id,
                  tipo: 'cuento',
                  titulo: next.cuento!.titulo,
                  fechaInicio: _fechaInicio,
                  fechaFin: DateTime.now(),
                  // Zen: no castigamos con un número bajo por fallar la
                  // pregunta final, pero sí reflejamos si acertó o no.
                  precision: acerto ? 100 : 60,
                ),
              );
        }

        _mostrarDialogoCierre(context, acerto);
      }
    });

    final state = ref.watch(storyProvider);
    final notifier = ref.read(storyProvider.notifier);

    if (state.cuento == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(state.cuento!.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: state.mostrarPreguntaFinal
            ? _buildPreguntaFinal(context, state, notifier)
            : _buildEscena(context, state, notifier),
      ),
    );
  }

  Widget _buildEscena(BuildContext context, StoryState state, StoryNotifier notifier) {
    final escena = state.escenaActual;
    if (escena == null) return const Center(child: CircularProgressIndicator());

    // Dispara la lectura en voz alta cada vez que cambia el texto de la escena.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leerEnVozAlta(escena.textoCompleto);
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer(builder: (context, ref, _) {
                  final imageUrlAsync = ref.watch(pictogramUrlProvider(escena.pictogramaClave));
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: imageUrlAsync.when(
                      loading: () => const SizedBox(
                        key: ValueKey('loading'),
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, s) => Icon(
                        Icons.auto_stories_rounded,
                        key: ValueKey('error-${escena.id}'),
                        size: 140,
                        color: Colors.grey.shade400,
                      ),
                      data: (url) => url != null
                          ? Image.network(
                              url,
                              key: ValueKey(url),
                              height: 140,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.auto_stories_rounded,
                                size: 140,
                                color: Colors.grey.shade400,
                              ),
                            )
                          : Icon(
                              Icons.auto_stories_rounded,
                              key: ValueKey('null-${escena.id}'),
                              size: 140,
                              color: Colors.grey.shade400,
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
                Text(
                  escena.textoCompleto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        if (escena.decision != null)
          _buildDecision(context, escena.decision!, notifier)
        else
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: notifier.avanzar,
              child: const Text('Continuar', style: TextStyle(fontSize: 20)),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDecision(BuildContext context, dynamic decision, StoryNotifier notifier) {
    return Column(
      children: [
        Text(
          decision.pregunta as String,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDecisionButton(
                context,
                decision.textoOpcionA as String,
                () => notifier.elegirRuta(decision.siguienteEscenaIdA as String),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDecisionButton(
                context,
                decision.textoOpcionB as String,
                () => notifier.elegirRuta(decision.siguienteEscenaIdB as String),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecisionButton(BuildContext context, String texto, VoidCallback onTap) {
    return SizedBox(
      height: 72,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        onPressed: onTap,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPreguntaFinal(BuildContext context, StoryState state, StoryNotifier notifier) {
    final pregunta = state.cuento!.preguntaFinal;
    final opciones = [pregunta.opcionCorrecta, pregunta.opcionIncorrecta]..shuffle();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leerEnVozAlta(pregunta.pregunta);
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_objects_rounded, size: 80, color: Colors.amber),
        const SizedBox(height: 24),
        Text(
          pregunta.pregunta,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        ...opciones.map((opcion) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => notifier.responderPreguntaFinal(opcion),
                  child: Text(opcion, style: const TextStyle(fontSize: 20)),
                ),
              ),
            )),
      ],
    );
  }
}
