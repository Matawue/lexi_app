import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';
import 'actividad_record.dart';
import 'historial_provider.dart';

class TutorStatisticsScreen extends ConsumerWidget {
  const TutorStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(themeNotifierProvider).primaryColor;
    final historialAsync = ref.watch(historialProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Informe Detallado'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: historialAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('No se pudo cargar el historial: $error', textAlign: TextAlign.center),
          ),
        ),
        data: (historial) {
          if (historial.isEmpty) {
            return const _EstadoVacio();
          }
          return _Contenido(historial: historial, primaryColor: primaryColor);
        },
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.query_stats_rounded, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay datos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '¡Que el niño juegue su primera partida para empezar a ver su progreso aquí!',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final List<ActividadRecord> historial;
  final Color primaryColor;

  const _Contenido({required this.historial, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final estaSemana = HistorialMetrics.ultimaSemana(historial);
    final semanaPasada = HistorialMetrics.semanaAnterior(historial);
    final racha = HistorialMetrics.rachaDeDias(historial);
    final precisionPromedio = HistorialMetrics.precisionPromedio(historial);
    final tiempoTotal = HistorialMetrics.tiempoTotal(historial);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildKpiRow(context, historial, precisionPromedio, tiempoTotal, racha),
        const SizedBox(height: 24),
        _buildComparisonCard(context, primaryColor, estaSemana, semanaPasada),
        const SizedBox(height: 24),
        _buildHistoryCard(historial),
      ],
    );
  }

  Widget _buildKpiRow(
    BuildContext context,
    List<ActividadRecord> historial,
    double precisionPromedio,
    Duration tiempoTotal,
    int racha,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = (constraints.maxWidth < 600) ? 2 : 4;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildKPICard('Actividades', '${historial.length}', Icons.check_circle_outline, Colors.green),
          _buildKPICard('Precisión Promedio', '${precisionPromedio.round()}%', Icons.track_changes, Colors.blue),
          _buildKPICard('Tiempo de Uso', '${tiempoTotal.inMinutes} min', Icons.timer_outlined, Colors.orange),
          _buildKPICard('Racha', '$racha día${racha == 1 ? '' : 's'}', Icons.local_fire_department, Colors.deepOrange),
        ],
      );
    });
  }

  Widget _buildKPICard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(icono, size: 32, color: color.withOpacity(0.7)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(titulo, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    Color primaryColor,
    List<ActividadRecord> estaSemana,
    List<ActividadRecord> semanaPasada,
  ) {
    final maxVal = [estaSemana.length, semanaPasada.length, 1].reduce((a, b) => a > b ? a : b);
    final cambio = semanaPasada.isEmpty
        ? (estaSemana.isEmpty ? 0 : 100)
        : (((estaSemana.length - semanaPasada.length) / semanaPasada.length) * 100).round();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actividad Semanal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildProgressBar('Semana Pasada', semanaPasada.length / maxVal, Colors.grey.shade300, '${semanaPasada.length}'),
            const SizedBox(height: 12),
            _buildProgressBar('Esta Semana', estaSemana.length / maxVal, primaryColor, '${estaSemana.length}'),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                cambio >= 0 ? '+$cambio% respecto a la semana pasada' : '$cambio% respecto a la semana pasada',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: cambio >= 0 ? Colors.green : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color, String etiquetaValor) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 16,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: constraints.maxWidth * percentage.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 24, child: Text(etiquetaValor, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildHistoryCard(List<ActividadRecord> historial) {
    final recientes = historial.take(10).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recientes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildHistoryTile(recientes[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(ActividadRecord actividad) {
    final IconData icono;
    final Color color;
    switch (actividad.tipo) {
      case 'letra':
        icono = Icons.edit;
        color = Colors.blue;
        break;
      case 'cuento':
        icono = Icons.auto_stories_rounded;
        color = Colors.deepPurple;
        break;
      case 'pictograma':
      default:
        icono = Icons.image_outlined;
        color = Colors.green;
    }

    final fecha = actividad.fechaInicio;
    final fechaTexto =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} - '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    final duracionTexto = 'Tardó ${actividad.duracion.inSeconds}s';

    return ListTile(
      leading: Icon(icono, color: color),
      title: Text(actividad.titulo),
      subtitle: Text('$fechaTexto · $duracionTexto · Precisión: ${actividad.precision}%'),
      contentPadding: EdgeInsets.zero,
    );
  }
}
