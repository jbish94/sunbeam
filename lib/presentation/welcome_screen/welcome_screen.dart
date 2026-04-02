import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import './widgets/auth_form_widget.dart';
import './widgets/privacy_footer_widget.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(context),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  children: [
                    SizedBox(height: 3.h),
                    AuthFormWidget(
                      onAuthSuccess: (context) =>
                          _handleAuthSuccess(context),
                    ),
                    SizedBox(height: 2.h),
                    _buildGuestOption(context),
                    SizedBox(height: 2.h),
                    const PrivacyFooterWidget(),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 30.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
            AppTheme.getAccentColor(true).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            padding: EdgeInsets.all(3.5.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4.w),
            ),
            child: CustomImageWidget(
              imageUrl: 'assets/images/img_app_logo.svg',
              width: 11.w,
              height: 11.w,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Sunbeam',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Your personal sun exposure companion',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestOption(BuildContext context) {
    return TextButton(
      onPressed: () =>
          Navigator.pushReplacementNamed(context, AppRoutes.home),
      child: Text(
        'Continue without an account',
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  static Future<void> _handleAuthSuccess(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !context.mounted) return;

    // Check if onboarding has been completed for this account
    try {
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('preferences')
          .eq('id', user.id)
          .maybeSingle();

      final prefs = profile?['preferences'] as Map<String, dynamic>?;
      final onboardingDone = prefs?['onboarding_completed'] as bool? ?? false;

      if (!context.mounted) return;
      if (onboardingDone) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
      }
    }
  }
}
