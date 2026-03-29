// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key, this.onSwitchToSignup}) : super(key: key);

  final VoidCallback? onSwitchToSignup;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonAnimation;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));
    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));
    _formAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutBack),
    ));
    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
    ));
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLOOM'),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated Logo
                FadeTransition(
                  opacity: _logoAnimation,
                  child: ScaleTransition(
                    scale: _logoAnimation,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            size: 80,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Animated Title
                FadeTransition(
                  opacity: _titleAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                        Text(
                          'Sign in to continue tracking your habits',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                // Error message with animation
                if (authState.errorMessage != null)
                  FadeTransition(
                    opacity: _formAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error, size: 20),
                            onPressed: () {
                              authNotifier.clearError();
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Form fields
                FadeTransition(
                  opacity: _formAnimation,
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        enabled: !authState.isLoading,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        enabled: !authState.isLoading,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        obscureText: _obscurePassword,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: authState.isLoading ? null : () async {
                            final currentContext = context;
                            if (_emailController.text.trim().isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(currentContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Please enter your email address'),
                                    backgroundColor: Theme.of(currentContext).colorScheme.error,
                                  ),
                                );
                              }
                              return;
                            }
                            
                            final success = await authNotifier.resetPassword(
                              _emailController.text.trim(),
                            );
                            
                            if (success && mounted) {
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(
                                  content: Text('Password reset email sent!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated Button
                ScaleTransition(
                  scale: _buttonAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : () async {
                            if (_emailController.text.trim().isEmpty || 
                                _passwordController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please fill in all fields'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                              return;
                            }
                            
                            final success = await authNotifier.signIn(
                              _emailController.text.trim(),
                              _passwordController.text,
                            );
                            
                            if (success && mounted) {
                              _emailController.clear();
                              _passwordController.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: widget.onSwitchToSignup,
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
