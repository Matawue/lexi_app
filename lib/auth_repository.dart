import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._firebaseAuth, this._googleSignIn);

  // Expone el stream de cambios de autenticación de Firebase
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // También cerramos la sesión de Google para que en el próximo inicio de sesión
    // se pueda volver a elegir una cuenta.
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // google_sign_in v7: ya no existe signIn(); ahora es authenticate().
      // También hay que verificar que la plataforma lo soporte.
      if (!_googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError(
          'Esta plataforma no soporta authenticate() directamente '
          '(por ejemplo, en Web se necesita el botón nativo de Google).',
        );
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // En v7, `.authentication` ya es síncrono (sin await) y solo expone idToken.
      // El accessToken ya NO viene de aquí: si lo necesitas, se pide por separado
      // vía googleUser.authorizationClient.authorizationForScopes([...]).
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // v7 lanza GoogleSignInException en vez de errores genéricos.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // El usuario canceló el proceso de inicio de sesión.
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

// Provider para la instancia de FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Provider para nuestro repositorio.
// IMPORTANTE: GoogleSignIn.instance debe estar inicializado (ver main.dart)
// antes de que este provider se use por primera vez.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider), GoogleSignIn.instance);
});

// StreamProvider que observa el estado de autenticación
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
