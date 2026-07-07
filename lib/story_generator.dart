import 'dart:math';

import 'cuento_escena.dart';

/// Genera cuentos combinando piezas reusables (personaje + escenario + objeto)
/// sobre un esqueleto narrativo fijo. No usa IA ni internet: es determinista
/// por semilla, así que el mismo `levelId` siempre arma el mismo cuento
/// (importante para no romper el seguimiento de progreso del tutor), pero
/// cambiando el `levelId` obtienes una combinación distinta.
///
/// Pensado para frases cortas y bajo estrés cognitivo (CEA / dislexia):
/// máximo 6-8 palabras por escena, sin cronómetros, sin vocabulario denso.
class StoryGenerator {
  static const List<String> _personajes = ['El perro', 'La gata', 'El conejo', 'La tortuga'];
  static const List<String> _clavePersonaje = ['perro', 'gato', 'conejo', 'tortuga'];

  static const List<String> _objetos = ['una pelota', 'una flor', 'una estrella', 'un globo'];
  static const List<String> _claveObjeto = ['pelota', 'flor', 'estrella', 'globo'];

  /// Genera un [StoryTemplate] completo a partir de un [seed] textual
  /// (normalmente el `levelId`, ej. "cuento_1"). Misma seed -> mismo cuento.
  static StoryTemplate generar(String seed) {
    final random = Random(seed.hashCode);

    final personajeIdx = random.nextInt(_personajes.length);
    final objetoIdx = random.nextInt(_objetos.length);

    final personaje = _personajes[personajeIdx];
    final clavePersonaje = _clavePersonaje[personajeIdx];
    final objeto = _objetos[objetoIdx];
    final claveObjeto = _claveObjeto[objetoIdx];

    final escenas = <String, CuentoEscena>{
      'inicio': CuentoEscena(
        id: 'inicio',
        palabras: '$personaje encontró $objeto en el jardín.'.split(' '),
        pictogramaClave: clavePersonaje,
        siguienteEscenaId: 'decision_camino',
      ),
      'decision_camino': CuentoEscena(
        id: 'decision_camino',
        palabras: '$personaje quiere seguir un camino.'.split(' '),
        pictogramaClave: claveObjeto,
        decision: const DecisionCuento(
          pregunta: '¿Qué camino elige?',
          textoOpcionA: 'Camino del bosque',
          iconoOpcionA: 'bosque',
          siguienteEscenaIdA: 'final_bosque',
          textoOpcionB: 'Camino de la casa',
          iconoOpcionB: 'casa',
          siguienteEscenaIdB: 'final_casa',
        ),
      ),
      'final_bosque': CuentoEscena(
        id: 'final_bosque',
        palabras: '$personaje llegó al bosque y jugó feliz.'.split(' '),
        pictogramaClave: 'bosque',
      ),
      'final_casa': CuentoEscena(
        id: 'final_casa',
        palabras: '$personaje llegó a casa y descansó feliz.'.split(' '),
        pictogramaClave: 'casa',
      ),
    };

    return StoryTemplate(
      id: seed,
      titulo: '$personaje y $objeto',
      escenaInicialId: 'inicio',
      escenas: escenas,
      preguntaFinal: PreguntaZen(
        pregunta: '¿Qué encontró $personaje?',
        opcionCorrecta: objeto,
        opcionIncorrecta: _objetos[(objetoIdx + 1) % _objetos.length],
      ),
    );
  }
}
