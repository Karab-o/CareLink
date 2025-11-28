import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';

// Place this file in: lib/screens/email_verification_screen.dart

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isResending = false;
  int _countdown = 60;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    // Check verification status every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.reloadUser();
    
    if (authService.isEmailVerified) {
      _timer?.cancel();
      // Navigate to main app - AppWrapper will handle this automatically
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _canResend = false;
      _countdown = 60;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Start countdown timer
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown == 0) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _canResend = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _countdown--;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _canResend = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userEmail = authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            label: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRedLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 60,
                    color: AppColors.emergencyRed,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'We\'ve sent a verification email to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emergencyRed,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                  Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.emergencyRed.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructionItem(
                        '1. Check your email inbox',
                        Icons.inbox,
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        '2. Click the verification link',
                        Icons.link,
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        '3. Return to this screen',
                        Icons.phone_android,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Resend button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canResend && !_isResending 
                        ? _resendVerificationEmail 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    icon: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isResending
                          ? 'Sending...'
                          : _canResend
                              ? 'Resend Verification Email'
                              : 'Resend in ${_countdown}s',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Check spam folder note
                Text(
                  'Don\'t see the email? Check your spam folder',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Auto-checking indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.emergencyRed.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Checking verification status...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.emergencyRed,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}