import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'theme_notifier.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Lexi App',
      theme: appTheme.getTheme(),
      initialRoute: AppRouter.studentLearningModule,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
