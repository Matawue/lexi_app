import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_router.dart';
import 'theme_notifier.dart';
import 'auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('lexiBox');
  await Hive.openBox('rondasBox');

  // google_sign_in v7 requiere inicializar el singleton antes de usarlo.
  //
  // IMPORTANTE (Android): a diferencia de v6, ahora SIEMPRE hay que pasar
  // `serverClientId` en Android, aunque ya tengas google-services.json.
  // Es el "Web client ID" (NO el de Android) que puedes copiar desde:
  //   - Google Cloud Console > APIs & Services > Credentials
  //     -> "Web client (auto created by Google Service)"
  //   - o Firebase Console > Authentication > Sign-in method > Google
  //     -> "Web SDK configuration" > Web client ID
  // Tiene forma: 864309675440-xxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
  //
  // Sin este valor, verás: GoogleSignInException(clientConfigurationError,
  // "serverClientId must be provided on Android").
  await GoogleSignIn.instance.initialize(
    serverClientId: '864309675440-98eqaijud7q6ib837lpaotj7det4veh4.apps.googleusercontent.com',
  );

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lexi App',
      theme: appTheme.getTheme(),
      home: const AuthWrapper(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
