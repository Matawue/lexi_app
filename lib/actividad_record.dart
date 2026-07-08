import 'package:cloud_firestore/cloud_firestore.dart';

/// Un registro de una actividad completada (pictograma, letra o cuento),
/// pensado para vivir en Firestore bajo `users/{uid}/actividades/{id}`.
///
/// Guardamos `fechaInicio` y `fechaFin` (no solo una fecha) para poder
/// calcular la duración real de cada actividad y así medir fluidez
/// (¿el niño resuelve más rápido con el tiempo?).
class ActividadRecord {
  final String? id; // null hasta que Firestore le asigna uno al guardar
  final String idNivel; // ej. 'pic_2', 'draw_B', 'cuentos_1'
  final String tipo; // 'pictograma' | 'letra' | 'cuento'
  final String titulo; // texto amigable para mostrar en el historial
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int precision; // 0-100. 100 si no aplica un cálculo real (pictogramas).
  final bool completado;

  const ActividadRecord({
    this.id,
    required this.idNivel,
    required this.tipo,
    required this.titulo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.precision,
    this.completado = true,
  });

  Duration get duracion => fechaFin.difference(fechaInicio);

  Map<String, dynamic> toMap() => {
        'idNivel': idNivel,
        'tipo': tipo,
        'titulo': titulo,
        'fechaInicio': Timestamp.fromDate(fechaInicio),
        'fechaFin': Timestamp.fromDate(fechaFin),
        'precision': precision,
        'completado': completado,
      };

  factory ActividadRecord.fromMap(Map<String, dynamic> map, String id) {
    return ActividadRecord(
      id: id,
      idNivel: map['idNivel'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'otro',
      titulo: map['titulo'] as String? ?? '',
      // Fallbacks defensivos: si algún documento viejo/corrupto no tiene
      // estos campos, no queremos que toda la pantalla del tutor truene.
      fechaInicio: (map['fechaInicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaFin: (map['fechaFin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      precision: map['precision'] as int? ?? 0,
      completado: map['completado'] as bool? ?? true,
    );
  }
}
