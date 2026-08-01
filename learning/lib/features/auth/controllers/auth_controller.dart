import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxBool isLoading = false.obs;

  String get userId => _auth.currentUser!.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  bool get hasPasswordProvider =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  /// One-shot fetch of the signed-in user's Firestore profile document.
  /// Deliberately not a live stream: the profile screen holds an editable
  /// copy of this in a text field, and a stream would overwrite in-progress
  /// edits whenever it re-emits.
  Future<UserModel?> fetchProfile() async {
    final doc = await _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _db
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set(user.toFirestore());

      showSuccessSnackbar('Account created. Welcome, $name!');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      showErrorSnackbar(mapAuthError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      showSuccessSnackbar('Logged in successfully');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      showErrorSnackbar(mapAuthError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user!;

      final userDocRef = _db.collection(FirestoreCollections.users).doc(user.uid);
      if (!(await userDocRef.get()).exists) {
        final name = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].whereType<String>().join(' ').trim();

        await userDocRef.set(
          UserModel(
            uid: user.uid,
            name: name.isEmpty ? 'Apple User' : name,
            email: user.email ?? appleCredential.email ?? '',
            createdAt: DateTime.now(),
          ).toFirestore(),
        );
      }

      showSuccessSnackbar('Signed in with Apple');
      Get.offAllNamed(AppRoutes.home);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        showErrorSnackbar(mapAuthError(e));
      }
    } catch (e) {
      showErrorSnackbar(mapAuthError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email.trim());
      showSuccessSnackbar('Password reset email sent to $email');
      return true;
    } on FirebaseAuthException catch (e) {
      // 'user-not-found' is mapped to a login-specific message elsewhere
      // (deliberately vague there); a reset flow can be direct about it.
      final message = e.code == 'user-not-found'
          ? 'No account found with that email.'
          : mapAuthError(e);
      showErrorSnackbar(message);
      return false;
    } catch (e) {
      showErrorSnackbar('Something went wrong. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> updateName(String name) async {
    try {
      isLoading.value = true;
      await _db.collection(FirestoreCollections.users).doc(userId).update({
        'name': name,
      });
      showSuccessSnackbar('Profile updated');
    } catch (e) {
      showErrorSnackbar('Could not update profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-proves identity for a password account before a sensitive action
  /// (like account deletion) that Firebase requires a recent sign-in for.
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Permanently deletes the user's data and Firebase Auth account.
  ///
  /// Firestore data is removed first (while the user is still
  /// authenticated, since security rules key off `request.auth.uid`) and
  /// the Auth account last — if the Auth deletion step fails because
  /// Firebase demands a recent login, throws the underlying
  /// [FirebaseAuthException] (code `requires-recent-login`) so the caller
  /// can prompt for re-authentication and call this again; retrying is
  /// safe since the data deletion is idempotent.
  Future<bool> deleteAccount() async {
    try {
      isLoading.value = true;
      final uid = userId;
      await _deleteUserData(uid);
      await _auth.currentUser!.delete();
      Get.offAllNamed(AppRoutes.login);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') rethrow;
      showErrorSnackbar(mapAuthError(e));
      return false;
    } catch (e) {
      showErrorSnackbar('Could not delete account. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _deleteUserData(String uid) async {
    final userRef = _db.collection(FirestoreCollections.users).doc(uid);
    for (final sub in [
      FirestoreCollections.products,
      FirestoreCollections.sales,
      FirestoreCollections.expenses,
    ]) {
      await _deleteCollection(userRef.collection(sub));
    }
    await userRef.delete();
  }

  Future<void> _deleteCollection(CollectionReference ref) async {
    const batchSize = 300;
    while (true) {
      final snapshot = await ref.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < batchSize) return;
    }
  }
}
