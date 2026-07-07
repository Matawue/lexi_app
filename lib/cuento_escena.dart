import 'package:flutter/foundation.dart';

/// Una decisión de ruta única al final de una escena (Idea #2 del equipo:
/// "Cuentos Ramificados de Elección Única"). Sin cronómetro, sin presión:
/// el niño elige a su propio ritmo entre dos caminos con icono.
@immutable
class DecisionCuento {
  final String pregunta;
  final String textoOpcionA;
  final String iconoOpcionA; // palabra clave para buscar pictograma ARASAAC
  final String siguienteEscenaIdA;
  final String textoOpcionB;
  final String iconoOpcionB;
  final String siguienteEscenaIdB;

  const DecisionCuento({
    required this.pregunta,
    required this.textoOpcionA,
    required this.iconoOpcionA,
    required this.siguienteEscenaIdA,
    required this.textoOpcionB,
    required this.iconoOpcionB,
    required this.siguienteEscenaIdB,
  });
}

/// Una sola escena del cuento. El texto se guarda ya separado en palabras
/// para que la pantalla pueda resaltarlas una a una en sincronía con el TTS
/// (Idea #1: "Lectura Dual" / efecto karaoke), sin tener que hacer parsing
/// de strings en tiempo real dentro del widget.
@immutable
class CuentoEscena {
  final String id;
  final List<String> palabras;
  final String pictogramaClave; // palabra usada para pedir el pictograma a ARASAAC
  final String? imagenFondo; // asset local opcional para la ilustración de fondo
  final DecisionCuento? decision; // null = escena final o lineal, avanza sola
  final String? siguienteEscenaId; // usado solo si no hay `decision`

  const CuentoEscena({
    required this.id,
    required this.palabras,
    required this.pictogramaClave,
    this.imagenFondo,
    this.decision,
    this.siguienteEscenaId,
  });

  String get textoCompleto => palabras.join(' ');

  bool get esFinal => decision == null && siguienteEscenaId == null;
}

/// Una pregunta "Zen" de comprensión al cierre del cuento (Idea #4):
/// dos opciones grandes, sin colores de alerta, sin sonido de error.
@immutable
class PreguntaZen {
  final String pregunta;
  final String opcionCorrecta;
  final String opcionIncorrecta;

  const PreguntaZen({
    required this.pregunta,
    required this.opcionCorrecta,
    required this.opcionIncorrecta,
  });
}

/// La plantilla completa de un cuento: un grafo de escenas identificadas
/// por id, más metadatos y la pregunta de cierre.
@immutable
class StoryTemplate {
  final String id;
  final String titulo;
  final String escenaInicialId;
  final Map<String, CuentoEscena> escenas;
  final PreguntaZen preguntaFinal;

  const StoryTemplate({
    required this.id,
    required this.titulo,
    required this.escenaInicialId,
    required this.escenas,
    required this.preguntaFinal,
  });

  CuentoEscena escena(String id) {
    final escena = escenas[id];
    assert(escena != null, 'Escena "$id" no existe en el cuento "$id"');
    return escena!;
  }
}
