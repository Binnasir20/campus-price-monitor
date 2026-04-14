import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../model/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;

  // Initialize isLoading to true because we check for user on startup
  bool _isLoading = true;
  String _errorMessage = "";

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  AuthProvider() {
    _checkCurrentUser();
  }

  // 1. Initial check when app starts
  Future<void> _checkCurrentUser() async {
    try {
      _userModel = await _authService.getUserDetails();
    } catch (e) {
      _userModel = null;
    } finally {
      _isLoading = false; // Data is no longer "fetching"
      notifyListeners();
    }
  }

  // 2. Registration Logic
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String university,
    required String campus,
  }) async {
    _setLoading(true);
    try {
      await _authService.registerUser(
        email: email,
        password: password,
        name: name,
        university: university,
        campus: campus,
      );
      _userModel = await _authService.getUserDetails();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // 3. Login Logic
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.loginUser(email, password);
      _userModel = await _authService.getUserDetails();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // 4. Reset Password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordReset(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // 5. Logout
  Future<void> logout() async {
    await _authService.signOut();
    _userModel = null;
    _errorMessage = "";
    notifyListeners();
  }

  // Helper methods to keep the code simple and dry
  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = "";
    notifyListeners();
  }

  void _setError(String msg) {
    _isLoading = false;
    _errorMessage = msg;
    notifyListeners();
  }
}