import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // App version - update this as needed
  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Contact Us Section
          _buildSectionTitle(context, 'Support'),
          _buildSettingsTile(
            context: context,
            icon: Icons.email_outlined,
            title: 'Contact Us',
            subtitle: 'Get in touch with support',
            onTap: () => _contactUs(context),
          ),
          
          const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16),
          
          // App Info Section
          _buildSectionTitle(context, 'App Information'),
          _buildSettingsTile(
            context: context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: appVersion,
            onTap: null,
          ),
          
          const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16),
          
          // Account Section
          _buildSectionTitle(context, 'Account'),
          _buildSettingsTile(
            context: context,
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            textColor: AppColors.emergencyRed,
            onTap: () => _showLogoutDialog(context),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.emergencyRed).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppColors.emergencyRed,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
      ),
      trailing: onTap != null 
        ? Icon(Icons.chevron_right, color: AppColors.mediumGray) 
        : null,
      onTap: onTap,
    );
  }

  void _contactUs(BuildContext context) async {
    // Update with your support email
    const email = 'support@carealert.com';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Care Alert Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not open email app'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error opening email app'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out of Care Alert?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout(context);
              },
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.emergencyRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get services
      final authService = context.read<AuthService>();
      final storageService = StorageService();
      
      // Sign out from auth service
      await authService.signOut();
      
      // Clear onboarding status to force user back to onboarding
      await storageService.clearOnboardingStatus();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged out successfully'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
        
        // Navigate back to app root - AppWrapper will handle routing to onboarding
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}