import 'package:campus_price_monitor/constants/app_colors.dart';
import 'package:campus_price_monitor/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_button_one.dart';
import 'login_screen.dart';

class RegisterOrSignUpScreen extends StatefulWidget {
  const RegisterOrSignUpScreen({super.key});

  @override
  State<RegisterOrSignUpScreen> createState() => _RegisterOrSignUpScreenState();
}

class _RegisterOrSignUpScreenState extends State<RegisterOrSignUpScreen> {

  @override
  void initState() {
    _initializeSystemUI();
    super.initState();
  }

  void _initializeSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // Image fix
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    "assets/image/bilya_sanda.jpg",
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "We say no to\n",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: "Unfair ",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  color: Color(AppColors.bgColor),
                                ),
                              ),
                              TextSpan(
                                text: "Prices",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Students deserve better and\nbe free of arbitrary prices",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 60),
                        CustomButtonOne(
                          title: "Log in",
                          onClick: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          isLoading: false,
                          bg: Color(AppColors.bgColor),
                          hasIcon: true,
                        ),
                        const SizedBox(height: 15),
                        CustomButtonOne(
                          title: "Register",
                          onClick: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          isLoading: false,
                          isOutlined: true,
                          textColor: Color(AppColors.bgColor),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}