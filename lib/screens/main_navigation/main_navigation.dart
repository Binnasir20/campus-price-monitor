import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../constants/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_list_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // List of screens to display in the tabs
  final List<Widget> _screens = [
    const HomeScreen(),
    const ShopListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(AppColors.bgColor),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(

            icon: Icon(IconlyLight.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconlyLight.work),
            label: 'Shops',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconlyLight.profile),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}