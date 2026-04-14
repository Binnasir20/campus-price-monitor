import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}


class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- NEW STATE VARIABLE ---
  bool _isPasswordVisible = false;

  // 2. Data Map
  final Map<String, List<String>> _universityData = {
    "UDUS": ["Main Campus", "City Campus", "Annex"],
    "ABU": ["Samaru Campus", "Kongo Campus"],
    "UNILAG": ["Akoka Campus", "Yaba Campus", "Surulere"],
    "UI": ["Main Campus", "UCH Site"],
  };

  // 3. Selection State
  String? _selectedUniversity;
  String? _selectedCampus;
  List<String> _availableCampuses = [];

  @override
  void dispose() {
    _nameController.dispose();
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
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("Create Account",style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w500,
      ),)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- NAME FIELD ---
            TextField(
              cursorColor: Color(AppColors.bgColor),
              cursorHeight: 20,
              controller: _nameController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                labelText: "Enter full name",
                prefixIcon: Icon(IconlyLight.profile),
                border: _inputBorder(),
                focusedBorder: _inputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // --- EMAIL FIELD ---
            TextField(
              cursorColor: Color(AppColors.bgColor),
              cursorHeight: 20,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                labelText: "Email",
                prefixIcon: Icon(IconlyLight.message),
                border: _inputBorder(),
                focusedBorder: _inputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // --- UPDATED PASSWORD FIELD ---
            TextField(
              cursorColor: Color(AppColors.bgColor),
              cursorHeight: 20,
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                labelText: "Password",
                prefixIcon: Icon(IconlyLight.lock),
                border: _inputBorder(),
                focusedBorder: _inputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 20),

            // --- UNIVERSITY DROPDOWN ---
            DropdownButtonFormField<String>(
              value: _selectedUniversity,
              hint: const Text("Select University"),
              decoration: InputDecoration(
                labelStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                prefixIcon: Icon(IconlyLight.discovery),
                labelText: "University",
                border: _inputBorder(),
                focusedBorder: _inputBorder()
              ),
              items: _universityData.keys
                  .map((uni) => DropdownMenuItem(value: uni, child: Text(uni)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedUniversity = value;
                  _selectedCampus = null;
                  _availableCampuses = _universityData[value] ?? [];
                });
              },
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String?>(
              value: _selectedCampus,
              hint: const Text("Select Campus"),
              isExpanded: true,
              decoration: InputDecoration(
                labelStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                labelText: "Campus",
                prefixIcon: Icon(IconlyLight.location),
                border: _inputBorder(),
                focusedBorder: _inputBorder(),
              ),
              items: _availableCampuses.map((campus) {
                return DropdownMenuItem(
                  value: campus,
                  child: Text(campus),
                );
              }).toList(),
              onChanged: _selectedUniversity == null
                  ? null
                  : (value) => setState(() => _selectedCampus = value),
            ),

            const SizedBox(height: 30),

            authProvider.isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: () async{
                    if (_nameController.text.trim().isEmpty ||
                        _emailController.text.trim().isEmpty ||
                        _passwordController.text.trim().isEmpty ||
                        _selectedUniversity == null ||
                        _selectedCampus == null) {
                      _showSnackBar("Please fill in all fields", Colors.orange);
                      return;
                    }

                    bool success = await authProvider.register(
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
                      name: _nameController.text.trim(),
                      university: _selectedUniversity!,
                      campus: _selectedCampus!,
                    );

                    if (success && mounted) {
                      _showSnackBar("Registration Successful!", Colors.green);
                      Navigator.pop(context);
                    } else if (!success && mounted) {
                      _showSnackBar("Registration Failed. Try again.", Colors.red);
                    }
                  },
                  child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(AppColors.bgColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text("Register",style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),),
                      )
                  ),
                )
            ),
            SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                  children: [
                    TextSpan(text: "Already have an account? ",style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12
                    )
                    ),
                    TextSpan(
                      text: "Login",
                      style: TextStyle(
                        color: Color(AppColors.bgColor),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}