import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static Stream<User?> get userStream => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  static Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static String get displayName {
    final user = _auth.currentUser;
    if (user == null) return 'Fan';
    if (user.isAnonymous) return 'Fan';
    return user.displayName?.split(' ').first ?? 'Fan';
  }

  static String? get photoUrl => _auth.currentUser?.photoURL;
}
