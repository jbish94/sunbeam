import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/duration_picker_widget.dart';
import './widgets/mood_energy_slider_widget.dart';
import './widgets/notes_input_widget.dart';
import './widgets/protection_selector_widget.dart';
import './widgets/session_summary_widget.dart';
import './widgets/time_picker_widget.dart';

class LogSessionScreen extends StatefulWidget {
  const LogSessionScreen({Key? key}) : super(key: key);

  @override
  State<LogSessionScreen> createState() => _LogSessionScreenState();
}

class _LogSessionScreenState extends State<LogSessionScreen> {
  DateTime _selectedTime = DateTime.now();
  int _selectedDuration = 30;
  List<String> _selectedProtections = ['None'];
  double _moodLevel = 3.0;
  double _energyLevel = 3.0;
  String _notes = '';
  bool _isRecommendedWindow = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkIfRecommendedWindow();
  }

  void _checkIfRecommendedWindow() {
    // Mock logic to determine if current time is in recommended window
    final currentHour = DateTime.now().hour;
    _isRecommendedWindow = currentHour >= 9 && currentHour <= 11 ||
        currentHour >= 15 && currentHour <= 17;
  }

  bool get _canSave {
    return _selectedDuration > 0 && _selectedProtections.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => _showCancelDialog(),
        icon: CustomIconWidget(
          iconName: 'close',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 6.w,
        ),
      ),
      title: Text(
        'Log Sun Session',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _canSave && !_isSaving ? _saveSession : null,
          child: _isSaving
              ? SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                )
              : Text(
                  'Save',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: _canSave
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            TimePickerWidget(
              selectedTime: _selectedTime,
              onTimeChanged: (time) {
                setState(() {
                  _selectedTime = time;
                  _checkIfRecommendedWindow();
                });
              },
            ),
            SizedBox(height: 3.h),
            DurationPickerWidget(
              selectedDuration: _selectedDuration,
              onDurationChanged: (duration) {
                setState(() {
                  _selectedDuration = duration;
                });
              },
            ),
            SizedBox(height: 3.h),
            ProtectionSelectorWidget(
              selectedProtections: _selectedProtections,
              onProtectionChanged: (protections) {
                setState(() {
                  _selectedProtections = protections;
                });
              },
            ),
            SizedBox(height: 3.h),
            MoodEnergySliderWidget(
              moodLevel: _moodLevel,
              energyLevel: _energyLevel,
              onMoodChanged: (mood) {
                setState(() {
                  _moodLevel = mood;
                });
              },
              onEnergyChanged: (energy) {
                setState(() {
                  _energyLevel = energy;
                });
              },
            ),
            SizedBox(height: 3.h),
            NotesInputWidget(
              notes: _notes,
              onNotesChanged: (notes) {
                setState(() {
                  _notes = notes;
                });
              },
              isRecommendedWindow: _isRecommendedWindow,
            ),
            SizedBox(height: 3.h),
            SessionSummaryWidget(
              startTime: _selectedTime,
              duration: _selectedDuration,
              protections: _selectedProtections,
              moodLevel: _moodLevel,
              energyLevel: _energyLevel,
              notes: _notes,
              isRecommendedWindow: _isRecommendedWindow,
            ),
            SizedBox(height: 10.h), // Extra space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: _canSave && !_isSaving ? _saveSession : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canSave
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.2),
              foregroundColor: _canSave
                  ? AppTheme.lightTheme.colorScheme.onPrimary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.4),
              elevation: _canSave ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
            ),
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightTheme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Saving Session...',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'save',
                        color: _canSave
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                            : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Save Sun Session',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        title: Text(
          'Discard Session?',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to discard this session? All entered data will be lost.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Editing',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Discard',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSession() async {
    if (!_canSave || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // Haptic feedback for save action
    HapticFeedback.mediumImpact();

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Show success animation
      _showSuccessDialog();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save session. Please try again.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.getSuccessColor(true).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.getSuccessColor(true),
                size: 12.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Session Saved!',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your sun exposure session has been logged successfully.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home-screen');
                },
                child: Text('View Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
