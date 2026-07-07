import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_router.dart';
import 'theme_notifier.dart';
import 'progress_notifier.dart';

class StudentMenuScreen extends ConsumerStatefulWidget {
  const StudentMenuScreen({super.key});

  @override
  ConsumerState<StudentMenuScreen> createState() => _StudentMenuScreenState();
}

class _StudentMenuScreenState extends ConsumerState<StudentMenuScreen> {
  final FlutterTts flutterTts = FlutterTts();
  String? _tappedItemId; // Estado local para el feedback visual

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("es-ES");
  }

  void _handleTap(Map<String, dynamic> node, bool isLocked) async {
    if (isLocked || _tappedItemId != null) return;

    // 1. Activar el color verde pastel temporal
    setState(() {
      _tappedItemId = node['id'];
    });

    // 2. Feedback auditivo (TTS)
    await flutterTts.speak(node['title']);

    // 3. Esperar 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() {
      _tappedItemId = null;
    });

    // 4. Navegar a la pantalla correspondiente
    if (node['type'] == 'pic') {
      Navigator.pushNamed(context, AppRouter.pictogramAssociation);
    } else if (node['type'] == 'draw') {
      Navigator.pushNamed(
        context,
        AppRouter.letterDrawing,
        arguments: {'letra': node['letra'], 'idNivel': node['id']},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Nuevos cuentos muy pronto!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeNotifierProvider);
    final progress = ref.watch(progressNotifierProvider);

    // Lista plana de nodos, la alineación dependerá de su tipo
    final nodes = [
      {'id': 'pic_1', 'title': 'Pictogramas 1', 'type': 'pic', 'locked': false},
      {'id': 'draw_A', 'title': 'Letra A', 'type': 'draw', 'locked': false, 'letra': 'A'},
      {'id': 'draw_B', 'title': 'Letra B', 'type': 'draw', 'locked': progress['draw_A'] != true, 'letra': 'B'},
      {'id': 'cuentos_1', 'title': 'Cuentos', 'type': 'story', 'locked': progress['draw_B'] != true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hola!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ir a Configuración (Tutor)',
            onPressed: () => Navigator.pushNamed(context, AppRouter.tutorDashboard),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Línea vertical suave en el fondo para simular el camino
          Positioned(
            top: 0,
            bottom: 0,
            child: Container(
              width: 8,
              color: appTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 40),
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              return _buildNode(context, nodes[index], appTheme.primaryColor, progress);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNode(BuildContext context, Map<String, dynamic> node, Color primaryColor, Map<String, bool> progress) {
    // Alineación según la categoría: Pictogramas (Izquierda), Letras (Centro), Cuentos (Derecha)
    Alignment align;
    if (node['type'] == 'pic') {
      align = Alignment.centerLeft;
    } else if (node['type'] == 'draw') {
      align = Alignment.center;
    } else {
      align = Alignment.centerRight;
    }

    final String id = node['id'] as String;
    final bool isCompleted = progress[id] == true;
    final bool isLocked = node['locked'] as bool;

    Color nodeColor;
    if (_tappedItemId == id) {
      nodeColor = Colors.lightGreen.shade300; // Verde pastel al tocar
    } else if (isCompleted) {
      nodeColor = Colors.green.shade400; // Verde de éxito Zen
    } else if (isLocked) {
      nodeColor = Colors.grey.shade300;
    } else {
      nodeColor = primaryColor;
    }

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        child: InkWell(
          onTap: () => _handleTap(node, isLocked),
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              border: Border.all(
                color: (isCompleted || !isLocked) ? Colors.white : Colors.transparent,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  node['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: (isCompleted || !isLocked) ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}