import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cuento_escena.dart';
import 'story_generator.dart';
import 'progress_notifier.dart';

@immutable
class StoryState {
  final StoryTemplate? cuento;
  final String? escenaActualId;
  final bool mostrarPreguntaFinal;
  final bool cuentoCompletado;
  final String? respuestaSeleccionada;

  const StoryState({
    this.cuento,
    this.escenaActualId,
    this.mostrarPreguntaFinal = false,
    this.cuentoCompletado = false,
    this.respuestaSeleccionada,
  });

  // Getter seguro: evita null-check en cada pantalla si el cuento aún no cargó.
  CuentoEscena? get escenaActual {
    if (cuento == null || escenaActualId == null) return null;
    return cuento!.escenas[escenaActualId];
  }

  StoryState copyWith({
    StoryTemplate? cuento,
    String? escenaActualId,
    bool? mostrarPreguntaFinal,
    bool? cuentoCompletado,
    String? respuestaSeleccionada,
  }) {
    return StoryState(
      cuento: cuento ?? this.cuento,
      escenaActualId: escenaActualId ?? this.escenaActualId,
      mostrarPreguntaFinal: mostrarPreguntaFinal ?? this.mostrarPreguntaFinal,
      cuentoCompletado: cuentoCompletado ?? this.cuentoCompletado,
      respuestaSeleccionada: respuestaSeleccionada ?? this.respuestaSeleccionada,
    );
  }
}

class StoryNotifier extends Notifier<StoryState> {
  @override
  StoryState build() {
    // Estado vacío inicial. El cuento se genera con `seleccionarCuento`.
    return const StoryState();
  }

  /// Genera (o regenera) el cuento asociado a un nivel y lo deja listo
  /// en su escena inicial.
  void seleccionarCuento(String levelId) {
    final cuento = StoryGenerator.generar(levelId);
    state = StoryState(
      cuento: cuento,
      escenaActualId: cuento.escenaInicialId,
    );
  }

  /// Avanza a la siguiente escena en cuentos lineales (sin decisión).
  void avanzar() {
    final escena = state.escenaActual;
    if (escena == null) return;

    if (escena.siguienteEscenaId != null) {
      state = state.copyWith(escenaActualId: escena.siguienteEscenaId);
    } else if (escena.esFinal) {
      state = state.copyWith(mostrarPreguntaFinal: true);
    }
  }

  /// El niño elige una ruta en una escena con decisión (Idea #2).
  void elegirRuta(String siguienteEscenaId) {
    state = state.copyWith(escenaActualId: siguienteEscenaId);
  }

  /// Registra la respuesta a la pregunta "Zen" final (Idea #4: sin castigo).
  /// Si acierta, marca el nivel como completado para desbloquear la
  /// recompensa en el Jardín de Mascotas.
  void responderPreguntaFinal(String respuesta) {
    final cuento = state.cuento;
    if (cuento == null) return;

    state = state.copyWith(respuestaSeleccionada: respuesta);

    final acerto = respuesta == cuento.preguntaFinal.opcionCorrecta;
    if (acerto) {
      ref.read(progressNotifierProvider.notifier).marcarCompletado(cuento.id);
    }
    // Independiente del acierto, mostramos el cierre sin penalización visual.
    state = state.copyWith(cuentoCompletado: true);
  }

  void reiniciar() {
    final cuento = state.cuento;
    if (cuento == null) return;
    state = StoryState(cuento: cuento, escenaActualId: cuento.escenaInicialId);
  }
}

final storyProvider = NotifierProvider.autoDispose<StoryNotifier, StoryState>(() {
  return StoryNotifier();
});