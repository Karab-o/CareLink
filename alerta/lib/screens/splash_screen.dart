import 'dart:async';
import 'package:CareAlert/screens/intro_screen.dart';
import 'package:CareAlert/screens/main_screen.dart';
import 'package:CareAlert/screens/signup_screen.dart';
import 'package:CareAlert/services/util.dart';
import 'package:flutter/material.dart'; 

  const String routeName = '/splash';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future checkFirstSeen() async {
    final isInitiated = await isAppInitiated();

    if (!isInitiated) {
      setIsAppInitiated();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        IntroScreen.routeName,
        (route) => false,
      );
      return;
    }
    final user = await getUser();
    user.fold(
      (l) => Navigator.of(context).pushNamedAndRemoveUntil(
        MainScreen.routeName,
        (route) => false,
      ),
      (r) {
        if (r.id!.isEmpty) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            SignUpScreen.routeName,
            (route) => false,
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            MainScreen.routeName,
            (route) => false,
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () async => await checkFirstSeen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(),
    );
  }
}
