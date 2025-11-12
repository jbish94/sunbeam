import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class BMISelectionScreen extends StatefulWidget {
  final String? initialBMIRange;
  final Function(String) onBMISelected;

  const BMISelectionScreen({
    Key? key,
    this.initialBMIRange,
    required this.onBMISelected,
  }) : super(key: key);

  @override
  State<BMISelectionScreen> createState() => _BMISelectionScreenState();
}

class _BMISelectionScreenState extends State<BMISelectionScreen> {
  String? _selectedBMIRange;

  final List<Map<String, String>> _bmiRanges = [
    {
      'range': 'Under 18.5',
      'description': 'Underweight',
    },
    {
      'range': '18.5-24.9',
      'description': 'Normal Weight',
    },
    {
      'range': '25.0-29.9',
      'description': 'Overweight',
    },
    {
      'range': '30.0-34.9',
      'description': 'Obesity Class I',
    },
    {
      'range': '35.0+',
      'description': 'Obesity Class II+',
    },
    {
      'range': 'I\'m not sure',
      'description': 'Skip this for now',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedBMIRange = widget.initialBMIRange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'BMI Range',
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),
                  Text(
                    'Select your BMI range',
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'This helps us provide more accurate vitamin D synthesis recommendations based on your body composition.',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                    ),
                    itemCount: _bmiRanges.length,
                    itemBuilder: (context, index) {
                      return _buildBMIRangeCard(_bmiRanges[index]);
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBMIRangeCard(Map<String, String> bmiRange) {
    final bool isSelected = _selectedBMIRange == bmiRange['range'];
    final bool isUnsure = bmiRange['range'] == 'I\'m not sure';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBMIRange = bmiRange['range'];
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
                : isUnsure
                    ? AppTheme.lightTheme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : AppTheme.lightTheme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : isUnsure
                      ? AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.5)
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : isUnsure
                              ? AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.2)
                              : AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: isUnsure ? 'help_outline' : 'monitor_weight',
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : isUnsure
                              ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                              : AppTheme.lightTheme.colorScheme.primary,
                      size: 4.w,
                    ),
                  ),
                  if (isSelected)
                    CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 4.w,
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                bmiRange['range']!,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                bmiRange['description']!,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
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
      child: ElevatedButton(
        onPressed: _selectedBMIRange != null
            ? () {
                widget.onBMISelected(_selectedBMIRange!);
                Navigator.pop(context);
              }
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Update BMI Range'),
            SizedBox(width: 2.w),
            CustomIconWidget(
              iconName: 'check',
              color: _selectedBMIRange != null
                  ? AppTheme.lightTheme.colorScheme.onPrimary
                  : AppTheme.lightTheme.colorScheme.onPrimary
                      .withValues(alpha: 0.5),
              size: 5.w,
            ),
          ],
        ),
      ),
    );
  }
}
