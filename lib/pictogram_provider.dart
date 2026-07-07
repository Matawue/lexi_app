import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pregunta_pictograma.dart';
import 'progress_notifier.dart';
import 'pictogram_dictionary.dart';
import 'arasaac_api_service.dart';

@immutable
class PictogramState {
  final String? levelId;
  final List<PreguntaPictograma> nivelActual;
  final int indicePregunta;
  final Set<String> opcionesIncorrectas;
  final bool mostrarExito;
  final bool nivelCompletado;
  final String? palabraAcertada; // Palabra de la última respuesta correcta

  const PictogramState({
    this.levelId,
    required this.nivelActual,
    required this.indicePregunta,
    this.opcionesIncorrectas = const {},
    this.mostrarExito = false,
    this.nivelCompletado = false,
    this.palabraAcertada,
  });

  // Getter seguro para evitar errores si la lista está vacía
  PreguntaPictograma? get preguntaActual =>
      (nivelActual.isNotEmpty && indicePregunta < nivelActual.length) ? nivelActual[indicePregunta] : null;

  PictogramState copyWith({
    String? levelId,
    int? indicePregunta,
    Set<String>? opcionesIncorrectas,
    bool? mostrarExito,
    bool? nivelCompletado,
    String? palabraAcertada,
  }) {
    return PictogramState(
      levelId: levelId ?? this.levelId,
      nivelActual: nivelActual,
      indicePregunta: indicePregunta ?? this.indicePregunta,
      opcionesIncorrectas: opcionesIncorrectas ?? this.opcionesIncorrectas,
      mostrarExito: mostrarExito ?? this.mostrarExito,
      nivelCompletado: nivelCompletado ?? this.nivelCompletado,
      palabraAcertada: palabraAcertada ?? this.palabraAcertada,
    );
  }
}

class PictogramNotifier extends Notifier<PictogramState> {
  // El diccionario de palabras ahora vive en `pictogram_dictionary.dart`.
  // Los niveles se generan dinámicamente.

  String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  bool _disposed = false;

  @override
  PictogramState build() {
    ref.onDispose(() {
      _disposed = true;
    });
    // El estado inicial es vacío. El nivel se carga a través de `seleccionarNivel`.
    return const PictogramState(
      nivelActual: [],
      indicePregunta: 0,
    );
  }

  void seleccionarNivel(String levelId) {
    // 1. Obtener las 3 palabras para este nivel (de Hive o generando nuevas).
    final palabrasObjetivo = ref.read(progressNotifierProvider.notifier).obtenerPalabrasParaNivel(levelId);
    if (palabrasObjetivo.isEmpty) return;

    final random = Random();
    final List<PreguntaPictograma> nivelData = [];

    // 2. Para cada palabra objetivo, crear una pregunta con 2 opciones falsas.
    for (final palabra in palabrasObjetivo) {
      final Set<String> opciones = {palabra};
      // Añadir 2 opciones incorrectas aleatorias del diccionario.
      while (opciones.length < 3) {
        final opcionAleatoria = kPictogramDictionary[random.nextInt(kPictogramDictionary.length)];
        opciones.add(opcionAleatoria);
      }
      // Mezclar las opciones y capitalizarlas para la UI.
      final listaOpciones = opciones.map(_capitalize).toList();
      listaOpciones.shuffle(random);

      nivelData.add(PreguntaPictograma(
        palabraObjetivo: _capitalize(palabra),
        opciones: listaOpciones,
      ));
    }

    state = PictogramState(
      levelId: levelId,
      nivelActual: nivelData,
      indicePregunta: 0,
    );
  }

  void checkAnswer(String selected) {
    if (state.mostrarExito || state.preguntaActual == null) return;

    if (selected == state.preguntaActual!.palabraObjetivo) {
      // Guardamos la palabra que se acertó y activamos la bandera de éxito.
      state = state.copyWith(
        mostrarExito: true,
        palabraAcertada: state.preguntaActual!.palabraObjetivo,
      );

      // Pausa de 3 segundos (aumentada) para que el niño asimile el acierto.
      Future.delayed(const Duration(seconds: 3), () {
        // La propiedad `mounted` no existe en un Notifier de Riverpod.
        // Usamos una bandera `_disposed` para evitar ejecutar código si el
        // provider ha sido destruido (por ejemplo, si el usuario navegó
        // fuera de la pantalla) y así prevenir errores al usar `ref`
        // después de un `await`.
        if (_disposed) return;

        if (state.indicePregunta == state.nivelActual.length - 1) {
          if (state.levelId != null) {
            ref.read(progressNotifierProvider.notifier).marcarCompletado(state.levelId!);
          }
          state = state.copyWith(nivelCompletado: true);
        } else {
          _siguientePregunta();
        }
      });
    } else {
      state = state.copyWith(opcionesIncorrectas: {...state.opcionesIncorrectas, selected});
    }
  }

  void _siguientePregunta() {
    final nuevoIndice = state.indicePregunta + 1;
    state = state.copyWith(
      indicePregunta: nuevoIndice,
      mostrarExito: false,
      opcionesIncorrectas: {},
    );
  }

  void onDialogDismissed() {
    state = state.copyWith(nivelCompletado: false);
  }
}

/// Provider que gestiona el estado del juego de asociación de pictogramas.
final pictogramProvider = NotifierProvider.autoDispose<PictogramNotifier, PictogramState>(() {
  return PictogramNotifier();
});

/// Provider de solo lectura que obtiene la URL de un pictograma a partir de una palabra.
///
/// Utiliza `.family` para poder pasarle la palabra como parámetro.
/// El resultado es un `AsyncValue<String?>` que maneja los estados de carga,
/// éxito (con la URL o null) y error de forma reactiva y cachea los resultados.
final pictogramUrlProvider = FutureProvider.family<String?, String>((ref, palabra) {
  final apiService = ref.watch(arasaacApiServiceProvider);
  return apiService.obtenerUrlPictogramaPorPalabra(palabra);
});