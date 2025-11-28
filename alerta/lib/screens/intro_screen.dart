import 'package:CareAlert/constants/app_colors.dart';
import 'package:CareAlert/constants/app_dimensions.dart';
import 'package:CareAlert/constants/app_text_styles.dart';
import 'package:CareAlert/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  static const String routeName = '/intro';

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Icon(
            icon,
            color: color,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isRequired,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTextStyles.h4),
                  if (isRequired) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Required',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            titleWidget: const Text(
              'Welcome to\nPersonal Safety',
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            bodyWidget: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // App Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.emergencyRedLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 60,
                      color: AppColors.emergencyRed,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  Text(
                    'Your personal safety companion that helps you stay connected with trusted contacts and emergency services when you need help most.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: AppDimensions.iconM,
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: Text(
                            'This app is designed to help in emergency situations. Please set it up carefully.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PageViewModel(
            titleWidget: const Text(
              'Key Features',
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            bodyWidget: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeatureItem(
                    icon: Icons.emergency,
                    title: 'Emergency Alerts',
                    description:
                        'Send instant alerts to your trusted contacts with your location',
                    color: AppColors.emergencyRed,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  _buildFeatureItem(
                    icon: Icons.location_on,
                    title: 'Location Sharing',
                    description:
                        'Automatically share your location during emergencies',
                    color: AppColors.info,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  _buildFeatureItem(
                    icon: Icons.contacts,
                    title: 'Trusted Contacts',
                    description:
                        'Manage your emergency contacts and trusted circle',
                    color: AppColors.safeGreen,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  _buildFeatureItem(
                    icon: Icons.history,
                    title: 'Alert History',
                    description:
                        'Keep track of all sent alerts and their status',
                    color: AppColors.warningOrange,
                  ),
                ],
              ),
            ),
          ),
          PageViewModel(
            titleWidget: const Text(
              'Permissions Required',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            bodyWidget: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'For the app to work effectively in emergencies, we need access to:',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  _buildPermissionItem(
                    icon: Icons.location_on,
                    title: 'Location Access',
                    description: 'To share your location during emergencies',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  _buildPermissionItem(
                    icon: Icons.phone,
                    title: 'Phone Access',
                    description: 'To make emergency calls and send SMS',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  _buildPermissionItem(
                    icon: Icons.contacts,
                    title: 'Contacts Access',
                    description: 'To easily add emergency contacts',
                    isRequired: false,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRedLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security,
                          color: AppColors.emergencyRed,
                          size: AppDimensions.iconM,
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: Text(
                            'Your privacy is important. Location data is only shared during emergencies.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.emergencyRedDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
        showNextButton: true,
        next: const Text('Next'),
        showSkipButton: true,
        skip: const Text('Skip'),
        done: const Text('Done'),
        onDone: () {
          Navigator.pushReplacementNamed(context, SignUpScreen.routeName);
        },
      ),
    );
  }
}
