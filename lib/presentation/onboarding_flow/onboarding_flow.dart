import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import './widgets/burn_history_widget.dart';
import './widgets/demographics_widget.dart';
import './widgets/goal_selection_widget.dart';
import './widgets/location_permission_widget.dart';
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
  final int _totalSteps = 5;

  // Onboarding data
  List<String> _selectedGoals = [];
  String? _selectedSkinType;
  bool _hasBurnHistory = false;
  double _sensitivity = 5.0;
  String? _selectedAgeRange;
  String? _selectedBMIRange;
  bool _hasLocationPermission = false;
  String? _manualLocation;

  bool get _canProceedFromCurrentStep {
    switch (_currentStep) {
      case 1:
        return _selectedGoals.isNotEmpty;
      case 2:
        return _selectedSkinType != null;
      case 3:
        return true; // Burn history and sensitivity always have default values
      case 4:
        return true; // Demographics are optional
      case 5:
        return _hasLocationPermission ||
            (_manualLocation != null && _manualLocation!.isNotEmpty);
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
    try {
      // Save onboarding completion status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);

      // Save onboarding data (in a real app, this would be saved to backend)
      await prefs.setStringList('selected_goals', _selectedGoals);
      await prefs.setString('selected_skin_type', _selectedSkinType ?? '');
      await prefs.setBool('has_burn_history', _hasBurnHistory);
      await prefs.setDouble('sensitivity', _sensitivity);
      await prefs.setString('selected_age_range', _selectedAgeRange ?? '');
      await prefs.setString('selected_bmi_range', _selectedBMIRange ?? '');
      await prefs.setBool('has_location_permission', _hasLocationPermission);
      await prefs.setString('manual_location', _manualLocation ?? '');

      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      // If error saving, still navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
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
                  _buildBurnHistoryStep(),
                  _buildDemographicsStep(),
                  _buildLocationPermissionStep(),
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

  Widget _buildBurnHistoryStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: BurnHistoryWidget(
        hasBurnHistory: _hasBurnHistory,
        sensitivity: _sensitivity,
        onDataChanged: (burnHistory, sensitivity) {
          setState(() {
            _hasBurnHistory = burnHistory;
            _sensitivity = sensitivity;
          });
        },
      ),
    );
  }

  Widget _buildDemographicsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: DemographicsWidget(
        selectedAgeRange: _selectedAgeRange,
        selectedBMIRange: _selectedBMIRange,
        onDataChanged: (ageRange, bmiRange) {
          setState(() {
            _selectedAgeRange = ageRange;
            _selectedBMIRange = bmiRange;
          });
        },
      ),
    );
  }

  Widget _buildLocationPermissionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: LocationPermissionWidget(
        hasLocationPermission: _hasLocationPermission,
        manualLocation: _manualLocation,
        onPermissionChanged: (hasPermission, location) {
          setState(() {
            _hasLocationPermission = hasPermission;
            _manualLocation = location;
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