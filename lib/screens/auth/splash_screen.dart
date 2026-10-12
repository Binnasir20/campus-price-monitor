import 'package:campus_price_monitor/screens/auth/login_or_signUp_screen.dart';
import 'package:flutter/material.dart';
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
_navigateToNextScreen();
}

Future<void> _navigateToNextScreen() async {
await Future.delayed(const Duration(seconds: 3));

if (!mounted) return;

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const RegisterOrSignUpScreen(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.teal,
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: const [
Icon(
IconlyBold.chart,
size: 90,
color: Colors.white,
),
SizedBox(height: 20),
Text(
'Campus Price Monitor',
style: TextStyle(
color: Colors.white,
fontSize: 24,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 10),
CircularProgressIndicator(
color: Colors.white,
),
],
),
),
);
}
}
