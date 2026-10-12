
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../model/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
final AuthService _authService = AuthService();

UserModel? _userModel;
bool _isLoading = true;
String _errorMessage = '';

// Getters
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
} catch (e) {
_userModel = null;
} finally {
_isLoading = false;
notifyListeners();
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

// Update the profile picture using Firebase Storage.
Future<bool> updateProfilePicture(File imageFile) async {
if (_userModel == null) {
_setError('No user is currently logged in.');
return false;
}

_setLoading(true);

try {
final storageRef = FirebaseStorage.instance
    .ref()
    .child('profile_images')
    .child('${_userModel!.uid}.jpg');

await storageRef.putFile(imageFile);

final imageUrl = await storageRef.getDownloadURL();

_userModel = UserModel(
uid: _userModel!.uid,
name: _userModel!.name,
email: _userModel!.email,
university: _userModel!.university,
campus: _userModel!.campus,
isAdmin: _userModel!.isAdmin,
profileImageUrl: imageUrl,
);

await _authService.updateUserProfileImage(imageUrl);

_setLoading(false);
return true;
} catch (e) {
_setError(e.toString());
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
