// lib/screens/auth/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/auth_header.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  bool _isEmailVerified = false;
  int _resendCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    if (user.emailVerified) {
      setState(() => _isEmailVerified = true);
      _timer?.cancel();
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Email verified! Redirecting...',
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/mode_selection');
          }
        });
      }
      return;
    }

    // Check every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await user.reload();
      if (user.emailVerified && mounted) {
        setState(() => _isEmailVerified = true);
        timer.cancel();
        CustomSnackBar.show(
          context,
          'Email verified! Redirecting...',
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/mode_selection');
          }
        });
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not found');

      await user.sendEmailVerification();
      _resendCount++;
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Verification email resent! Check your inbox.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to resend: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: 'Verify Your Email',
                subtitle: 'We sent a verification link to your email',
              ),
              const SizedBox(height: 48),
              // Icon
              Icon(
                _isEmailVerified ? Icons.check_circle : Icons.email_outlined,
                size: 80,
                color: _isEmailVerified ? Colors.green : Colors.blue,
              ),
              const SizedBox(height: 24),
              // Status text
              Text(
                _isEmailVerified
                    ? 'Email Verified!'
                    : 'Please check your inbox',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isEmailVerified
                    ? 'Your email has been verified successfully.'
                    : 'Click the link in the email to verify your account.\n\n'
                        'If you don\'t see it, check your spam folder.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_isEmailVerified) ...[
                Text(
                  'Resend attempts: $_resendCount / 5',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: _resendCount < 5 ? _resendVerificationEmail : null,
                  text: 'Resend Verification Email',
                  isLoading: _isLoading,
                  type: ButtonType.outline,
                  size: ButtonSize.medium,
                ),
              ],
              const SizedBox(height: 24),
              if (!_isEmailVerified) ...[
                TextButton(
                  onPressed: _resendCount < 5 ? _resendVerificationEmail : null,
                  child: const Text(
                    'Didn\'t receive the email?',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_isEmailVerified)
                CustomButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/mode_selection');
                  },
                  text: 'Continue',
                  type: ButtonType.primary,
                  size: ButtonSize.large,
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
