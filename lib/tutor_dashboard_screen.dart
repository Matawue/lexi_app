import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';
import 'app_theme.dart';
import 'auth_repository.dart';
import 'app_router.dart';
import 'historial_provider.dart';

class TutorDashboardScreen extends ConsumerWidget {
  const TutorDashboardScreen({super.key});

  String _currentPalette(AppTheme theme) {
    if (theme.backgroundColor == Colors.black) return 'high_contrast';
    if (theme.backgroundColor == const Color(0xFFF0F8FF)) return 'calm_blue';
    return 'default';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeNotifierProvider);
    final historialAsync = ref.watch(historialProvider);
    final currentPalette = _currentPalette(appTheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Tutor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Configuración Sensorial',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Usar fuente para dislexia'),
            value: appTheme.fontFamily == 'OpenDyslexic',
            onChanged: (value) {
              ref.read(themeNotifierProvider.notifier).toggleDyslexicFont(value);
            },
          ),
          const Divider(),
          const Text('Paleta de Colores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          RadioListTile<String>(
            title: const Text('Por Defecto'),
            value: 'default',
            groupValue: currentPalette,
            onChanged: (val) => ref.read(themeNotifierProvider.notifier).applyStudentPreferences(val!),
          ),
          RadioListTile<String>(
            title: const Text('Azul Calmante (Bajo estrés)'),
            value: 'calm_blue',
            groupValue: currentPalette,
            onChanged: (val) => ref.read(themeNotifierProvider.notifier).applyStudentPreferences(val!),
          ),
          RadioListTile<String>(
            title: const Text('Alto Contraste'),
            value: 'high_contrast',
            groupValue: currentPalette,
            onChanged: (val) => ref.read(themeNotifierProvider.notifier).applyStudentPreferences(val!),
          ),
          const SizedBox(height: 30),
          const Text(
            'Métricas de Progreso',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          historialAsync.when(
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator())),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (historial) {
                final precisionPromedio =
                    HistorialMetrics.precisionPromedio(historial);
                final tiempoTotal = HistorialMetrics.tiempoTotal(historial);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = (constraints.maxWidth < 600) ? 2 : 3;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildKPICard(
                          'Actividades Totales',
                          '${historial.length}',
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                        _buildKPICard(
                          'Precisión Promedio',
                          '${precisionPromedio.round()}%',
                          Icons.track_changes,
                          Colors.blue,
                        ),
                        _buildKPICard(
                          'Tiempo de Uso',
                          '${tiempoTotal.inMinutes} min',
                          Icons.timer_outlined,
                          Colors.orange,
                        ),
                      ],
                    );
                  },
                );
              }),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: const Text('Ver Informe Detallado'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.tutorStatistics);
            },
          ),
        ],
      ),
    );
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
                  Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // Para evitar el desbordamiento, envolvemos el texto en Flexible y FittedBox.
                  // Flexible permite que el widget ocupe el espacio restante.
                  // FittedBox reduce el tamaño de la fuente si el texto es demasiado largo para el espacio.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(titulo, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
}