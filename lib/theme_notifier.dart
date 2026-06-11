import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() {
    // Estado inicial por defecto
    return AppTheme();
  }

  void updatePrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
  }

  void updateBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
  }

  void toggleDyslexicFont(bool enable) {
    state = state.copyWith(
      fontFamily: enable ? 'OpenDyslexic' : 'Roboto',
    );
  }

  void applyStudentPreferences(String paletteStr) {
    if (paletteStr == 'default') {
      state = state.copyWith(
        primaryColor: Colors.blue,
        backgroundColor: Colors.white,
      );
    } else if (paletteStr == 'calm_blue') {
      state = state.copyWith(
        primaryColor: Colors.lightBlue,
        backgroundColor: const Color(0xFFF0F8FF), // Azul muy claro para reducir estrés visual
      );
    } else if (paletteStr == 'high_contrast') {
      state = state.copyWith(
        primaryColor: Colors.yellowAccent,
        backgroundColor: Colors.black,
      );
    }
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppTheme>(() {
  return ThemeNotifier();
});