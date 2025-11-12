import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/mood_energy_chart_widget.dart';
import './widgets/session_frequency_widget.dart';
import './widgets/sun_exposure_progress_widget.dart';
import './widgets/weekly_summary_card_widget.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTimeFrame = 0; // 0: Week, 1: Month, 2: 3 Months
  int _selectedNavIndex = 2; // Set to insights tab
  bool _isLoading = false;
  late AnimationController _animationController;

  // Mock user goal data - synchronized with Home screen
  Map<String, dynamic> userGoals = {
    'primary_goal_type': 'sessions_per_day',
    'enable_secondary_goal': true,
    'secondary_goal_type': 'minutes_per_session',
    'sessions_per_day': 2,
    'minutes_per_session': 15,
    'sessions_per_week': 14,
    'total_minutes_per_week': 210,
  };

  // Mock current progress data - synchronized with Home screen
  Map<String, dynamic> currentProgress = {
    'sessions_today': 1,
    'minutes_today': 15,
    'sessions_this_week': 8,
    'minutes_this_week':
        200, // Updated to match the 200m shown in the description
  };

  // Mock data for insights
  final List<Map<String, dynamic>> weeklySessionData = [
    {
      "day": "Mon",
      "sessions": 1,
      "duration": 25,
      "mood": 4.2,
      "energy": 3.8,
      "uvExposure": 45,
    },
    {
      "day": "Tue",
      "sessions": 0,
      "duration": 0,
      "mood": 0,
      "energy": 0,
      "uvExposure": 0,
    },
    {
      "day": "Wed",
      "sessions": 2,
      "duration": 40,
      "mood": 4.5,
      "energy": 4.1,
      "uvExposure": 78,
    },
    {
      "day": "Thu",
      "sessions": 1,
      "duration": 20,
      "mood": 3.9,
      "energy": 4.3,
      "uvExposure": 35,
    },
    {
      "day": "Fri",
      "sessions": 1,
      "duration": 35,
      "mood": 4.7,
      "energy": 4.6,
      "uvExposure": 62,
    },
    {
      "day": "Sat",
      "sessions": 2,
      "duration": 50,
      "mood": 4.8,
      "energy": 4.9,
      "uvExposure": 95,
    },
    {
      "day": "Sun",
      "sessions": 1,
      "duration": 30,
      "mood": 4.4,
      "energy": 4.2,
      "uvExposure": 58,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      // Removed the leading back arrow completely
      automaticallyImplyLeading: false,
      title: Text(
        'Your Sun Insights',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<int>(
          onSelected: (value) {
            setState(() {
              _selectedTimeFrame = value;
            });
            _refreshData();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 0, child: Text('This Week')),
            PopupMenuItem(value: 1, child: Text('This Month')),
            PopupMenuItem(value: 2, child: Text('Last 3 Months')),
          ],
          child: Container(
            padding: EdgeInsets.all(2.w),
            margin: EdgeInsets.only(right: 3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTimeFrameText(),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 4.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.lightTheme.primaryColor,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(_getProgressSectionTitle()),
            SizedBox(height: 1.h),
            WeeklySummaryCardWidget(
              totalSessions: _getTotalSessions(),
              totalDuration: _getTotalDuration(),
              averageMood: _getAverageMood(),
              averageEnergy: _getAverageEnergy(),
              weeklyGoalProgress: _calculateGoalProgress(),
              animationController: _animationController,
              timePeriod: _getTimePeriod(),
            ),
            SizedBox(height: 3.h),
            _buildSectionHeader('Mood & Energy Trends'),
            SizedBox(height: 1.h),
            MoodEnergyChartWidget(
              weeklyData: weeklySessionData,
              animationController: _animationController,
            ),
            SizedBox(height: 3.h),
            _buildSectionHeader('Session Frequency'),
            SizedBox(height: 1.h),
            SessionFrequencyWidget(
              weeklyData: weeklySessionData,
              animationController: _animationController,
            ),
            SizedBox(height: 3.h),
            _buildSectionHeader('Sun Exposure Progress'),
            SizedBox(height: 1.h),
            SunExposureProgressWidget(
              weeklyData: weeklySessionData,
              recommendedMinutes: _getRecommendedMinutes(),
              animationController: _animationController,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        if (index == _selectedNavIndex) return; // Don't navigate to same tab

        setState(() {
          _selectedNavIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home-screen');
            break;
          case 1:
            Navigator.pushNamed(context, '/log-session-screen');
            break;
          case 2:
            // Already on insights
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile-screen');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: _selectedNavIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'add_circle_outline',
            color: _selectedNavIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Log',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'insights',
            color: _selectedNavIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _selectedNavIndex == 3
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(-0.5, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.3, 0.9, curve: Curves.easeOut),
        ),
      ),
      child: Text(
        title,
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _getTimeFrameText() {
    switch (_selectedTimeFrame) {
      case 0:
        return 'Week';
      case 1:
        return 'Month';
      case 2:
        return '3 Months';
      default:
        return 'Week';
    }
  }

  int _getTotalSessions() {
    return weeklySessionData.fold(
      0,
      (sum, day) => sum + (day['sessions'] as int),
    );
  }

  int _getTotalDuration() {
    return weeklySessionData.fold(
      0,
      (sum, day) => sum + (day['duration'] as int),
    );
  }

  double _getAverageMood() {
    final validMoods = weeklySessionData
        .where((day) => day['mood'] > 0)
        .map((day) => day['mood'] as double);
    if (validMoods.isEmpty) return 0.0;
    return validMoods.reduce((a, b) => a + b) / validMoods.length;
  }

  double _getAverageEnergy() {
    final validEnergy = weeklySessionData
        .where((day) => day['energy'] > 0)
        .map((day) => day['energy'] as double);
    if (validEnergy.isEmpty) return 0.0;
    return validEnergy.reduce((a, b) => a + b) / validEnergy.length;
  }

  // Calculate accurate goal progress based on user's goals and current progress
  double _calculateGoalProgress() {
    final primaryGoalType = userGoals['primary_goal_type'] as String;

    switch (primaryGoalType) {
      case 'sessions_per_day':
        final target = userGoals['sessions_per_day'] as int;
        final current = currentProgress['sessions_today'] as int;
        return target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

      case 'sessions_per_week':
        final target = userGoals['sessions_per_week'] as int;
        final current = currentProgress['sessions_this_week'] as int;
        return target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

      case 'total_minutes_per_week':
        final target = userGoals['total_minutes_per_week'] as int;
        final current = currentProgress['minutes_this_week'] as int;
        return target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

      case 'minutes_per_session':
        // For session duration, calculate based on average
        final target = userGoals['minutes_per_session'] as int;
        final sessionsToday = currentProgress['sessions_today'] as int;
        final minutesToday = currentProgress['minutes_today'] as int;
        final avgMinutesPerSession =
            sessionsToday > 0 ? (minutesToday / sessionsToday) : 0.0;
        return target > 0
            ? (avgMinutesPerSession / target).clamp(0.0, 1.0)
            : 0.0;

      default:
        return 0.75; // Fallback value
    }
  }

  String _getProgressSectionTitle() {
    switch (_selectedTimeFrame) {
      case 0:
        return 'Weekly Progress';
      case 1:
        return 'Monthly Progress';
      case 2:
        return 'Quarterly Progress';
      default:
        return 'Weekly Progress';
    }
  }

  String _getTimePeriod() {
    switch (_selectedTimeFrame) {
      case 0:
        return 'week';
      case 1:
        return 'month';
      case 2:
        return '3 months';
      default:
        return 'week';
    }
  }

  int _getRecommendedMinutes() {
    switch (_selectedTimeFrame) {
      case 0:
        return 150; // Weekly recommendation
      case 1:
        return 600; // Monthly recommendation (150 * 4)
      case 2:
        return 1800; // 3-month recommendation (150 * 12)
      default:
        return 150;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Reset animation
    _animationController.reset();
    _animationController.forward();
  }
}
