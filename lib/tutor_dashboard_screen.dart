import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';
import 'app_theme.dart';

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
    final currentPalette = _currentPalette(appTheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Tutor'),
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
        ],
      ),
    );
  }
}