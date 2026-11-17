// FILE: lib/providers/auth_provider.dart  (REPLACE entire file)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final bool isLoggedIn;
  final String? userEmail;
  final String? userName;
  final String? role;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.isLoggedIn,
    this.userEmail,
    this.userName,
    this.role,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAdmin => role == 'admin';
  bool get isClient => role == 'client';

  AuthState copyWith({
    bool? isLoggedIn,
    String? userEmail,
    String? userName,
    String? role,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;

  AuthNotifier({required this.authService}) : super(AuthState(isLoggedIn: false)) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    state = state.copyWith(isLoading: true);
    final isLoggedIn = await authService.isLoggedIn();
    if (isLoggedIn) {
      final email = await authService.getUserEmail();
      final name  = await authService.getUserName();
      final role  = await authService.getRole();
      final token = await authService.getToken();
      state = state.copyWith(
        isLoggedIn: true,
        userEmail: email,
        userName: name,
        role: role,
        token: token,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoggedIn: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await authService.login(email, password);
      if (data != null) {
        state = state.copyWith(
          isLoggedIn: true,
          userEmail: data['email'],
          userName: data['name'],
          role: data['role'],
          token: data['token'],
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Invalid credentials');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await authService.register(name, email, password);
      if (data != null) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Registration failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await authService.logout();
    state = AuthState(isLoggedIn: false);
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(authService: ref.watch(authServiceProvider));
});