import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DemographicsWidget extends StatefulWidget {
  final Function(String?, String?) onDataChanged;
  final String? selectedAgeRange;
  final String? selectedBMIRange;

  const DemographicsWidget({
    Key? key,
    required this.onDataChanged,
    this.selectedAgeRange,
    this.selectedBMIRange,
  }) : super(key: key);

  @override
  State<DemographicsWidget> createState() => _DemographicsWidgetState();
}

class _DemographicsWidgetState extends State<DemographicsWidget> {
  String? _selectedAgeRange;
  String? _selectedBMIRange;

  final List<String> _ageRanges = [
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55-64',
    '65+',
  ];

  final List<String> _bmiRanges = [
    'Under 18.5',
    '18.5-24.9',
    '25.0-29.9',
    '30.0-34.9',
    '35.0+',
    'I\'m not sure',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAgeRange = widget.selectedAgeRange;
    _selectedBMIRange = widget.selectedBMIRange;
  }

  void _updateAgeRange(String? value) {
    setState(() {
      _selectedAgeRange = value;
    });
    widget.onDataChanged(_selectedAgeRange, _selectedBMIRange);
  }

  void _updateBMIRange(String? value) {
    setState(() {
      _selectedBMIRange = value;
    });
    widget.onDataChanged(_selectedAgeRange, _selectedBMIRange);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional information',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Help us provide more accurate recommendations (optional)',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4.h),
        _buildAgeRangeSection(),
        SizedBox(height: 4.h),
        _buildBMIRangeSection(),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'This information helps optimize vitamin D synthesis recommendations based on your body composition.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgeRangeSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'cake',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Age Range',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              Spacer(),
              if (_selectedAgeRange != null)
                TextButton(
                  onPressed: () => _updateAgeRange(null),
                  child: Text(
                    'Clear',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _ageRanges
                .map((range) => _buildSelectionChip(
                      range,
                      _selectedAgeRange == range,
                      () => _updateAgeRange(range),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIRangeSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'monitor_weight',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'BMI Range',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              Spacer(),
              if (_selectedBMIRange != null)
                TextButton(
                  onPressed: () => _updateBMIRange(null),
                  child: Text(
                    'Clear',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _bmiRanges
                .map((range) => _buildSelectionChip(
                      range,
                      _selectedBMIRange == range,
                      () => _updateBMIRange(range),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionChip(
      String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.onPrimary
                  : AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
