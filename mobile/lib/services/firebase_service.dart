import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

  static Future<void> initialize() async {
    print('[FirebaseService] Inicializando');
  }

  static Future<String?> signInWithGoogle() async {
    try {
      print('[FirebaseService] Iniciando Google Sign In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('[FirebaseService] Usuario cancelou login');
        return null;
      }

      print('[FirebaseService] Login via Google bem-sucedido: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;

      final token = googleAuth.accessToken ?? googleAuth.idToken;

      if (token == null || token.isEmpty) {
        print('[FirebaseService] Nenhum token obtido');
        return null;
      }

      print('[FirebaseService] Token obtido: ${token.length} caracteres');
      return token;
    } catch (e) {
      print('[FirebaseService] Erro: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('[FirebaseService] Logout bem-sucedido');
    } catch (e) {
      print('[FirebaseService] Erro ao fazer logout: $e');
    }
  }

  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }
}
