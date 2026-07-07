import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'progress_notifier.dart';

class PetGardenScreen extends ConsumerWidget {
  const PetGardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressNotifierProvider);

    // Lista de recompensas y el ID de nivel que las desbloquea
    final rewards = [
      {'id': 'pic_1', 'emoji': '🐶'},
      {'id': 'draw_A', 'emoji': '🐱'},
      {'id': 'draw_B', 'emoji': '🐢'},
      {'id': 'cuentos_1', 'emoji': '🦊'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jardín de Mascotas'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200, // Cada elemento tendrá un ancho máximo de 200
          childAspectRatio: 1, // Asegura que los elementos sean cuadrados
          crossAxisSpacing: 20, // Espacio horizontal
          mainAxisSpacing: 20, // Espacio vertical
        ),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          final isUnlocked = progress[reward['id']] == true;

          return _PetCard(
            emoji: reward['emoji']!,
            isUnlocked: isUnlocked,
          );
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final String emoji;
  final bool isUnlocked;

  const _PetCard({required this.emoji, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: LayoutBuilder(builder: (context, constraints) {
          final fontSize = constraints.maxWidth * 0.6; // Tamaño de fuente relativo al ancho
          final cardContent = isUnlocked
              ? _BreathingPet(emoji: emoji, size: fontSize)
              : Opacity(
                  opacity: 0.2,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.saturation,
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                );
          return cardContent;
        }),
      ),
    );
  }
}

/// Widget que crea una animación de "respiración" para su hijo.
class _BreathingPet extends StatefulWidget {
  final String emoji;
  final double size;
  const _BreathingPet({required this.emoji, required this.size});

  @override
  State<_BreathingPet> createState() => _BreathingPetState();
}

class _BreathingPetState extends State<_BreathingPet> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true); // Repite la animación hacia adelante y atrás

    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Text(
        widget.emoji,
        style: TextStyle(fontSize: widget.size),
      ),
    );
  }
}