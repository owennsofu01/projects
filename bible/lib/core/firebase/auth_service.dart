import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Wraps Firebase Auth. Every user starts as an anonymous guest on first
/// launch (see [signInAnonymouslyIfNeeded]); signing up later links the
/// chosen provider onto that same UID so guest progress is never lost.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  Future<User?> signInAnonymouslyIfNeeded() async {
    if (_auth.currentUser != null) return _auth.currentUser;
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  Future<User?> linkOrSignInWithEmail(String email, String password) async {
    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      final result = await current.linkWithCredential(credential);
      return result.user;
    }
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> registerWithEmail(String email, String password) async {
    final current = _auth.currentUser;
    final credential = EmailAuthProvider.credential(email: email, password: password);
    if (current != null && current.isAnonymous) {
      final result = await current.linkWithCredential(credential);
      return result.user;
    }
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      final result = await current.linkWithCredential(credential);
      return result.user;
    }
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Requires the app to run under a real Apple Developer Program team with
  /// Sign in with Apple configured — see project README follow-ups.
  Future<User?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, accessToken: appleCredential.authorizationCode);
    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      final result = await current.linkWithCredential(oauthCredential);
      return result.user;
    }
    final result = await _auth.signInWithCredential(oauthCredential);
    return result.user;
  }

  Future<void> signOut() => _auth.signOut();
}
