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
      Navigator.pushNamed(
        context,
        AppRouter.pictogramAssociation,
        arguments: {'levelId': node['id']},
      );
    } else if (node['type'] == 'draw') {
      Navigator.pushNamed(
        context,
        AppRouter.letterDrawing,
        arguments: {'letra': node['letra'], 'idNivel': node['id']},
      );
    } else if (node['type'] == 'story') {
      Navigator.pushNamed(
        context,
        AppRouter.story,
        arguments: {'idNivel': node['id']},
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

    // Generación dinámica de nodos para un camino de aprendizaje infinito.

    // 1. Generar nodos de pictogramas. Siempre muestra todos los completados
    //    y el siguiente nivel bloqueado.
    final List<Map<String, dynamic>> pictogramNodes = [];
    int currentPicLevel = 1;
    while (true) {
      final levelId = 'pic_$currentPicLevel';
      final prevLevelId = 'pic_${currentPicLevel - 1}';
      final isLocked = (currentPicLevel > 1) && (progress[prevLevelId] != true);

      pictogramNodes.add({
        'id': levelId,
        'title': 'Pictogramas $currentPicLevel',
        'type': 'pic',
        'locked': isLocked,
      });

      // Si el nivel actual no está completado, hemos añadido el siguiente
      // nivel disponible y podemos parar.
      if (progress[levelId] != true) break;
      currentPicLevel++;
    }

    // 2. Generar nodos de trazado de letras para todo el abecedario.
    final List<Map<String, dynamic>> drawingNodes = [];
    const abecedario = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < abecedario.length; i++) {
      final letra = abecedario[i];
      final idNivel = 'draw_$letra';
      // La primera letra ('A') no está bloqueada. Las demás dependen de la anterior.
      final idNivelAnterior = i > 0 ? 'draw_${abecedario[i - 1]}' : null;
      final isLocked = (idNivelAnterior != null) && (progress[idNivelAnterior] != true);

      drawingNodes.add({
        'id': idNivel,
        'title': 'Letra $letra',
        'type': 'draw',
        'locked': isLocked,
        'letra': letra,
      });
    }

    // 3. Combinar todos los nodos para construir el menú.
    final nodes = [
      ...pictogramNodes,
      ...drawingNodes,
      {'id': 'cuentos_1', 'title': 'Cuentos', 'type': 'story', 'locked': progress['draw_Z'] != true},
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
          LayoutBuilder(builder: (context, constraints) {
            // Usar un layout diferente para pantallas anchas (tablets, web)
            if (constraints.maxWidth > 600) {
              return _buildWideLayout(context, nodes, appTheme.primaryColor, progress);
            } else {
              return _buildNarrowLayout(context, nodes, appTheme.primaryColor, progress);
            }
          }),
        ],
      ),
    );
  }

  // Layout para pantallas estrechas (móviles)
  Widget _buildNarrowLayout(BuildContext context, List<Map<String, dynamic>> nodes, Color primaryColor, Map<String, bool> progress) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _buildNodeItem(context, nodes[index], primaryColor, progress, isWide: false);
      },
    );
  }

  // Layout para pantallas anchas (tablets/web)
  Widget _buildWideLayout(BuildContext context, List<Map<String, dynamic>> nodes, Color primaryColor, Map<String, bool> progress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 40, // Espacio horizontal entre nodos
        runSpacing: 40, // Espacio vertical entre filas
        children: nodes.map((node) {
          return _buildNodeItem(context, node, primaryColor, progress, isWide: true);
        }).toList(),
      ),
    );
  }

  // Alineación para el layout estrecho
  Alignment _getNodeAlignment(Map<String, dynamic> node) {
    Alignment align;
    if (node['type'] == 'pic') {
      align = Alignment.centerLeft;
    } else if (node['type'] == 'draw') {
      align = Alignment.center;
    } else {
      align = Alignment.centerRight;
    }
    return align;
  }

  Widget _buildNodeItem(BuildContext context, Map<String, dynamic> node, Color primaryColor, Map<String, bool> progress, {required bool isWide}) {
    final screenWidth = MediaQuery.of(context).size.width;
    // El tamaño del nodo es relativo al ancho de la pantalla en móviles, pero fijo en pantallas anchas
    final double nodeSize = isWide ? 140 : screenWidth * 0.3;

    final nodeWidget = _buildNodeContent(node, primaryColor, progress, nodeSize);

    if (isWide) {
      return nodeWidget;
    }

    // En layout estrecho, mantenemos la alineación original
    return Align(
      alignment: _getNodeAlignment(node),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 30),
        child: nodeWidget,
      ),
    );
  }

  Widget _buildNodeContent(Map<String, dynamic> node, Color primaryColor, Map<String, bool> progress, double nodeSize) {
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

    return InkWell(
      onTap: () => _handleTap(node, isLocked),
      borderRadius: BorderRadius.circular(nodeSize / 2),
      child: Container(
        width: nodeSize,
        height: nodeSize,
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
                fontSize: nodeSize * 0.12, // Tamaño de fuente relativo al tamaño del nodo
                fontWeight: FontWeight.bold,
                color: (isCompleted || !isLocked) ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}