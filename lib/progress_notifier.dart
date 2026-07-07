import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProgressNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final box = Hive.box('progressBox');
    final Map<String, bool> progress = {};
    // Cargar progreso previamente guardado
    for (final key in box.keys) {
      progress[key.toString()] = box.get(key) as bool;
    }
    return progress;
  }

  void marcarCompletado(String idNivel) {
    final box = Hive.box('progressBox');
    box.put(idNivel, true);
    // Actualizamos el estado para que toda la app reaccione al instante
    state = {...state, idNivel: true};
  }
}

final progressNotifierProvider = NotifierProvider<ProgressNotifier, Map<String, bool>>(() {
  return ProgressNotifier();
});