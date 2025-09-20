import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream to listen for authentication changes (login/logout).
  Stream<User?> get user => _auth.authStateChanges();

  /// Sign in with Google.
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in process
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // For debugging, print the error
      if (kDebugMode) {
        print("❌ Google Sign-In Error: $e");
      }
      // Throw a user-friendly error message
      throw 'Google Sign-In failed. Please try again.';
    }
  }

  /// 🚀 **NEW**: Sign up with Email & Password.
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors with user-friendly messages
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'An account already exists for that email.';
      }
      // For other errors, provide a generic message
      throw 'Sign-up failed. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// 🚀 **NEW**: Sign in with Email & Password.
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Invalid email or password.';
      }
      // For other errors, provide a generic message
      throw 'Login failed. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// 🚀 **NEW**: Sign in Anonymously (as a Guest).
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      throw 'Guest sign-in failed. Please check your connection.';
    }
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    try {
      // Check if the user is signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Sign out error: $e");
      }
      // Optionally, you can throw an error here too
      // throw 'Failed to sign out.';
    }
  }
}