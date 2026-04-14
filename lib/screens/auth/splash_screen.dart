import 'package:campus_price_monitor/constants/app_colors.dart';
import 'package:campus_price_monitor/screens/auth/log2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart'; // 1. IMPORT THE SHOP PROVIDER
import '../main_navigation/main_navigation.dart';
import 'login_screen.dart';
import 'package:iconly/iconly.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  // This function decides where to go after the splash screen.
  Future<void> _initApp() async {
    // Show logo for a few seconds
    await Future.delayed(const Duration(seconds: 3));

    // Safety: don't navigate if widget is already disposed
    if (!mounted) return;

    // 2. Get current auth & shop state
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    // 3. Check if the user's data is loaded and available || // Check if user is already logged in
    final user = authProvider.userModel;

    if (user != null) {

      // Before navigating, fetch all shops.
      // We pass 'isAdmin: user.isAdmin' so the provider knows to fetch ALL pending shops for admins.
      shopProvider.fetchShopsByUniversity(
        user.university,
        user.uid,
        isAdmin: user.isAdmin,
      );

      // User is logged in, navigate to the main app screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      // No user found, navigate to the Login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  RegisterOrSignUpScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.bgColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyBold.chart,
              size: 90,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Campus Price Monitor",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
