import 'package:flutter/material.dart';

import 'tutor_dashboard_screen.dart';
import 'student_menu_screen.dart';
import 'pictogram_association_screen.dart';
import 'pet_garden_screen.dart';
import 'tutor_statistics_screen.dart';
import 'letter_drawing_screen.dart';

class AppRouter {
  static const String tutorDashboard = '/tutor';
  static const String studentLearningModule = '/student';
  static const String pictogramAssociation = '/pictogram';
  static const String petGarden = '/pet_garden';
  static const String tutorStatistics = '/tutor_statistics';
  static const String letterDrawing = '/letter_drawing';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case tutorDashboard:
        return MaterialPageRoute(builder: (_) => const TutorDashboardScreen());
      case studentLearningModule:
        return MaterialPageRoute(builder: (_) => const StudentMenuScreen());
      case pictogramAssociation:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final levelId = args['levelId'] as String? ?? 'pic_1'; // Fallback por seguridad
        return MaterialPageRoute(
          builder: (_) => PictogramAssociationScreen(levelId: levelId),
        );
      case petGarden:
        return MaterialPageRoute(builder: (_) => const PetGardenScreen());
      case tutorStatistics:
        return MaterialPageRoute(builder: (_) => const TutorStatisticsScreen());
      case letterDrawing:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final letra = args['letra'] as String? ?? 'A';
        final idNivel = args['idNivel'] as String? ?? 'draw_A';
        return MaterialPageRoute(
          builder: (_) =>
              LetterDrawingScreen(letra: letra, idNivel: idNivel),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}