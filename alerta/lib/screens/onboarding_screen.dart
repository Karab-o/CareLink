import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';
import '../providers/app_provider.dart';
import 'signup_screen.dart';  // ADD THIS LINE
import 'login_screen.dart'; 
/// Onboarding screen to introduce the app and collect basic information
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  
  // Track form validity
  bool _isNameValid = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.removeListener(_validateForm);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _medicalInfoController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _nameController.text.trim().isNotEmpty;
    if (_isNameValid != isValid) {
      setState(() {
        _isNameValid = isValid;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      
      // Create user profile if name is provided
      if (_nameController.text.trim().isNotEmpty) {
        await appProvider.createUserProfile(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty 
              ? null 
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty 
              ? null 
              : _emailController.text.trim(),
          emergencyMedicalInfo: _medicalInfoController.text.trim().isEmpty 
              ? null 
              : _medicalInfoController.text.trim(),
        );
      }
      
      await appProvider.completeOnboarding();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  bool _canProceed() {
    if (_isProcessing) return false;
    
    // On profile page (page 2), require name
    if (_currentPage == 2) {
      return _isNameValid;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildFeaturesPage(),
                  _buildProfilePage(),
                  _buildPermissionsPage(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: List.generate(_totalPages, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? AppColors.emergencyRed
                    : AppColors.mediumGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
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
          
          const Text(
            'Welcome to\nCare Alert',
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
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
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
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
    );
  }

  Widget _buildFeaturesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          const Text(
            'Key Features',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          _buildFeatureItem(
            icon: Icons.emergency,
            title: 'Emergency Alerts',
            description: 'Send instant alerts to your trusted contacts with your location',
            color: AppColors.emergencyRed,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildFeatureItem(
            icon: Icons.location_on,
            title: 'Location Sharing',
            description: 'Automatically share your location during emergencies',
            color: AppColors.info,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildFeatureItem(
            icon: Icons.contacts,
            title: 'Trusted Contacts',
            description: 'Manage your emergency contacts and trusted circle',
            color: AppColors.safeGreen,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          _buildFeatureItem(
            icon: Icons.history,
            title: 'Alert History',
            description: 'Keep track of all sent alerts and their status',
            color: AppColors.warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimensions.paddingL),
          
          const Text(
            'Set Up Your Profile',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingS),
          
          Text(
            'This information helps emergency contacts identify you.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingXL),
          
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              filled: true,
              fillColor: AppColors.backgroundGray,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              filled: true,
              fillColor: AppColors.backgroundGray,
            ),
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              filled: true,
              fillColor: AppColors.backgroundGray,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          TextField(
            controller: _medicalInfoController,
            decoration: InputDecoration(
              labelText: 'Emergency Medical Info',
              hintText: 'Allergies, medications, medical conditions...',
              prefixIcon: const Icon(Icons.medical_services),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              filled: true,
              fillColor: AppColors.backgroundGray,
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                '* Required field',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          const Text(
            'Permissions Required',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
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
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
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
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isRequired,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  Flexible(
                    child: Text(
                      title,
                      style: AppTextStyles.h4,
                    ),
                  ),
                  if (isRequired) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Required',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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

 Widget _buildNavigationButtons() {
  return Container(
    padding: const EdgeInsets.all(AppDimensions.paddingL),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _previousPage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.mediumGray),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            
            if (_currentPage > 0) 
              const SizedBox(width: AppDimensions.paddingM),
            
            Expanded(
              flex: _currentPage == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _currentPage == _totalPages - 1
                    ? () {
                        // Direct navigation instead of named route
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      }
                    : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (_currentPage == _totalPages - 1) ...[
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Direct navigation
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
}