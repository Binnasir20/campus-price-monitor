
import 'dart:io';

import 'package:flutter/material.dart';

import '../model/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_profile_image_service.dart';

class AuthProvider with ChangeNotifier {
final AuthService _authService = AuthService();

UserModel? _userModel;
bool _isLoading = true;
String _errorMessage = '';

UserModel? get userModel => _userModel;
bool get isLoading => _isLoading;
String get errorMessage => _errorMessage;

AuthProvider() {
_checkCurrentUser();
}

// Check the current Firebase user when the app starts.
Future<void> _checkCurrentUser() async {
try {
_userModel = await _authService.getUserDetails();

if (_userModel != null) {
await _loadLocalProfilePicture();
}
} catch (e) {
debugPrint('Could not load current user: $e');
_userModel = null;
} finally {
_isLoading = false;
notifyListeners();
}
}

// Load the locally saved picture for the logged-in user.
Future<void> _loadLocalProfilePicture() async {
final user = _userModel;

if (user == null) return;

try {
final imageFile =
await LocalProfileImageService.getProfileImage(user.uid);

_userModel = user.copyWith(
localProfileImagePath: imageFile?.path,
clearLocalProfileImagePath: imageFile == null,
);
} catch (e) {
debugPrint('Could not load local profile picture: $e');
}
}

// Register a new user with Firebase.
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

if (_userModel != null) {
await _loadLocalProfilePicture();
}

_setLoading(false);
return true;
} catch (e) {
_setError(e.toString());
return false;
}
}

// Log in an existing Firebase user.
Future<bool> login(String email, String password) async {
_setLoading(true);

try {
await _authService.loginUser(email, password);

_userModel = await _authService.getUserDetails();

if (_userModel != null) {
await _loadLocalProfilePicture();
}

_setLoading(false);
return true;
} catch (e) {
_setError(e.toString());
return false;
}
}

// Send a password-reset email through Firebase.
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

// Sign out the current Firebase user.
Future<void> logout() async {
_setLoading(true);

try {
await _authService.signOut();

_userModel = null;
_errorMessage = '';

_setLoading(false);
} catch (e) {
_setError(e.toString());
}
}

// Save the profile picture locally instead of Firebase Storage.
Future<bool> updateProfilePicture(File imageFile) async {
if (_userModel == null) {
_setError('No user is currently logged in.');
return false;
}

final currentUser = _userModel!;

_setLoading(true);

try {
final savedImagePath =
await LocalProfileImageService.saveProfileImage(
uid: currentUser.uid,
imageFile: imageFile,
);

_userModel = currentUser.copyWith(
localProfileImagePath: savedImagePath,
);

_isLoading = false;
_errorMessage = '';

notifyListeners();

return true;
} catch (e) {
_setError('Could not save profile picture: $e');
return false;
}
}

// Shared state helpers.
void _setLoading(bool value) {
_isLoading = value;
_errorMessage = '';
notifyListeners();
}

void _setError(String message) {
_isLoading = false;
_errorMessage = message;
notifyListeners();
}
}
