import 'package:campus_price_monitor/providers/auth_provider.dart';
import 'package:campus_price_monitor/providers/complaint_provider.dart';
import 'package:campus_price_monitor/providers/item_provider.dart';
import 'package:campus_price_monitor/providers/price_provider.dart';
import 'package:campus_price_monitor/providers/shop_provider.dart';
import 'package:campus_price_monitor/screens/admin/manage_shop_screen.dart';
import 'package:campus_price_monitor/screens/auth/splash_screen.dart';
import 'package:campus_price_monitor/screens/auth/login_screen.dart'; // ADD THIS
import 'package:campus_price_monitor/screens/complaints/admin_complaint_screen.dart';
import 'package:campus_price_monitor/screens/home/home_screen.dart';   // ADD THIS
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Price Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 1. Keep SplashScreen as the first thing the user sees
      home: const SplashScreen(),

      // 2. REGISTER THE ROUTES HERE
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/manage_shops': (context) => const ManageShopsScreen(),
        '/admin_complaints': (context) => const AdminComplaintScreen(),
        // ADD MORE ROUTES HERE
      },
    );
  }
}