import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AppleSigninButtonWidget extends StatefulWidget {
  final VoidCallback onSignInSuccess;

  const AppleSigninButtonWidget({
    Key? key,
    required this.onSignInSuccess,
  }) : super(key: key);

  @override
  State<AppleSigninButtonWidget> createState() =>
      _AppleSigninButtonWidgetState();
}

class _AppleSigninButtonWidgetState extends State<AppleSigninButtonWidget> {
  bool _isSigningIn = false;

  void _handleAppleSignIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      // TODO: Implement actual Apple Sign In functionality
      // For now, this is just UI implementation

      // Simulate sign in process
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Apple Sign In functionality will be implemented with backend integration'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            duration: Duration(seconds: 3),
          ),
        );

        // For now, proceed to onboarding
        widget.onSignInSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAppleSignInButton(),
        SizedBox(height: 2.h),
        _buildSignInNote(),
      ],
    );
  }

  Widget _buildAppleSignInButton() {
    return Container(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSigningIn ? null : _handleAppleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[800],
          disabledForegroundColor: Colors.grey[400],
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: _isSigningIn
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.apple,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Register with Apple',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSignInNote() {
    return Text(
      'Quick and secure registration with Face ID or Touch ID',
      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
      textAlign: TextAlign.center,
    );
  }
}
