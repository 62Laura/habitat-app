import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  auth.User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<auth.UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore (non-blocking)
      _createUserDocumentAsync(result.user!.uid, email, name);

      return result;
    } on auth.FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('AuthService: Sign up error - $e');
      throw 'Sign up failed: ${e.toString()}';
    }
  }

  // Create user document asynchronously without blocking sign up
  Future<void> _createUserDocumentAsync(
      String uid, String email, String name) async {
    try {
      auth.User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != uid) {
        if (kDebugMode)
          print('AuthService: User not authenticated or UID mismatch');
        return;
      }

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      });
      if (kDebugMode) print('AuthService: User document created in Firestore');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (kDebugMode)
          print(
              'AuthService: Permission denied - check Firestore security rules');
      } else {
        if (kDebugMode) print('AuthService: Firebase error - $e');
      }
    } catch (e) {
      if (kDebugMode) print('AuthService: Failed to create user document - $e');
    }
  }

  // Sign in with email and password
  Future<auth.UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      _updateLastLoginAsync(result.user!.uid, email);

      return result;
    } on auth.FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('AuthService: Sign in error - $e');
      throw 'Sign in failed: ${e.toString()}';
    }
  }

  // Update last login asynchronously without blocking sign in
  Future<void> _updateLastLoginAsync(String uid, String email) async {
    try {
      auth.User? currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != uid) {
        if (kDebugMode)
          print(
              'AuthService: User not authenticated or UID mismatch for login update');
        return;
      }

      // First try to update existing document
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (kDebugMode)
          print(
              'AuthService: Permission denied for login update - check Firestore security rules');
      } else if (e.code == 'not-found') {
        // Document doesn't exist, try to create it
        if (kDebugMode)
          print(
              'AuthService: Update last login failed, attempting to create document - $e');
        try {
          await _firestore.collection('users').doc(uid).set({
            'uid': uid,
            'email': email,
            'lastLogin': Timestamp.now(),
          }, SetOptions(merge: true));
          if (kDebugMode)
            print('AuthService: User document created in Firestore');
        } on FirebaseException catch (createError) {
          if (createError.code == 'permission-denied') {
            if (kDebugMode)
              print(
                  'AuthService: Permission denied for document creation - check Firestore security rules');
          } else {
            if (kDebugMode)
              print(
                  'AuthService: Firebase error creating document - $createError');
          }
        }
      } else {
        if (kDebugMode)
          print('AuthService: Firebase error updating login - $e');
      }
    } catch (e) {
      if (kDebugMode)
        print(
            'AuthService: Update last login failed, attempting to create document - $e');
      try {
        // If update fails, create the document with merge option
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'lastLogin': Timestamp.now(),
        }, SetOptions(merge: true));
        if (kDebugMode)
          print('AuthService: User document created in Firestore');
      } on FirebaseException catch (createError) {
        if (createError.code == 'permission-denied') {
          if (kDebugMode)
            print(
                'AuthService: Permission denied for document creation - check Firestore security rules');
        } else {
          if (kDebugMode)
            print(
                'AuthService: Firebase error creating document - $createError');
        }
      } catch (createError) {
        if (kDebugMode)
          print('AuthService: Failed to create user document - $createError');
      }
    }
  }

  // Update user profile
  Future<void> updateProfile(String name) async {
    try {
      auth.User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
        });
      }
    } catch (e) {
      if (kDebugMode) print('AuthService: Update profile error - $e');
      throw 'Error updating profile: ${e.toString()}';
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
