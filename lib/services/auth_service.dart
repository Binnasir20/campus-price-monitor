import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. REGISTER USER
  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String name,
    required String university,
    required String campus,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
        university: university,
        campus: campus,
      );

      await _db.collection('users').doc(result.user!.uid).set(newUser.toMap());
      return result;
    } on FirebaseAuthException catch (e) {
      // Provide cleaner error messages for common issues
      if (e.code == 'email-already-in-use') {
        throw 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      }
      throw e.message ?? 'An unknown error occurred.';
    } catch (e) {
      rethrow;
    }
  }

  // 2. LOGIN USER
  Future<UserCredential?> loginUser(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Map Firebase codes to human-readable strings for your UI logic
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw 'Account not found';
      } else if (e.code == 'wrong-password') {
        throw 'Incorrect password';
      }
      throw 'Login failed: ${e.message}';
    } catch (e) {
      rethrow;
    }
  }

  // 3. GET USER DETAILS
  Future<UserModel?> getUserDetails() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  // 4. RESET PASSWORD (The "Forgotten Password" addition)
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No account found with this email.';
      }
      throw e.message ?? 'Error sending reset email.';
    } catch (e) {
      rethrow;
    }
  }

  // 5. LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}