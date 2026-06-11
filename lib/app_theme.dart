import 'package:flutter/material.dart';

class AppTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final String fontFamily;

  AppTheme({
    this.primaryColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.fontFamily = 'Roboto', // Por defecto, puede cambiarse a 'OpenDyslexic'
  });

  ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        surface: backgroundColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  AppTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    String? fontFamily,
  }) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}