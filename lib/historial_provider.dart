import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'actividad_record.dart';
import 'auth_repository.dart';

/// Repositorio delgado sobre Firestore. Cada usuario tiene su propia
/// subcolección `users/{uid}/actividades`, así que el historial de un niño
/// nunca se mezcla con el de otra cuenta y viaja con la cuenta entre
/// dispositivos (a diferencia de Hive, que es solo local).
class HistorialRepository {
  final FirebaseFirestore _firestore;
  HistorialRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _coleccion(String uid) {
    return _firestore.collection('users').doc(uid).collection('actividades');
  }

  Future<void> registrarActividad(String uid, ActividadRecord record) {
    return _coleccion(uid).add(record.toMap());
  }

  Stream<List<ActividadRecord>> observarHistorial(String uid) {
    return _coleccion(uid)
        .orderBy('fechaInicio', descending: true)
        .limit(200) // suficiente para calcular métricas sin traer todo el histórico
        .snapshots()
        .map((snap) => snap.docs.map((d) => ActividadRecord.fromMap(d.data(), d.id)).toList());
  }
}

final historialRepositoryProvider = Provider<HistorialRepository>((ref) {
  return HistorialRepository(FirebaseFirestore.instance);
});

/// Stream reactivo del historial del usuario actualmente autenticado.
/// Si no hay usuario logueado, devuelve una lista vacía en vez de fallar.
final historialProvider = StreamProvider.autoDispose<List<ActividadRecord>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(const <ActividadRecord>[]);

  return ref.watch(historialRepositoryProvider).observarHistorial(user.uid);
});

/// Funciones de métricas puras (fáciles de testear, no dependen de Firestore
/// directamente) que la pantalla del tutor usa para transformar la lista
/// cruda de actividades en indicadores legibles.
class HistorialMetrics {
  static List<ActividadRecord> actividadesEnRango(
    List<ActividadRecord> historial,
    DateTime desde,
    DateTime hasta,
  ) {
    return historial.where((a) => a.fechaInicio.isAfter(desde) && a.fechaInicio.isBefore(hasta)).toList();
  }

  static List<ActividadRecord> ultimaSemana(List<ActividadRecord> historial) {
    final ahora = DateTime.now();
    return actividadesEnRango(historial, ahora.subtract(const Duration(days: 7)), ahora);
  }

  static List<ActividadRecord> semanaAnterior(List<ActividadRecord> historial) {
    final ahora = DateTime.now();
    return actividadesEnRango(
      historial,
      ahora.subtract(const Duration(days: 14)),
      ahora.subtract(const Duration(days: 7)),
    );
  }

  static double precisionPromedio(List<ActividadRecord> actividades) {
    if (actividades.isEmpty) return 0;
    final suma = actividades.fold<int>(0, (acc, a) => acc + a.precision);
    return suma / actividades.length;
  }

  static Duration tiempoTotal(List<ActividadRecord> actividades) {
    return actividades.fold<Duration>(Duration.zero, (acc, a) => acc + a.duracion);
  }

  static Duration tiempoPromedio(List<ActividadRecord> actividades) {
    if (actividades.isEmpty) return Duration.zero;
    return tiempoTotal(actividades) ~/ actividades.length;
  }

  /// Racha de días consecutivos (incluyendo hoy si ya jugó) con al menos
  /// una actividad registrada. Se detiene en el primer día sin actividad.
  static int rachaDeDias(List<ActividadRecord> historial) {
    if (historial.isEmpty) return 0;

    final diasConActividad = historial.map((a) {
      final f = a.fechaInicio;
      return DateTime(f.year, f.month, f.day);
    }).toSet();

    int racha = 0;
    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    // Si hoy no jugó, la racha "activa" empieza a contar desde ayer
    // (no penalizamos al niño solo porque aún no ha abierto la app hoy).
    if (!diasConActividad.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (diasConActividad.contains(cursor)) {
      racha++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return racha;
  }
}
