import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_notifier.dart';

class PictogramQuestion {
  final IconData icon;
  final String correctAnswer;
  final List<String> options;

  PictogramQuestion(this.icon, this.correctAnswer, this.options);
}

class PictogramAssociationScreen extends ConsumerStatefulWidget {
  const PictogramAssociationScreen({super.key});

  @override
  ConsumerState<PictogramAssociationScreen> createState() => _PictogramAssociationScreenState();
}

class _PictogramAssociationScreenState extends ConsumerState<PictogramAssociationScreen> {
  int _currentIndex = 0;
  String _feedbackMessage = '';

  final List<PictogramQuestion> _questions = [
    PictogramQuestion(Icons.pets, 'Perro', ['Gato', 'Perro', 'Pájaro']),
    PictogramQuestion(Icons.directions_car, 'Auto', ['Auto', 'Bici', 'Tren']),
    PictogramQuestion(Icons.star, 'Estrella', ['Luna', 'Sol', 'Estrella']),
  ];

  void _checkAnswer(String selected) {
    if (selected == _questions[_currentIndex].correctAnswer) {
      setState(() => _feedbackMessage = '¡Muy bien!');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _questions.length;
            _feedbackMessage = ''; // Limpiar mensaje para el siguiente
          });
        }
      });
    } else {
      setState(() => _feedbackMessage = 'Intenta de nuevo');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeNotifierProvider);
    final currentQuestion = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asociar Palabras'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  currentQuestion.icon,
                  size: 150,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            // Mensaje de retroalimentación amigable
            Text(
              _feedbackMessage,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: currentQuestion.options.map((option) {
                return _buildOptionButton(context, option);
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String option) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
          ),
          onPressed: _feedbackMessage == '¡Muy bien!' ? null : () => _checkAnswer(option),
          child: Text(option, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}