import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Maps a thrown auth error into a short, user-facing message instead of
/// surfacing raw Firebase exception text.
String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
  if (error is SignInWithAppleAuthorizationException) {
    return 'Sign in with Apple failed. Please try again.';
  }
  if (error is GoogleSignInException) {
    return 'Sign in with Google failed. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
