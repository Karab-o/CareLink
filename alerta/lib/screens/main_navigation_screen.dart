import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';
import 'trusted_contacts_screen.dart';
import 'alerts_history_screen.dart';
import 'settings_page.dart';
/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: const [
              HomeScreen(),
              TrustedContactsScreen(),
              AlertsHistoryScreen(),
              SettingsPage(),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(
            context,
            navigationProvider,
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    NavigationProvider navigationProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: navigationProvider.currentIndex,
        onTap: navigationProvider.setCurrentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.backgroundLight,
        selectedItemColor: navigationProvider.isEmergencyMode
            ? AppColors.emergencyRed
            : AppColors.emergencyRed,
        unselectedItemColor: AppColors.textLight,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              Icons.home_outlined,
              Icons.home,
              0,
              navigationProvider.currentIndex,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              Icons.contacts_outlined,
              Icons.contacts,
              1,
              navigationProvider.currentIndex,
            ),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              Icons.history_outlined,
              Icons.history,
              2,
              navigationProvider.currentIndex,
            ),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              Icons.settings_outlined,
              Icons.settings,
              3,
              navigationProvider.currentIndex,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    IconData outlinedIcon,
    IconData filledIcon,
    int index,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.emergencyRed.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: 24,
      ),
    );
  }
}