import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import './widgets/goal_selection_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/skin_type_selector_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 2;

  // Onboarding data
  List<String> _selectedGoals = [];
  String? _selectedSkinType;

  bool get _canProceedFromCurrentStep {
    switch (_currentStep) {
      case 1:
        return _selectedGoals.isNotEmpty;
      case 2:
        return _selectedSkinType != null;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps && _canProceedFromCurrentStep) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == _totalSteps && _canProceedFromCurrentStep) {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    try {
      if (user != null) {
        // Persist skin type to user_profiles
        final skinTypeInt = _skinTypeToInt(_selectedSkinType);
        await client.from('user_profiles').update({
          'skin_type': skinTypeInt,
          'preferences': {'onboarding_completed': true},
        }).eq('id', user.id);

        // Persist selected goals to user_goals (upsert in case row exists)
        await client.from('user_goals').upsert({
          'user_id': user.id,
          'primary_goal_type': _selectedGoals.isNotEmpty
              ? _goalLabelToType(_selectedGoals.first)
              : 'sessions_per_day',
          'enable_secondary_goal': _selectedGoals.length > 1,
          'secondary_goal_type': _selectedGoals.length > 1
              ? _goalLabelToType(_selectedGoals[1])
              : null,
        });
      }
    } catch (e) {
      debugPrint('[Onboarding] Supabase sync error: $e');
      // Non-fatal — still navigate to home
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  int _skinTypeToInt(String? roman) {
    switch (roman) {
      case 'I':
        return 1;
      case 'II':
        return 2;
      case 'III':
        return 3;
      case 'IV':
        return 4;
      case 'V':
        return 5;
      case 'VI':
        return 6;
      default:
        return 2;
    }
  }

  String _goalLabelToType(String label) {
    switch (label) {
      case 'Vitamin D Optimization':
        return 'sessions_per_day';
      case 'Mood Enhancement':
        return 'minutes_per_session';
      case 'Better Sleep':
        return 'sessions_per_week';
      default:
        return 'sessions_per_day';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ProgressIndicatorWidget(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildGoalSelectionStep(),
                  _buildSkinTypeStep(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSelectionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: GoalSelectionWidget(
        selectedGoals: _selectedGoals,
        onGoalsChanged: (goals) {
          setState(() {
            _selectedGoals = goals;
          });
        },
      ),
    );
  }

  Widget _buildSkinTypeStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: SkinTypeSelectorWidget(
        selectedSkinType: _selectedSkinType,
        onSkinTypeChanged: (skinType) {
          setState(() {
            _selectedSkinType = skinType;
          });
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'arrow_back',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text('Back'),
                  ],
                ),
              ),
            )
          else
            Expanded(child: SizedBox()),
          SizedBox(width: 4.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceedFromCurrentStep ? _nextStep : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_currentStep == _totalSteps ? 'Get Started' : 'Next'),
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName:
                        _currentStep == _totalSteps ? 'check' : 'arrow_forward',
                    color: _canProceedFromCurrentStep
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.onPrimary
                            .withValues(alpha: 0.5),
                    size: 5.w,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}