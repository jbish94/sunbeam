import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class GoalEditScreen extends StatefulWidget {
  final Map<String, dynamic> currentGoals;
  final Function(Map<String, dynamic>) onGoalsChanged;

  const GoalEditScreen({
    Key? key,
    required this.currentGoals,
    required this.onGoalsChanged,
  }) : super(key: key);

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _sessionsPerDayController;
  late TextEditingController _minutesPerSessionController;
  late TextEditingController _sessionsPerWeekController;
  late TextEditingController _totalMinutesPerWeekController;

  // Goal type selection
  String _selectedGoalType = 'sessions_per_day';
  bool _enableSecondaryGoal = false;
  String _selectedSecondaryGoalType = 'minutes_per_session';

  final List<Map<String, dynamic>> _goalTypes = [
    {
      'id': 'sessions_per_day',
      'title': 'Sessions per Day',
      'description': 'Number of sun exposure sessions daily',
      'unit': 'sessions',
      'icon': 'wb_sunny',
    },
    {
      'id': 'minutes_per_session',
      'title': 'Minutes per Session',
      'description': 'Duration of each sun exposure session',
      'unit': 'minutes',
      'icon': 'timer',
    },
    {
      'id': 'sessions_per_week',
      'title': 'Sessions per Week',
      'description': 'Total sessions for the week',
      'unit': 'sessions',
      'icon': 'date_range',
    },
    {
      'id': 'total_minutes_per_week',
      'title': 'Total Minutes per Week',
      'description': 'Cumulative weekly sun exposure',
      'unit': 'minutes',
      'icon': 'schedule',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _sessionsPerDayController = TextEditingController(
      text: widget.currentGoals['sessions_per_day']?.toString() ?? '2',
    );
    _minutesPerSessionController = TextEditingController(
      text: widget.currentGoals['minutes_per_session']?.toString() ?? '15',
    );
    _sessionsPerWeekController = TextEditingController(
      text: widget.currentGoals['sessions_per_week']?.toString() ?? '14',
    );
    _totalMinutesPerWeekController = TextEditingController(
      text: widget.currentGoals['total_minutes_per_week']?.toString() ?? '210',
    );

    _selectedGoalType =
        widget.currentGoals['primary_goal_type'] ?? 'sessions_per_day';
    _enableSecondaryGoal =
        widget.currentGoals['enable_secondary_goal'] ?? false;
    _selectedSecondaryGoalType =
        widget.currentGoals['secondary_goal_type'] ?? 'minutes_per_session';
  }

  @override
  void dispose() {
    _sessionsPerDayController.dispose();
    _minutesPerSessionController.dispose();
    _sessionsPerWeekController.dispose();
    _totalMinutesPerWeekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Goals',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveGoals,
            child: Text(
              'Save',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionCard(),
              SizedBox(height: 3.h),
              _buildPrimaryGoalSection(),
              SizedBox(height: 3.h),
              _buildSecondaryGoalSection(),
              SizedBox(height: 3.h),
              _buildGoalPreview(),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.primaryColor,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'How Goals Work',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Set your sun exposure targets based on your wellness goals. You can track by sessions per day, session duration, or weekly totals. Enable a secondary goal for comprehensive tracking.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Goal',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        _buildGoalTypeSelector(_selectedGoalType, (value) {
          setState(() {
            _selectedGoalType = value;
          });
        }),
        SizedBox(height: 2.h),
        _buildGoalInputField(_selectedGoalType),
      ],
    );
  }

  Widget _buildSecondaryGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Secondary Goal (Optional)',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Switch(
              value: _enableSecondaryGoal,
              onChanged: (value) {
                setState(() {
                  _enableSecondaryGoal = value;
                });
              },
              activeColor: AppTheme.lightTheme.primaryColor,
            ),
          ],
        ),
        if (_enableSecondaryGoal) ...[
          SizedBox(height: 2.h),
          _buildGoalTypeSelector(_selectedSecondaryGoalType, (value) {
            setState(() {
              _selectedSecondaryGoalType = value;
            });
          }, excludeType: _selectedGoalType),
          SizedBox(height: 2.h),
          _buildGoalInputField(_selectedSecondaryGoalType),
        ],
      ],
    );
  }

  Widget _buildGoalTypeSelector(String selectedType, Function(String) onChanged,
      {String? excludeType}) {
    final availableTypes =
        _goalTypes.where((type) => type['id'] != excludeType).toList();

    return Column(
      children: availableTypes.map((goalType) {
        final bool isSelected = selectedType == goalType['id'];
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          child: InkWell(
            onTap: () => onChanged(goalType['id']),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
                    : AppTheme.lightTheme.cardColor,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: goalType['icon'],
                      color: isSelected
                          ? Colors.white
                          : AppTheme.lightTheme.primaryColor,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goalType['title'],
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          goalType['description'],
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 6.w,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalInputField(String goalType) {
    final goalInfo = _goalTypes.firstWhere((type) => type['id'] == goalType);
    TextEditingController controller = _getControllerForGoalType(goalType);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target ${goalInfo['title']}',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter target value',
              suffixText: goalInfo['unit'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a target value';
              }
              final intValue = int.tryParse(value);
              if (intValue == null || intValue <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPreview() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal Summary',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          _buildGoalPreviewItem(_selectedGoalType),
          if (_enableSecondaryGoal) ...[
            SizedBox(height: 1.h),
            _buildGoalPreviewItem(_selectedSecondaryGoalType),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalPreviewItem(String goalType) {
    final goalInfo = _goalTypes.firstWhere((type) => type['id'] == goalType);
    final controller = _getControllerForGoalType(goalType);
    final value = controller.text.isEmpty ? '0' : controller.text;

    return Row(
      children: [
        CustomIconWidget(
          iconName: goalInfo['icon'],
          color: AppTheme.lightTheme.primaryColor,
          size: 5.w,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            '${goalInfo['title']}: $value ${goalInfo['unit']}',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  TextEditingController _getControllerForGoalType(String goalType) {
    switch (goalType) {
      case 'sessions_per_day':
        return _sessionsPerDayController;
      case 'minutes_per_session':
        return _minutesPerSessionController;
      case 'sessions_per_week':
        return _sessionsPerWeekController;
      case 'total_minutes_per_week':
        return _totalMinutesPerWeekController;
      default:
        return _sessionsPerDayController;
    }
  }

  void _saveGoals() async {
    if (_formKey.currentState!.validate()) {
      final goals = {
        'primary_goal_type': _selectedGoalType,
        'enable_secondary_goal': _enableSecondaryGoal,
        'secondary_goal_type':
            _enableSecondaryGoal ? _selectedSecondaryGoalType : null,
        'sessions_per_day': int.tryParse(_sessionsPerDayController.text) ?? 2,
        'minutes_per_session':
            int.tryParse(_minutesPerSessionController.text) ?? 15,
        'sessions_per_week':
            int.tryParse(_sessionsPerWeekController.text) ?? 14,
        'total_minutes_per_week':
            int.tryParse(_totalMinutesPerWeekController.text) ?? 210,
      };

      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('primary_goal_type', goals['primary_goal_type'] as String);
      await prefs.setBool(
          'enable_secondary_goal', goals['enable_secondary_goal'] as bool);
      if (goals['secondary_goal_type'] != null) {
        await prefs.setString(
            'secondary_goal_type', goals['secondary_goal_type'] as String);
      }
      await prefs.setInt('sessions_per_day', goals['sessions_per_day'] as int);
      await prefs.setInt('minutes_per_session', goals['minutes_per_session'] as int);
      await prefs.setInt('sessions_per_week', goals['sessions_per_week'] as int);
      await prefs.setInt(
          'total_minutes_per_week', goals['total_minutes_per_week'] as int);

      widget.onGoalsChanged(goals);
      Navigator.pop(context);
    }
  }
}