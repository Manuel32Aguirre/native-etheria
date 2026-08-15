import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _errorMessage;

  AuthProvider(this.authService) {
    _restoreSession();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _restoreSession() async {
    _isAuthenticated = await authService.isLoggedIn();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) =>
      _run(() => authService.login(username, password));

  Future<bool> register(String username, String email, String password) =>
      _run(() => authService.register(username, email, password));

  Future<bool> _run(Future<Map<String, dynamic>> Function() action) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      await action();
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}
