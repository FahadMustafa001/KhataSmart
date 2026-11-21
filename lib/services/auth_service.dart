import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Central Authentication Service for KhataSmart
/// Manages Firebase Email/Password Authentication & Google 1-Tap Sign-In
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void markInitialized() {
    _isInitialized = true;
    notifyListeners();
  }

  User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn => currentUser != null;
  String? get userEmail => currentUser?.email;
  String? get userDisplayName => currentUser?.displayName ?? currentUser?.email?.split('@').first;
  String? get userPhotoUrl => currentUser?.photoURL;

  Stream<User?> get authStateChanges {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  /// Sign Up with Email and Password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (displayName != null && displayName.trim().isNotEmpty) {
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
    }

    notifyListeners();
    return credential;
  }

  /// Sign In with Email and Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    notifyListeners();
    return credential;
  }

  /// Sign In with Google (1-Tap Account Chooser)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        notifyListeners();
        return userCredential;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '711388054106-7bk5k86vbl1c4vp8jqqei6eciek1tlsr.apps.googleusercontent.com'
            : null,
        serverClientId: '711388054106-7bk5k86vbl1c4vp8jqqei6eciek1tlsr.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the Google sign-in dialog
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Send Password Reset Verification Email
  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await GoogleSignIn(
          clientId: '711388054106-3qlij7rn5u7s9fgj2k4clvrvtnnho9qn.apps.googleusercontent.com',
        ).signOut();
      } else {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    notifyListeners();
  }

  /// Translates Firebase Auth and Google Sign-In error codes into clear, user-friendly messages
  static String formatAuthError(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('ApiException: 10') || errorString.contains('10:')) {
      return 'Google Sign-In configuration error: Please register the app SHA-1 fingerprint in Firebase Console settings.';
    }
    if (errorString.contains('ApiException: 12500') || errorString.contains('12500:')) {
      return 'Google Sign-In failed (12500). Please ensure Google Sign-In is enabled in Firebase Authentication.';
    }
    if (errorString.contains('network_error') || errorString.contains('ApiException: 7')) {
      return 'Network error connecting to Google Play Services. Please check your internet connection.';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Please check or sign up.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect password. Please try again or reset your password.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in instead.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a few moments and try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error.toString();
  }
}
