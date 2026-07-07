import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

import 'pictogram_dictionary.dart';

class ProgressNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final box = Hive.box('lexiBox');
    final Map<String, bool> estadoInicial = {};
    // Filtra de manera segura solo los valores que son booleanos para evitar
    // errores de tipo si la caja contiene otros tipos de datos.
    for (var entry in box.toMap().entries) {
      if (entry.value is bool) {
        estadoInicial[entry.key.toString()] = entry.value as bool;
      }
    }
    return estadoInicial;
  }

  void marcarCompletado(String idNivel) {
    final box = Hive.box('lexiBox');
    box.put(idNivel, true);
    // Actualizamos el estado para que toda la app reaccione al instante
    state = {...state, idNivel: true};
  }

  /// Obtiene una lista de 3 palabras para un nivel de pictogramas.
  ///
  /// Primero, busca si ya existe una ronda guardada para `levelId` en Hive.
  /// Si existe, la devuelve.
  /// Si no, selecciona 3 palabras aleatorias del diccionario, las guarda en Hive
  /// para futuras partidas y las devuelve.
  List<String> obtenerPalabrasParaNivel(String levelId) {
    // Usar una caja separada para las rondas para no mezclar tipos de datos.
    final box = Hive.box('rondasBox');
    // Usamos un prefijo para no colisionar con las claves de progreso.
    final roundKey = 'round_$levelId';

    final List<dynamic>? palabrasGuardadas = box.get(roundKey);

    if (palabrasGuardadas != null && palabrasGuardadas.isNotEmpty) {
      return palabrasGuardadas.cast<String>();
    } else {
      final random = Random();
      final Set<String> palabrasNuevas = {};
      while (palabrasNuevas.length < 3) {
        palabrasNuevas.add(kPictogramDictionary[random.nextInt(kPictogramDictionary.length)]);
      }
      final listaPalabras = palabrasNuevas.toList();
      box.put(roundKey, listaPalabras);
      return listaPalabras;
    }
  }
}

final progressNotifierProvider = NotifierProvider<ProgressNotifier, Map<String, bool>>(() {
  return ProgressNotifier();
});