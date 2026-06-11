import 'package:flutter/material.dart';

import 'tutor_dashboard_screen.dart';
import 'student_menu_screen.dart';
import 'pictogram_association_screen.dart';
import 'letter_drawing_screen.dart';

class AppRouter {
  static const String tutorDashboard = '/tutor';
  static const String studentLearningModule = '/student';
  static const String pictogramAssociation = '/pictogram';
  static const String letterDrawing = '/letter_drawing';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case tutorDashboard:
        return MaterialPageRoute(builder: (_) => const TutorDashboardScreen());
      case studentLearningModule:
        return MaterialPageRoute(builder: (_) => const StudentMenuScreen());
      case pictogramAssociation:
        return MaterialPageRoute(builder: (_) => const PictogramAssociationScreen());
      case letterDrawing:
        return MaterialPageRoute(builder: (_) => const LetterDrawingScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}