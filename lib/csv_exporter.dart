import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'actividad_record.dart';

/// Genera un CSV del historial de actividades y lo comparte usando el
/// selector nativo (email, Drive, WhatsApp, guardar en archivos, etc.),
/// para que el tutor/fonoaudiólogo pueda abrirlo en Excel o imprimirlo.
class CsvExporter {
  static String _escaparCsv(String valor) {
    // Regla estándar de CSV: si el texto trae coma, comillas o salto de
    // línea, hay que encerrarlo en comillas y escapar las comillas internas.
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }

  static String generarCsv(List<ActividadRecord> historial) {
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Hora,Tipo,Actividad,Duración (s),Precisión (%)');

    // El historial viene ordenado del más reciente al más antiguo; para un
    // reporte es más natural leerlo en orden cronológico ascendente.
    final ordenado = historial.reversed.toList();

    for (final actividad in ordenado) {
      final f = actividad.fechaInicio;
      final fecha = '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
      final hora = '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

      buffer.writeln([
        fecha,
        hora,
        _escaparCsv(actividad.tipo),
        _escaparCsv(actividad.titulo),
        actividad.duracion.inSeconds.toString(),
        actividad.precision.toString(),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Escribe el CSV en un archivo temporal y abre el selector nativo para
  /// compartirlo o guardarlo. Lanza una excepción si algo falla, para que
  /// la UI pueda mostrar un mensaje de error.
  static Future<void> exportarYCompartir(List<ActividadRecord> historial) async {
    final csv = generarCsv(historial);
    final directorio = await getTemporaryDirectory();

    final ahora = DateTime.now();
    final sufijo =
        '${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}';
    final archivo = File('${directorio.path}/reporte_lexi_$sufijo.csv');
    await archivo.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(archivo.path)],
      subject: 'Reporte de progreso - Lexi App',
      text: 'Reporte de actividades generado el '
          '${ahora.day}/${ahora.month}/${ahora.year}.',
    );
  }
}
