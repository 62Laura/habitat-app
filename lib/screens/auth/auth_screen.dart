import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// AuthScreen manages the authentication flow with easy switching between login and signup
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key, this.initialScreen = AuthScreenType.login}) : super(key: key);

  final AuthScreenType initialScreen;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthScreenType { login, signup }

class _AuthScreenState extends State<AuthScreen> {
  late AuthScreenType _currentScreen;

  @override
  void initState() {
    super.initState();
    _currentScreen = widget.initialScreen;
  }

  void _switchToLogin() {
    setState(() {
      _currentScreen = AuthScreenType.login;
    });
  }

  void _switchToSignup() {
    setState(() {
      _currentScreen = AuthScreenType.signup;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AuthScreenType.login:
        return LoginScreen(onSwitchToSignup: _switchToSignup);
      case AuthScreenType.signup:
        return SignupScreen(onSwitchToLogin: _switchToLogin);
    }
  }
}
