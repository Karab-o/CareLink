import 'package:CareAlert/constants/app_colors.dart';
import 'package:CareAlert/screens/alerts_history_screen.dart';
import 'package:CareAlert/screens/contact_screen.dart';
import 'package:CareAlert/screens/home_screen.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = '/main-screen';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<Widget> _pages;
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const ContactScreen(),
      const AlertsHistoryScreen(),
      Container(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 10,
        backgroundColor: AppColors.backgroundLight,
        selectedItemColor: AppColors.emergencyRed,
        unselectedItemColor: AppColors.darkGray,
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            activeIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'My Account',
            tooltip: 'My Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'Settings',
          ),
        ],
      ),

      // bottomNavigationBar: FloatingNavbar(
      //   backgroundColor: AppColors.backgroundLight,
      //   selectedItemColor: AppColors.emergencyRed,
      //   borderRadius: 15,
      //   itemBorderRadius: 15,
      //   width: MediaQuery.of(context).size.width * 0.9,
      //   items: [
      //     FloatingNavbarItem(icon: Icons.home, title: 'H'),
      //     FloatingNavbarItem(icon: Icons.contacts, title: 'C'),
      //     FloatingNavbarItem(icon: Icons.account_circle, title: 'A'),
      //     FloatingNavbarItem(icon: Icons.settings, title: 'S'),
      //   ],
      //   currentIndex: _selectedPageIndex,
      //   onTap: _selectPage,
      // ),
    );
  }
}
