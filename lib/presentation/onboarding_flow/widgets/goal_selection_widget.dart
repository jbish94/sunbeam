import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GoalSelectionWidget extends StatefulWidget {
  final Function(List<String>) onGoalsChanged;
  final List<String> selectedGoals;

  const GoalSelectionWidget({
    Key? key,
    required this.onGoalsChanged,
    required this.selectedGoals,
  }) : super(key: key);

  @override
  State<GoalSelectionWidget> createState() => _GoalSelectionWidgetState();
}

class _GoalSelectionWidgetState extends State<GoalSelectionWidget> {
  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'vitamin_d',
      'title': 'Vitamin D Optimization',
      'description': 'Maximize vitamin D synthesis safely',
      'icon': 'wb_sunny',
    },
    {
      'id': 'better_sleep',
      'title': 'Better Sleep',
      'description': 'Improve circadian rhythm naturally',
      'icon': 'bedtime',
    },
    {
      'id': 'mood_enhancement',
      'title': 'Mood Enhancement',
      'description': 'Boost mood through natural light',
      'icon': 'sentiment_very_satisfied',
    },
  ];

  void _toggleGoal(String goalId) {
    List<String> updatedGoals = List.from(widget.selectedGoals);

    if (updatedGoals.contains(goalId)) {
      updatedGoals.remove(goalId);
    } else {
      updatedGoals.add(goalId);
    }

    widget.onGoalsChanged(updatedGoals);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are your wellness goals?',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Select all that apply to personalize your sun exposure recommendations',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4.h),
        ..._goals.map((goal) => _buildGoalChip(goal)).toList(),
      ],
    );
  }

  Widget _buildGoalChip(Map<String, dynamic> goal) {
    final bool isSelected = widget.selectedGoals.contains(goal['id']);

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleGoal(goal['id']),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: goal['icon'],
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['title'],
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        goal['description'],
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
