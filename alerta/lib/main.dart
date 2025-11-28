import 'package:CareAlert/providers/app_provider.dart';
import 'package:CareAlert/providers/navigation_provider.dart';
import 'package:CareAlert/providers/user.provider.dart';
import 'package:CareAlert/screens/add_contact_screen.dart';
import 'package:CareAlert/screens/contact_screen.dart';
import 'package:CareAlert/screens/home_screen.dart';
import 'package:CareAlert/screens/intro_screen.dart';
import 'package:CareAlert/screens/login_screen.dart';
import 'package:CareAlert/screens/main_screen.dart';
import 'package:CareAlert/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'services/storage_service.dart';
import 'services/location_service.dart';
import 'services/emergency_service.dart'; // FIXED: Changed from emergency_service.dart
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set preferred orientations (portrait only for emergency app)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final storageService = StorageService();
  final locationService = LocationService();
  // FIXED: Get the singleton instance correctly
  final emergencyService = EmergencyAlertService(
    LocationService: locationService,
    storageService: storageService,
  );

  // Initialize FCM if needed
  try {
    await emergencyService.initializeFCM();
  } catch (e) {
    debugPrint('FCM initialization error: $e');
    // Continue anyway - FCM is not critical for app startup
  }

  runApp(PersonalSafetyApp(
    storageService: storageService,
    locationService: locationService,
    emergencyService: emergencyService,
  ));
}

class PersonalSafetyApp extends StatelessWidget {
  final StorageService storageService;
  final LocationService locationService;
  final EmergencyAlertService emergencyService;

  const PersonalSafetyApp({
    super.key,
    required this.storageService,
    required this.locationService,
    required this.emergencyService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(
            storageService: storageService,
            locationService: locationService,
            emergencyService: emergencyService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Care Alert',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routes: {
          SplashScreen.routeName: (context) => const SplashScreen(),
          IntroScreen.routeName: (context) => const IntroScreen(),
          SignUpScreen.routeName: (context) => const SignUpScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          ContactScreen.routeName: (context) => const ContactScreen(),
          AddContactScreen.routeName: (context) => const AddContactScreen(),
          MainScreen.routeName: (context) => const MainScreen(),
        },
      ),
    );
  }

  /// Build the app theme with emergency-focused design
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emergencyRed,
        brightness: Brightness.light,
        primary: AppColors.emergencyRed,
        secondary: AppColors.safeGreen,
        error: AppColors.error,
        surface: AppColors.backgroundLight,
        onSurface: AppColors.textPrimary,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emergencyRed,
          foregroundColor: AppColors.textOnDark,
          textStyle: AppTextStyles.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emergencyRed,
          textStyle: AppTextStyles.buttonMedium,
          side: const BorderSide(color: AppColors.emergencyRed, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emergencyRed,
          textStyle: AppTextStyles.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mediumGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emergencyRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedItemColor: AppColors.emergencyRed,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
      ),

      // Scaffold Theme
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineMedium: AppTextStyles.h4,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.buttonMedium,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),
    );
  }
}
