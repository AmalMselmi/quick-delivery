// FILE: lib/services/auth_service.dart  (REPLACE entire file)

import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final _api = ApiService();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final data = await _api.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('userEmail', data['email']);
      await prefs.setString('userName', data['name']);
      await prefs.setBool('loggedIn', true);
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final data = await _api.register(name, email, password);
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try { await _api.logout(token); } catch (_) {}
    }
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }
}