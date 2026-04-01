import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    setState(() => _isSigningIn = true);

    try {
      // On mobile the OAuth callback is handled via the deep-link URL scheme
      // configured in ios/Runner/Info.plist (CFBundleURLSchemes).
      // On web, Supabase handles the redirect automatically.
      // Prerequisites:
      //   1. Supabase Dashboard → Auth → Providers → Apple → enabled
      //   2. Apple Developer: App ID with "Sign In with Apple" capability
      //   3. Apple Developer: Services ID + domain/redirect URL registered
      //   4. iOS Info.plist: add URL scheme matching your Supabase callback URL
      const redirectUrl = kIsWeb
          ? null
          : 'io.supabase.sunbeam://login-callback/';

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // The auth state change is handled by Supabase's deep-link listener.
      // onSignInSuccess will be called by the auth state listener in main/welcome.
      if (mounted) widget.onSignInSuccess();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in failed. Please try again.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
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
