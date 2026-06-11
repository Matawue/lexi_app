import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'theme_notifier.dart';

class StudentMenuScreen extends ConsumerWidget {
  const StudentMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Al observar el tema nos aseguramos de que toda la pantalla reaccione a cambios
    ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hola!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ir a Configuración (Tutor)',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.tutorDashboard);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMenuButton(context, 'Asociar Palabras', () {
                Navigator.pushNamed(context, AppRouter.pictogramAssociation);
              }),
              const SizedBox(height: 24),
              _buildMenuButton(context, 'Dibujar Letras', () {
                Navigator.pushNamed(context, AppRouter.letterDrawing);
              }),
              const SizedBox(height: 24),
              _buildMenuButton(context, 'Cuentos', () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
      ),
      onPressed: onPressed,
      child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }
}