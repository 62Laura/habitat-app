import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final auth.User? user;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  final int stateVersion; // Add version to force rebuilds
  final DateTime timestamp; // Add timestamp to force rebuilds
  final String? userName; // User's display name from Firestore

  AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.stateVersion = 0,
    DateTime? timestamp,
    this.userName,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isAuthenticated {
    final result = user != null;
    if (kDebugMode) print('AuthState: isAuthenticated getter - user: $user, result: $result');
    return result;
  }

  AuthState copyWith({
    auth.User? user,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    int? stateVersion,
    DateTime? timestamp,
    String? userName,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
      stateVersion: stateVersion ?? this.stateVersion,
      timestamp: timestamp ?? this.timestamp,
      userName: userName ?? this.userName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.isInitialized == isInitialized &&
        other.errorMessage == errorMessage &&
        other.stateVersion == stateVersion &&
        other.timestamp == timestamp &&
        other.userName == userName;
  }

  @override
  int get hashCode {
    return user.hashCode ^
        isLoading.hashCode ^
        isInitialized.hashCode ^
        errorMessage.hashCode ^
        stateVersion.hashCode ^
        timestamp.hashCode ^
        userName.hashCode;
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  StreamSubscription<auth.User?>? _authSubscription;

  AuthNotifier() : super(AuthState(isInitialized: false)) {
    _initialize();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Initialize authentication and listen to state changes
  Future<void> _initialize() async {
    try {
      if (kDebugMode) print('AuthNotifier: Starting initialization...');
      
      // Listen to auth state changes - this will handle initial state and all subsequent changes
      _authSubscription = _authService.authStateChanges.listen(
        (auth.User? user) async {
          if (kDebugMode) print('AuthNotifier: Auth state changed - $user');
          if (kDebugMode) print('AuthNotifier: Current state before update - user: ${state.user}, isInitialized: ${state.isInitialized}');
          
          String? userName;
          
          // Fetch user name from Firestore if user is authenticated
          if (user != null) {
            try {
              final userDoc = await _authService.getUserData(user.uid);
              if (userDoc.exists) {
                userName = userDoc.get('name') as String?;
                if (kDebugMode) print('AuthNotifier: Fetched user name from Firestore: $userName');
              }
            } catch (e) {
              if (kDebugMode) print('AuthNotifier: Error fetching user name - $e');
            }
          }
          
          // Simple state update
          final newState = AuthState(
            user: user,
            isLoading: false,
            isInitialized: true,
            errorMessage: null,
            stateVersion: state.stateVersion + 1,
            timestamp: DateTime.now(),
            userName: userName,
          );
          
          if (kDebugMode) print('AuthNotifier: Setting new state - user: ${newState.user}, isAuthenticated: ${newState.isAuthenticated}, version: ${newState.stateVersion}, userName: ${newState.userName}');
          
          // Single state update
          state = newState;
          
          if (kDebugMode) print('AuthNotifier: State after update - user: ${state.user}, isAuthenticated: ${state.isAuthenticated}');
        },
        onDone: () {
          if (kDebugMode) print('AuthNotifier: Auth stream completed');
        },
        cancelOnError: true,
        onError: (error) {
          if (kDebugMode) print('AuthNotifier: Auth stream error - $error');
          state = AuthState(
            user: null,
            isLoading: false,
            isInitialized: true,
            errorMessage: 'Authentication stream error: $error',
          );
        },
      );
      
      if (kDebugMode) print('AuthNotifier: Initialization complete');
    } catch (e) {
      if (kDebugMode) print('AuthNotifier: Initialization error - $e');
      state = state.copyWith(
        isInitialized: true,
        errorMessage: 'Failed to initialize authentication: $e',
      );
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password, String name) async {
    await prepareForNewUser();
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _authService.signUpWithEmailAndPassword(
        email,
        password,
        name,
      );
      
      if (result != null) {
        if (kDebugMode) print('AuthNotifier: Sign up successful');
        
        // Don't sign out automatically - let the user stay signed in
        // The signup screen will handle navigation to login screen if needed
        
        state = state.copyWith(isLoading: false);
        
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign up failed',
      );
      return false;
    } catch (e) {
      if (kDebugMode) print('AuthNotifier: Sign up error - $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    await prepareForNewUser();
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (result != null) {
        state = state.copyWith(isLoading: false);
        
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.signOut();
      if (kDebugMode) print('AuthNotifier: Sign out successful, stream will handle state update');
      
      // Give the auth stream a moment to process the sign-out
      await Future.delayed(const Duration(milliseconds: 200));
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (kDebugMode) print('AuthNotifier: Sign out error - $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sign out: $e',
      );
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      if (kDebugMode) print('AuthNotifier: Password reset email sent');
      return true;
    } catch (e) {
      if (kDebugMode) print('AuthNotifier: Reset password error - $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.updateProfile(name);
      state = state.copyWith(isLoading: false);
      if (kDebugMode) print('AuthNotifier: Profile updated');
      return true;
    } catch (e) {
      if (kDebugMode) print('AuthNotifier: Update profile error - $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Force refresh auth state (for debugging)
  void forceRefreshAuthState() {
    final auth.User? currentUser = _authService.currentUser;
    if (kDebugMode) print('AuthNotifier: Force refresh - current user: $currentUser');
    
    // Create a completely new state to force UI update
    final newState = AuthState(
      user: currentUser,
      isLoading: false,
      isInitialized: true,
      errorMessage: null,
      stateVersion: (state.stateVersion + 1) % 1000000,
      timestamp: DateTime.now(), // New timestamp to force rebuild
    );
    
    if (kDebugMode) print('AuthNotifier: Force refresh - setting state version: ${newState.stateVersion}');
    
    state = newState;
    
    // Force another update after delay
    Future.microtask(() {
      state = newState;
    });
  }

  /// Clear auth state and force user to login again
  Future<void> clearAuthState() async {
    try {
      if (kDebugMode) print('AuthNotifier: Clearing auth state and forcing login');
      await _authService.signOut();
      // State will be updated by the stream listener
    } catch (e) {
      if (kDebugMode) print('AuthNotifier: Error clearing auth state - $e');
      // Force clear the state even if sign out fails
      state = AuthState(
        user: null,
        isLoading: false,
        isInitialized: true,
        errorMessage: null,
      );
    }
  }

  /// Prepare for new user login (clears current state cleanly)
  Future<void> prepareForNewUser() async {
    // Clear any existing error messages and loading states
    state = state.copyWith(
      errorMessage: null,
      isLoading: false,
    );
  }
}
