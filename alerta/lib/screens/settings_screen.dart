import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.emergencyRed,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= PROFILE SECTION =================
              _buildSectionTitle('👤 Account Settings'),
              const SizedBox(height: AppDimensions.paddingM),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _getProfileImage(appProvider),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickProfilePicture(context),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.emergencyRed,
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              _buildSettingTile(
                context,
                icon: Icons.person,
                title: 'Name',
                subtitle: appProvider.userProfile?.name ?? 'Not set',
                onTap: () {
                  _editFieldDialog(context, 'Name', appProvider.userProfile?.name, (value) {
                    appProvider.updateUserProfileField('name', value);
                  });
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.email,
                title: 'Email',
                subtitle: appProvider.userProfile?.email ?? 'Not set',
                onTap: () {
                  _editFieldDialog(context, 'Email', appProvider.userProfile?.email, (value) {
                    appProvider.updateUserProfileField('email', value);
                  });
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.phone,
                title: 'Phone',
                subtitle: appProvider.userProfile?.phoneNumber ?? 'Not set',
                onTap: () {
                  _editFieldDialog(context, 'Phone', appProvider.userProfile?.phoneNumber, (value) {
                    appProvider.updateUserProfileField('phoneNumber', value);
                  });
                },
              ),
              const Divider(height: 40),

              // ================= GENERAL SETTINGS =================
              _buildSectionTitle('⚙️ General Settings'),
              const SizedBox(height: AppDimensions.paddingM),
              _buildSettingTile(
                context,
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English', // can integrate dropdown
                onTap: () {},
              ),
              _buildThemeToggle(context, appProvider), // Theme toggle added
              _buildSettingTile(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.access_time,
                title: 'Time Zone / Date & Time',
                onTap: () {},
              ),
              const Divider(height: 40),

              // ================= PRIVACY & SECURITY =================
              _buildSectionTitle('🔒 Privacy & Security'),
              const SizedBox(height: AppDimensions.paddingM),
              _buildSettingTile(
                context,
                icon: Icons.fingerprint,
                title: 'Biometric Lock / PIN',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.privacy_tip,
                title: 'Privacy Settings',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.devices,
                title: 'Session Management',
                subtitle: 'Log out of all devices',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.delete_forever,
                title: 'Delete / Deactivate Account',
                onTap: () {},
              ),
              const Divider(height: 40),

              // ================= LOGOUT =================
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PROFILE IMAGE HELPER =================
  ImageProvider _getProfileImage(AppProvider appProvider) {
    final profilePicture = appProvider.userProfile?.profilePicture;
    
    if (profilePicture == null || profilePicture.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    
    // Check if it's a URL or local file path
    if (profilePicture.startsWith('http://') || profilePicture.startsWith('https://')) {
      return NetworkImage(profilePicture);
    } else {
      // Local file path
      final file = File(profilePicture);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return const AssetImage('assets/images/default_avatar.png');
      }
    }
  }

  // ================= HELPERS =================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildSettingTile(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.emergencyRed),
      title: Text(title, style: AppTextStyles.h4),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // ================= THEME TOGGLE =================
  Widget _buildThemeToggle(BuildContext context, AppProvider appProvider) {
    return SwitchListTile(
      secondary: const Icon(Icons.color_lens, color: AppColors.emergencyRed),
      title: const Text('Theme', style: AppTextStyles.h4),
      subtitle: Text(appProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
      value: appProvider.isDarkMode,
      onChanged: (value) {
        appProvider.toggleTheme(value);
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AppProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _editFieldDialog(BuildContext context, String fieldName, String? currentValue,
      void Function(String value) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter $fieldName'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _pickProfilePicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // Show dialog to choose between camera or gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null && context.mounted) {
        await context.read<AppProvider>().updateProfilePicture(image.path);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}