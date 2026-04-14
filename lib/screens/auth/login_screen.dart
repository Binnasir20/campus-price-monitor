import 'package:campus_price_monitor/constants/app_colors.dart';
import 'package:campus_price_monitor/providers/auth_provider.dart';
import 'package:campus_price_monitor/screens/auth/forgot_password_screen.dart';
import 'package:campus_price_monitor/screens/auth/register_screen.dart';
import 'package:campus_price_monitor/screens/main_navigation/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Color(AppColors.bgColor)),
    );
  }
  
  final List<String> _socialMediaIcons = [
    "search.png",
    "facebook.png",
    "twitter.png"
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Login",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(
              IconlyBold.chart,
              size: 60,
              color: Color(AppColors.bgColor),
            ),
            const SizedBox(height: 24),
            const Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Email field
            TextField(
              controller: _emailController,
              cursorColor: Color(AppColors.bgColor),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                prefixIcon: const Icon(IconlyLight.message),
                border: _inputBorder(),
                focusedBorder: _inputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              cursorColor: Color(AppColors.bgColor),
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                prefixIcon: const Icon(IconlyLight.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : IconlyLight.hide,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: _inputBorder(),
                focusedBorder: _inputBorder(),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Color(AppColors.bgColor),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Login button
            if (auth.isLoading)
              const CircularProgressIndicator()
            else
              GestureDetector(
                onTap: () => _handleLogin(auth),
                child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                color: Color(AppColors.bgColor),
                borderRadius: BorderRadius.circular(11),
    ),
                  child: Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Register link
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: "Register",
                      style: TextStyle(
                        color: Color(AppColors.bgColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Social login placeholders images
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_socialMediaIcons.length, (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 30,
                  height: 30,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Image.asset("assets/image/${_socialMediaIcons[index]}"),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(AuthProvider auth) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter email and password", Colors.red);
      return;
    }

    final success = await auth.login(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      final msg = auth.errorMessage;
      if (msg.toLowerCase().contains("not found") || msg.toLowerCase().contains("credential")) {
        _showRegistrationSnackBar();
      } else {
        _showSnackBar(msg.isEmpty ? "Login failed" : msg, Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRegistrationSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Account not found. Want to register?"),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "REGISTER",
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
        ),
      ),
    );
  }
}