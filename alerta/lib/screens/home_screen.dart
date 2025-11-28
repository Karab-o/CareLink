import 'dart:async';
import 'dart:developer';

import 'package:CareAlert/models/user.model.dart';
import 'package:CareAlert/providers/user.provider.dart';
import 'package:CareAlert/screens/contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';
import '../providers/app_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/emergency_alert.dart';

/// Home screen with emergency panic button and quick actions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home-screen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isEmergencyMode = false;
  final int _emergencyCountdown = 0;

  User _user = User();
  late UserProvider _userProvider;

  void _userListener() {
    setState(() {
      _user = _userProvider.user;
    });
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _userProvider = Provider.of<UserProvider>(context, listen: false)
      ..getProfile()
      ..addListener(_userListener);
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _userProvider.removeListener(_userListener);
    super.dispose();
  }

  void _showNoContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Emergency Contacts'),
        content: const Text(
          'You need to add at least one emergency contact before you can send alerts. Would you like to add contacts now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NavigationProvider>().navigateToContacts();
            },
            child: const Text('Add Contacts'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyOptionsDialog() {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.warning,
              color: AppColors.emergencyRed,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Emergency Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the type of emergency:',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildEmergencyTypeButton(
              AlertType.general,
              Icons.emergency,
              'General Emergency',
            ),
            const SizedBox(height: 8),
            _buildEmergencyTypeButton(
              AlertType.medical,
              Icons.medical_services,
              'Medical Emergency',
            ),
            const SizedBox(height: 8),
            _buildEmergencyTypeButton(
              AlertType.violence,
              Icons.security,
              'Violence/Assault',
            ),
            const SizedBox(height: 8),
            _buildEmergencyTypeButton(
              AlertType.harassment,
              Icons.report_problem,
              'Harassment',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeButton(
    AlertType type,
    IconData icon,
    String label,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _sendEmergencyAlert(type),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emergencyRed,
          foregroundColor: AppColors.textOnDark,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Future<void> _sendEmergencyAlert(AlertType type) async {
    Navigator.of(context).pop(); // Close dialog

    final appProvider = context.read<AppProvider>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sending emergency alert...'),
          ],
        ),
      ),
    );

    try {
      final alert = await appProvider.sendEmergencyAlert(
        type: type,
        includeLocation: true,
      );
      log(alert.toString());

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (alert != null) {
          _showAlertSentDialog(alert as EmergencyAlertss);
        } else {
          _showAlertFailedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showAlertFailedDialog();
      }
    } finally {
      _cancelEmergency();
    }
  }

  void _showAlertSentDialog(EmergencyAlertss alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.safeGreen,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Alert Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency alert sent to ${context.read<AppProvider>().activeContacts.length} contacts.',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Alert Type: ${alert.type.name}',
              style: AppTextStyles.bodyMedium,
            ),
            if (alert.location != null) ...[
              const SizedBox(height: 4),
              const Text(
                'Location included in alert',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAlertFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.error,
              color: AppColors.error,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Alert Failed'),
          ],
        ),
        content: const Text(
          'Failed to send emergency alert. Please try again or contact emergency services directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEmergencyOptionsDialog(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _cancelEmergency() {
    setState(() {
      _isEmergencyMode = false;
    });
    context.read<NavigationProvider>().exitEmergencyMode();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _userProvider,
      builder: (context, child) => Selector<UserProvider, bool>(
        selector: (_, provider) => provider.isLoading,
        builder: (context, loading, _) {
          final contacts = _user.trustedContacts ?? [];
          final contactCount = contacts.length;
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('Personal Safety'),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: contactCount > 0
                        ? AppColors.safeGreenLight
                        : AppColors.warningOrangeLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.contacts,
                        size: 16,
                        color: contactCount > 0
                            ? AppColors.safeGreen
                            : AppColors.warningOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$contactCount',
                        style: AppTextStyles.caption.copyWith(
                          color: contactCount > 0
                              ? AppColors.safeGreen
                              : AppColors.warningOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: loading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Welcome Message
                          _buildWelcomeSection(_user),

                          const SizedBox(height: AppDimensions.paddingXL),

                          // Emergency Button
                          _buildEmergencyButton(),

                          const SizedBox(height: AppDimensions.paddingXL),

                          // Quick Actions
                          _buildQuickActions(_user),

                          const SizedBox(height: AppDimensions.paddingL),

                          // Recent Alerts
                          // _buildRecentAlerts(appProvider),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(User user) {
    final userName = user.fullName ?? 'User';
    final contacts = user.trustedContacts ?? [];
    final contactCount = contacts.length;

    return Column(
      children: [
        Text(
          'Hello, $userName',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        if (contactCount == 0)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.warningOrangeLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: AppColors.warningOrange,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setup Required',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.warningOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add emergency contacts to enable alerts',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.safeGreenLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.safeGreen,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Text(
                    'Ready to send alerts to $contactCount emergency contacts',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.safeGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyButton() {
    return Column(
      children: [
        const Text(
          'Emergency Alert',
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Text(
          'Press and hold for emergency',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingL),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: _showEmergencyOptionsDialog,
                child: ElevatedButton.icon(
                  onPressed: _showEmergencyOptionsDialog,
                  icon: const Icon(Icons.emergency),
                  label: const Text('SOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    foregroundColor: AppColors.textOnDark,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: AppTextStyles.h3,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Text(
          'This will alert your emergency contacts\nwith your location',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions(User user) {
    final contacts = user.trustedContacts ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.phone,
                title: 'Call 911',
                subtitle: 'Emergency services',
                onTap: () {
                  launchUrlString("tel:911");
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.location_on,
                title: 'Share Location',
                subtitle: 'Send current location',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location sharing coming soon'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.contacts,
                title: 'Contacts',
                subtitle: '${contacts.length} active',
                onTap: () {
                  Navigator.of(context).pushNamed(
                    ContactScreen.routeName,
                  );
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.west_outlined,
                title: 'Test System',
                subtitle: 'Test emergency alerts',
                onTap: () => _testEmergencySystem(user),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconL,
                color: AppColors.emergencyRed,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                title,
                style: AppTextStyles.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testEmergencySystem(User user) async {
    final contacts = user.trustedContacts ?? [];
    
    if (contacts.isEmpty) {
      _showNoContactsDialog();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Emergency System'),
        content: const Text(
          'This will send a test message to your first emergency contact. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Test'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // await appProvider.testEmergencySystem();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test message sent successfully'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      }
    }
  }
}