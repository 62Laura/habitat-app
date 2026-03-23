import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
