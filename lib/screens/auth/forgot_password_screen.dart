import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Color(AppColors.bgColor)),
    );
  }

  // Method to handle the password reset logic
  void _sendResetLink() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showFeedback("Please enter a valid email.", Colors.orange);
      return;
    }

    bool success = await authProvider.resetPassword(email);

    if (mounted) {
      if (success) {
        _showFeedback("Password reset link sent! Check your email inbox.", Colors.green);
        // Pop back to the login screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showFeedback(authProvider.errorMessage, Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We only need the provider for the 'onPressed' logic, not for rebuilding the UI
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("Reset Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
             Icon(Icons.lock_reset, size: 100, color: Color(AppColors.bgColor)),
            const SizedBox(height: 20),
            const Text(
              "Forgot Your Password?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter your email below and we will send you a link to reset it.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              cursorColor: Color(AppColors.bgColor),
              cursorHeight: 20,
              controller: _emailController,
              decoration:  InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: _inputBorder(),
                focusedBorder: _inputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendResetLink(),
            ),
            const SizedBox(height: 30),
            authProvider.isLoading
                ? const CircularProgressIndicator()
                : GestureDetector(
              onTap: ()=> _sendResetLink(),
              child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(AppColors.bgColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text("SEND RESET LINK",style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),),
                  )
              ),
            )

          ],
        ),
      ),
    );
  }

  // Helper method for showing feedback
  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
