import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
import './widgets/education_pill_widget.dart';
import './widgets/goal_progress_card_widget.dart';
import './widgets/hourly_uv_chart_widget.dart';
import './widgets/safety_recommendations_widget.dart';
import './widgets/sun_window_card_widget.dart';
import './widgets/weather_badges_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  bool _isLoadingWeather = false;
  String _currentLocation = 'Fetching location...';

  final LocationService _locationService = LocationService.instance;
  final WeatherService _weatherService = WeatherService.instance;

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
    'sessions_today': 1,
    'minutes_today': 15,
    'sessions_this_week': 8,
    'minutes_this_week': 120,
  };

  final List<Map<String, dynamic>> hourlyUvData = [
    {"time": "6AM", "uvIndex": 1, "temp": 65},
    {"time": "8AM", "uvIndex": 3, "temp": 68},
    {"time": "10AM", "uvIndex": 6, "temp": 72},
    {"time": "12PM", "uvIndex": 9, "temp": 78},
    {"time": "2PM", "uvIndex": 11, "temp": 82},
    {"time": "4PM", "uvIndex": 8, "temp": 80},
    {"time": "6PM", "uvIndex": 5, "temp": 76},
    {"time": "8PM", "uvIndex": 2, "temp": 72},
  ];

  Map<String, dynamic> _currentWeatherData = {
    'temperature': 78.0, // can be double; we’ll round when using
    'cloudCover': '20%',
    'windSpeed': '8 mph',
    'humidity': '65%',
    'uvIndex': 7.0,
    'visibility': 'Good',
    'precipitation': '0%',
    'condition': 'Partly Sunny',
    'description': 'Partly sunny',
  };

  final List<Map<String, dynamic>> educationArticles = [
    {
      "id": 1,
      "title": "Understanding UV Index: Your Guide to Safe Sun Exposure",
      "category": "UV Safety",
      "summary":
          "Learn how UV index affects your skin and the best times for sun exposure.",
      "readTime": 3,
      "content":
          "The UV Index measures the strength of ultraviolet radiation. Aim for sun exposure when UV Index is between 3–6, typically early morning or late afternoon."
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGoalSettings();
    _initializeLocationAndWeather();
  }

  Future<void> _initializeLocationAndWeather() async {
    await _updateLocationAndWeather();
  }

  Future<void> _updateLocationAndWeather() async {
    debugPrint('📍 [HomeScreen] Starting location and weather update...');
    setState(() => _isLoadingWeather = true);

    try {
      debugPrint('📍 [HomeScreen] Calling fetchAndSaveLocation...');
      final locationData = await _locationService.fetchAndSaveLocation();
      debugPrint('📍 [HomeScreen] Location data received: ${locationData != null ? "SUCCESS" : "NULL"}');

      if (locationData != null) {
        final lat = (locationData['latitude'] as num).toDouble();
        final lng = (locationData['longitude'] as num).toDouble();
        debugPrint('📍 [HomeScreen] Coordinates: $lat, $lng');

        setState(() {
          _currentLocation = locationData['address'] ??
              "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
        });

        debugPrint('📍 [HomeScreen] Fetching weather data...');
        final weatherData =
            await _weatherService.getCompleteWeatherData(lat, lng);

        if (weatherData != null) {
          debugPrint('📍 [HomeScreen] Weather data received successfully');
          setState(() {
            _currentWeatherData = {
              'temperature':
                  (weatherData['temperature'] as num?)?.toDouble() ?? 78.0,
              'cloudCover': '${weatherData['cloud_cover'] ?? 20}%',
              'windSpeed':
                  '${(weatherData['wind_speed'] as num?)?.toStringAsFixed(1) ?? '8'} mph',
              'humidity': '${weatherData['humidity'] ?? 65}%',
              'uvIndex': (weatherData['uv_index'] as num?)?.toDouble() ?? 7.0,
              'visibility': 'Good',
              'precipitation': '0%',
              'condition': weatherData['weather_condition'] ?? 'Partly Sunny',
              'description': weatherData['description'] ?? 'Partly sunny',
            };
          });
        } else {
          debugPrint('⚠️ [HomeScreen] Weather data is null');
        }
      } else {
        // Location fetch failed - update UI with appropriate message
        debugPrint('❌ [HomeScreen] Location data is null - check permissions');
        setState(() {
          _currentLocation = 'Location unavailable (Tap to retry)';
        });
      }
    } catch (e) {
      debugPrint('❌ [HomeScreen] Error updating location/weather: $e');
      setState(() {
        _currentLocation = 'Location error (Tap to retry)';
      });
    } finally {
      setState(() => _isLoadingWeather = false);
      debugPrint('📍 [HomeScreen] Location and weather update completed');
    }
  }

  Future<void> _loadGoalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userGoals = {
        'primary_goal_type':
            prefs.getString('primary_goal_type') ?? 'sessions_per_day',
        'enable_secondary_goal':
            prefs.getBool('enable_secondary_goal') ?? true,
        'secondary_goal_type':
            prefs.getString('secondary_goal_type') ?? 'minutes_per_session',
        'sessions_per_day': prefs.getInt('sessions_per_day') ?? 2,
        'minutes_per_session': prefs.getInt('minutes_per_session') ?? 15,
        'sessions_per_week': prefs.getInt('sessions_per_week') ?? 14,
        'total_minutes_per_week':
            prefs.getInt('total_minutes_per_week') ?? 210,
      };
    });
  }

  Future<void> _saveGoalSettings(Map<String, dynamic> newGoals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primary_goal_type', newGoals['primary_goal_type']);
    await prefs.setBool(
        'enable_secondary_goal', newGoals['enable_secondary_goal']);
    if (newGoals['secondary_goal_type'] != null) {
      await prefs.setString(
          'secondary_goal_type', newGoals['secondary_goal_type']);
    }
    await prefs.setInt('sessions_per_day', newGoals['sessions_per_day']);
    await prefs.setInt('minutes_per_session', newGoals['minutes_per_session']);
    await prefs.setInt('sessions_per_week', newGoals['sessions_per_week']);
    await prefs.setInt(
        'total_minutes_per_week', newGoals['total_minutes_per_week']);

    setState(() {
      userGoals = newGoals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppTheme.lightTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 2.h),
                    _buildGoalProgressSection(),
                    SizedBox(height: 2.h),
                    _buildDynamicSunWindowCard(),
                    SizedBox(height: 1.h),
                    HourlyUvChartWidget(hourlyData: hourlyUvData),
                    SizedBox(height: 1.h),
                    if (_isLoadingWeather)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: CircularProgressIndicator(
                            color: AppTheme.lightTheme.primaryColor,
                          ),
                        ),
                      )
                    else
                      WeatherBadgesWidget(
                        // 🔑 ensure we always give an int
                        temperature:
                            ((_currentWeatherData['temperature'] as num?) ??
                                    78)
                                .round(),
                        cloudCover:
                            _currentWeatherData['cloudCover'] as String? ??
                                '20%',
                        windSpeed:
                            _currentWeatherData['windSpeed'] as String? ??
                                '8 mph',
                        humidity:
                            _currentWeatherData['humidity'] as String? ??
                                '65%',
                      ),
                    SizedBox(height: 1.h),
                    _buildDynamicSafetyRecommendations(),
                    SizedBox(height: 1.h),
                    EducationPillWidget(
                      article: educationArticles[0],
                      onDismiss: () {},
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/log-session-screen');
        },
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const CustomIconWidget(
          iconName: 'wb_sunny',
          color: Colors.white,
          size: 24,
        ),
        label: Text(
          'Log Sun Session',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Ready for some sunshine?',
                    style: AppTheme.lightTheme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                      context, AppRoutes.notificationsScreen);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CustomIconWidget(
                    iconName: 'notifications',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              InkWell(
                onTap: _currentLocation.contains('unavailable') ||
                        _currentLocation.contains('error') ||
                        _currentLocation.contains('Fetching')
                    ? () {
                        debugPrint('📍 [HomeScreen] User tapped to retry location');
                        _updateLocationAndWeather();
                      }
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _currentLocation,
                      style:
                          AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color:
                            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        decoration: _currentLocation.contains('Tap to retry')
                            ? TextDecoration.underline
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              const CustomIconWidget(
                iconName: 'wb_sunny',
                color: Colors.orange,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                _currentWeatherData['condition'] as String? ??
                    'Partly Sunny',
                style:
                    AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color:
                      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressSection() {
    final primaryGoalType = userGoals['primary_goal_type'] as String;
    final enableSecondaryGoal =
        userGoals['enable_secondary_goal'] as bool;
    final secondaryGoalType =
        userGoals['secondary_goal_type'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Goals',
                style: AppTheme.lightTheme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: _editGoals,
                child: Text(
                  'Edit Goals',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildGoalCard(primaryGoalType, isPrimary: true),
        if (enableSecondaryGoal && secondaryGoalType != null)
          _buildGoalCard(secondaryGoalType, isPrimary: false),
      ],
    );
  }

  Widget _buildGoalCard(String goalType, {required bool isPrimary}) {
    final Map<String, dynamic> goalInfo = _getGoalInfo(goalType);
    final int currentValue = _getCurrentProgress(goalType);
    final int targetValue = userGoals[goalType] as int;

    return GoalProgressCardWidget(
      goalType: goalInfo['title'],
      goalDescription: isPrimary ? 'Primary Goal' : 'Secondary Goal',
      currentProgress: currentValue,
      targetValue: targetValue,
      unit: goalInfo['unit'],
      timeframe: goalInfo['timeframe'],
      icon: goalInfo['icon'],
      progressColor: isPrimary
          ? AppTheme.lightTheme.primaryColor
          : AppTheme.lightTheme.colorScheme.secondary,
      onEditGoal: _editGoals,
    );
  }

  Map<String, dynamic> _getGoalInfo(String goalType) {
    switch (goalType) {
      case 'sessions_per_day':
        return {
          'title': 'Daily Sessions',
          'unit': 'sessions',
          'timeframe': 'Today',
          'icon': 'wb_sunny'
        };
      case 'minutes_per_session':
        return {
          'title': 'Session Duration',
          'unit': 'minutes',
          'timeframe': 'Per Session',
          'icon': 'timer'
        };
      case 'sessions_per_week':
        return {
          'title': 'Weekly Sessions',
          'unit': 'sessions',
          'timeframe': 'This Week',
          'icon': 'date_range'
        };
      case 'total_minutes_per_week':
        return {
          'title': 'Weekly Minutes',
          'unit': 'minutes',
          'timeframe': 'This Week',
          'icon': 'schedule'
        };
      default:
        return {
          'title': 'Daily Sessions',
          'unit': 'sessions',
          'timeframe': 'Today',
          'icon': 'wb_sunny'
        };
    }
  }

  int _getCurrentProgress(String goalType) {
    switch (goalType) {
      case 'sessions_per_day':
        return currentProgress['sessions_today'] as int;
      case 'minutes_per_session':
        final sessionsToday = currentProgress['sessions_today'] as int;
        final minutesToday = currentProgress['minutes_today'] as int;
        return sessionsToday > 0 ? (minutesToday / sessionsToday).round() : 0;
      case 'sessions_per_week':
        return currentProgress['sessions_this_week'] as int;
      case 'total_minutes_per_week':
        return currentProgress['minutes_this_week'] as int;
      default:
        return 0;
    }
  }

  void _editGoals() {
    Navigator.pushNamed(
      context,
      AppRoutes.goalEditScreen,
      arguments: {
        'currentGoals': userGoals,
        'onGoalsChanged': (Map<String, dynamic> newGoals) =>
            _saveGoalSettings(newGoals),
      },
    );
  }

  Widget _buildDynamicSunWindowCard() => const SunWindowCardWidget(
        startTime: '4 PM',
        endTime: '5:30 PM',
        recommendedMinutes: 15,
        countdownText: '3h 15m',
      );

  Widget _buildDynamicSafetyRecommendations() =>
      const SafetyRecommendationsWidget(
        spfRecommendation: 'SPF 30+ recommended',
        safetyLevel: 'Moderate',
        protectiveMeasures: [
          'Wear sunscreen',
          'Stay hydrated',
          'Avoid midday sun'
        ],
      );

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 1:
            Navigator.pushNamed(context, '/log-session-screen');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/insights-screen');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile-screen');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor:
          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        _navItem('home', 'Home', 0),
        _navItem('add_circle_outline', 'Log', 1),
        _navItem('insights', 'Insights', 2),
        _navItem('person', 'Profile', 3),
      ],
    );
  }

  BottomNavigationBarItem _navItem(String icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: CustomIconWidget(
        iconName: icon,
        color: _selectedIndex == index
            ? AppTheme.lightTheme.primaryColor
            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
      label: label,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _updateLocationAndWeather();
    setState(() => _isRefreshing = false);
  }
}
