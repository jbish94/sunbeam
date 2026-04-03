import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/session_service.dart';
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
  int _selectedNavIndex = 2;
  bool _isLoading = false;
  late AnimationController _animationController;

  Map<String, dynamic> userGoals = {
    'primary_goal_type': 'sessions_per_day',
    'enable_secondary_goal': true,
    'secondary_goal_type': 'minutes_per_session',
    'sessions_per_day': 2,
    'minutes_per_session': 15,
    'sessions_per_week': 14,
    'total_minutes_per_week': 210,
  };

  Map<String, dynamic> currentProgress = {
    'sessions_today': 0,
    'minutes_today': 0,
    'sessions_this_week': 0,
    'minutes_this_week': 0,
  };

  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadGoals(), _loadSessions()]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userGoals = {
        'primary_goal_type': prefs.getString('primary_goal_type') ?? 'sessions_per_day',
        'enable_secondary_goal': prefs.getBool('enable_secondary_goal') ?? true,
        'secondary_goal_type': prefs.getString('secondary_goal_type') ?? 'minutes_per_session',
        'sessions_per_day': prefs.getInt('sessions_per_day') ?? 2,
        'minutes_per_session': prefs.getInt('minutes_per_session') ?? 15,
        'sessions_per_week': prefs.getInt('sessions_per_week') ?? 14,
        'total_minutes_per_week': prefs.getInt('total_minutes_per_week') ?? 210,
      };
    });
  }

  Future<void> _loadSessions() async {
    final now = DateTime.now();
    final range = _getDateRange(now);

    final sessions = await SessionService.instance.getSessionHistory(
      startDate: range.$1,
      endDate: range.$2,
      limit: 1000,
    );
    final completed = sessions.where((s) => s['status'] == 'completed').toList();

    // Today's stats
    final today = DateTime(now.year, now.month, now.day);
    final todaySessions = completed.where((s) {
      final start = DateTime.parse(s['start_time'] as String);
      return start.year == today.year &&
          start.month == today.month &&
          start.day == today.day;
    }).toList();

    // This week's stats
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisWeekSessions = completed.where((s) {
      final start = DateTime.parse(s['start_time'] as String);
      return !start.isBefore(weekStart);
    }).toList();

    if (!mounted) return;
    setState(() {
      _chartData = _buildChartData(completed);
      currentProgress = {
        'sessions_today': todaySessions.length,
        'minutes_today': todaySessions.fold(
            0, (sum, s) => sum + ((s['duration_minutes'] as int?) ?? 0)),
        'sessions_this_week': thisWeekSessions.length,
        'minutes_this_week': thisWeekSessions.fold(
            0, (sum, s) => sum + ((s['duration_minutes'] as int?) ?? 0)),
      };
    });
  }

  (DateTime, DateTime) _getDateRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedTimeFrame) {
      case 1:
        return (now.subtract(const Duration(days: 30)), now);
      case 2:
        return (now.subtract(const Duration(days: 90)), now);
      default:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, now);
    }
  }

  List<Map<String, dynamic>> _buildChartData(
      List<Map<String, dynamic>> sessions) {
    if (_selectedTimeFrame == 0) {
      // Week view: one slot per day Mon–Sun
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final slots = List.generate(
        7,
        (i) => {
          'day': dayNames[i],
          'sessions': 0,
          'duration': 0,
          'mood': 0.0,
          'energy': 0.0,
          'uvExposure': 0.0,
          '_moodCount': 0,
          '_energyCount': 0,
        },
      );
      for (final s in sessions) {
        final start = DateTime.parse(s['start_time'] as String);
        final d = slots[start.weekday - 1];
        d['sessions'] = (d['sessions'] as int) + 1;
        d['duration'] = (d['duration'] as int) + ((s['duration_minutes'] as int?) ?? 0);
        d['uvExposure'] = (d['uvExposure'] as double) +
            ((s['uv_index_avg'] as num?)?.toDouble() ?? 0);
        final mood = (s['mood_before'] as int?)?.toDouble();
        if (mood != null) {
          d['mood'] = (d['mood'] as double) + mood;
          d['_moodCount'] = (d['_moodCount'] as int) + 1;
        }
        final energy = (s['energy_before'] as int?)?.toDouble();
        if (energy != null) {
          d['energy'] = (d['energy'] as double) + energy;
          d['_energyCount'] = (d['_energyCount'] as int) + 1;
        }
      }
      return slots.map((d) {
        final mc = d.remove('_moodCount') as int;
        final ec = d.remove('_energyCount') as int;
        d['mood'] = mc > 0 ? (d['mood'] as double) / mc : 0.0;
        d['energy'] = ec > 0 ? (d['energy'] as double) / ec : 0.0;
        return d;
      }).toList();
    } else {
      // Month / 3-month view: group by ISO week number
      final bucketsMap = <String, Map<String, dynamic>>{};
      for (final s in sessions) {
        final start = DateTime.parse(s['start_time'] as String);
        final label = 'W${_weekOfYear(start)}';
        final d = bucketsMap.putIfAbsent(label, () => {
          'day': label,
          'sessions': 0,
          'duration': 0,
          'mood': 0.0,
          'energy': 0.0,
          'uvExposure': 0.0,
          '_moodCount': 0,
          '_energyCount': 0,
        });
        d['sessions'] = (d['sessions'] as int) + 1;
        d['duration'] = (d['duration'] as int) + ((s['duration_minutes'] as int?) ?? 0);
        d['uvExposure'] = (d['uvExposure'] as double) +
            ((s['uv_index_avg'] as num?)?.toDouble() ?? 0);
        final mood = (s['mood_before'] as int?)?.toDouble();
        if (mood != null) {
          d['mood'] = (d['mood'] as double) + mood;
          d['_moodCount'] = (d['_moodCount'] as int) + 1;
        }
        final energy = (s['energy_before'] as int?)?.toDouble();
        if (energy != null) {
          d['energy'] = (d['energy'] as double) + energy;
          d['_energyCount'] = (d['_energyCount'] as int) + 1;
        }
      }
      final result = bucketsMap.values.map((d) {
        final mc = d.remove('_moodCount') as int;
        final ec = d.remove('_energyCount') as int;
        d['mood'] = mc > 0 ? (d['mood'] as double) / mc : 0.0;
        d['energy'] = ec > 0 ? (d['energy'] as double) / ec : 0.0;
        return d;
      }).toList();
      result.sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));
      return result;
    }
  }

  int _weekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return (date.difference(startOfYear).inDays / 7).floor() + 1;
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return _buildGuestState();

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.primaryColor,
        ),
      );
    }

    final hasData = _chartData.any((d) => (d['sessions'] as int) > 0);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.lightTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: hasData ? _buildCharts() : _buildEmptyState(),
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
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
          weeklyData: _chartData,
          animationController: _animationController,
        ),
        SizedBox(height: 3.h),
        _buildSectionHeader('Session Frequency'),
        SizedBox(height: 1.h),
        SessionFrequencyWidget(
          weeklyData: _chartData,
          animationController: _animationController,
        ),
        SizedBox(height: 3.h),
        _buildSectionHeader('Sun Exposure Progress'),
        SizedBox(height: 1.h),
        SunExposureProgressWidget(
          weeklyData: _chartData,
          recommendedMinutes: _getRecommendedMinutes(),
          animationController: _animationController,
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'wb_sunny',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.4),
              size: 20.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'No sessions yet',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Log your first sun session to see your insights here.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/log-session-screen'),
                child: const Text('Log a Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'lock',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.4),
              size: 16.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Sign in to see your insights',
              style: AppTheme.lightTheme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Create a free account to log sessions and track your progress over time.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/welcome-screen'),
                child: const Text('Sign In / Create Account'),
              ),
            ),
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
            Navigator.pushReplacementNamed(context, '/history-screen');
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
            iconName: 'history',
            color: _selectedNavIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'History',
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
    return _chartData.fold(0, (sum, day) => sum + (day['sessions'] as int));
  }

  int _getTotalDuration() {
    return _chartData.fold(0, (sum, day) => sum + (day['duration'] as int));
  }

  double _getAverageMood() {
    final validMoods = _chartData
        .where((day) => (day['mood'] as double) > 0)
        .map((day) => day['mood'] as double);
    if (validMoods.isEmpty) return 0.0;
    return validMoods.reduce((a, b) => a + b) / validMoods.length;
  }

  double _getAverageEnergy() {
    final validEnergy = _chartData
        .where((day) => (day['energy'] as double) > 0)
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
    await _loadData();
  }
}
