import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ArasaacApiService {
  final String _baseUrl = 'https://api.arasaac.org/v1';

  /// Realiza una búsqueda de un pictograma por palabra clave en español y devuelve la URL de la imagen.
  ///
  /// Consume el endpoint de búsqueda de ARASAAC, extrae el ID del primer resultado
  /// y construye la URL final para obtener la imagen del pictograma.
  Future<String?> obtenerUrlPictogramaPorPalabra(String palabra) async {
    try {
      // 1. Construir la URL para la búsqueda de texto en español ('es').
      // Se usa el endpoint `/pictograms/{language}/search/{searchText}` como indica la documentación.
      // Se convierte a minúsculas para una búsqueda más consistente.
      final searchUrl = Uri.parse('$_baseUrl/pictograms/es/search/${palabra.toLowerCase()}');
      final response = await http.get(searchUrl);

      // 2. Procesar la respuesta si la petición fue exitosa (código 200).
      if (response.statusCode == 200) {
        final List<dynamic> pictograms = json.decode(response.body);
        if (pictograms.isNotEmpty) {
          // 3. Extraer el ID del primer pictograma encontrado.
          final int pictogramId = pictograms.first['_id'];
          // 4. Retornar la URL directa de la imagen, formateada como `.../pictograms/{id}`.
          return '$_baseUrl/pictograms/$pictogramId';
        }
      }
      // Si no hay resultados o la respuesta no es 200, retorna null.
      return null;
    } catch (e) {
      // 5. Manejar cualquier error (red, parsing, etc.) de forma segura, retornando null
      // para no interrumpir la aplicación.
      return null;
    }
  }
}

final arasaacApiServiceProvider = Provider<ArasaacApiService>((ref) {
  return ArasaacApiService();
});