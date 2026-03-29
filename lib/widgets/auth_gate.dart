// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../services/auth_service.dart';

/// AuthGate widget that manages the authentication flow
/// Shows the appropriate screen based on authentication status with smooth transitions
class AuthGate extends ConsumerWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        
        if (kDebugMode) {
          print('AuthGate: Building - isInitialized: ${authState.isInitialized}, isAuthenticated: ${authState.isAuthenticated}, user: ${authState.user?.email}');
        }
        
        // Show loading screen while checking authentication status
        if (!authState.isInitialized) {
          if (kDebugMode) print('AuthGate: Showing loading screen');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
            ),
          );
        }

        // Check if user is authenticated - use both conditions for safety
        if (authState.isAuthenticated && authState.user != null) {
          if (kDebugMode) print('AuthGate: User authenticated, showing HomeScreen');
          // Directly return HomeScreen without trying to fetch user data
          return const HomeScreen();
        }

        // Show login screen if not authenticated
        if (kDebugMode) print('AuthGate: User not authenticated, showing AuthScreen');
        return const AuthScreen(initialScreen: AuthScreenType.login);
      },
    );
  }
}
