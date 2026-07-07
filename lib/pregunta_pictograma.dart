import 'package:flutter/foundation.dart';

@immutable
class PreguntaPictograma {
  final String palabraObjetivo;
  final List<String> opciones;
  final String? imagenUrl;

  const PreguntaPictograma({
    required this.palabraObjetivo,
    required this.opciones,
    this.imagenUrl,
  });

  PreguntaPictograma copyWith({
    String? palabraObjetivo,
    List<String>? opciones,
    String? imagenUrl,
  }) {
    return PreguntaPictograma(
        palabraObjetivo: palabraObjetivo ?? this.palabraObjetivo,
        opciones: opciones ?? this.opciones,
        imagenUrl: imagenUrl ?? this.imagenUrl);
  }
}