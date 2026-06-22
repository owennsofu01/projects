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

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
