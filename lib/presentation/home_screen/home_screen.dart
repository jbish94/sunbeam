import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
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

  StreamSubscription<AuthState>? _authSubscription;

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

  List<Map<String, dynamic>> _hourlyUvData = [];
  Map<String, dynamic>? _sunWindow;

  // Null until real data arrives — prevents fake defaults from showing
  Map<String, dynamic>? _currentWeatherData;
  bool _weatherDataLoaded = false;

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
    _loadSessionProgress();
    _initializeLocationAndWeather();

    // React to sign-in / sign-out without requiring a restart
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (mounted) {
          setState(() {}); // rebuild so FAB / greeting update immediately
          _loadSessionProgress(); // refresh progress for the new user state
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSessionProgress() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => currentProgress = {
          'sessions_today': 0,
          'minutes_today': 0,
          'sessions_this_week': 0,
          'minutes_this_week': 0,
        });
      }
      return;
    }

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      final sessions = await Supabase.instance.client
          .from('sun_sessions')
          .select('start_time, duration_minutes')
          .eq('user_id', user.id)
          .gte('start_time', weekStart.toIso8601String());

      int sessionsToday = 0, minutesToday = 0;
      int sessionsWeek = 0, minutesWeek = 0;

      for (final s in sessions as List) {
        final start = DateTime.parse(s['start_time'] as String);
        final mins = (s['duration_minutes'] as int?) ?? 0;
        sessionsWeek++;
        minutesWeek += mins;
        if (!start.isBefore(todayStart)) {
          sessionsToday++;
          minutesToday += mins;
        }
      }

      if (mounted) {
        setState(() => currentProgress = {
          'sessions_today': sessionsToday,
          'minutes_today': minutesToday,
          'sessions_this_week': sessionsWeek,
          'minutes_this_week': minutesWeek,
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Failed to load session progress: $e');
    }
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

        debugPrint('📍 [HomeScreen] Fetching weather + location name...');
        final results = await Future.wait([
          _weatherService.getCompleteWeatherData(lat, lng),
          _weatherService.getHourlyUvForecast(lat, lng),
          _weatherService.getLocationName(lat, lng),
        ]);

        final weatherData = results[0] as Map<String, dynamic>?;
        final hourlyData = results[1] as List<Map<String, dynamic>>?;
        final geoApiName = results[2] as String?;

        // Resolve display location with priority:
        // 1. Device geocoding (mobile, gives "City, State")
        // 2. OpenWeather Geo API (web-safe, gives "City, State")
        // 3. OpenWeather current weather city field ("City, US")
        // 4. Raw coordinates — absolute last resort
        final geoAddress = locationData['address'] as String?;
        final cityAddress = weatherData?['city_address'] as String?;
        final displayLocation = (geoAddress?.isNotEmpty == true)
            ? geoAddress!
            : (geoApiName?.isNotEmpty == true)
                ? geoApiName!
                : (cityAddress?.isNotEmpty == true)
                    ? cityAddress!
                    : '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}';

        setState(() => _currentLocation = displayLocation);

        if (weatherData != null) {
          debugPrint('📍 [HomeScreen] Weather data received successfully');
          // API returns metric: temp in °C, wind in m/s — convert for display
          final tempC = (weatherData['temperature'] as num?)?.toDouble() ?? 20.0;
          final tempF = tempC * 9 / 5 + 32;
          final windMs = (weatherData['wind_speed'] as num?)?.toDouble() ?? 0.0;
          final windMph = windMs * 2.237;
          setState(() {
            _weatherDataLoaded = true;
            _currentWeatherData = {
              'temperature': tempF,
              'cloudCover': '${weatherData['cloud_cover'] ?? 0}%',
              'windSpeed': '${windMph.toStringAsFixed(1)} mph',
              'humidity': '${weatherData['humidity'] ?? 0}%',
              'uvIndex': (weatherData['uv_index'] as num?)?.toDouble() ?? 0.0,
              'visibility': 'Good',
              'condition': weatherData['weather_condition'] ?? 'Unknown',
              'description': weatherData['description'] ?? '',
            };
          });
        } else {
          debugPrint('⚠️ [HomeScreen] Weather data is null — API key may be missing');
        }

        if (hourlyData != null && hourlyData.isNotEmpty) {
          debugPrint(
              '📍 [HomeScreen] Hourly UV data: ${hourlyData.length} points');
          setState(() {
            _hourlyUvData = hourlyData;
            _sunWindow = _computeSunWindow(hourlyData);
          });
        } else {
          debugPrint('⚠️ [HomeScreen] Hourly UV data unavailable');
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
                    if (_isLoadingWeather)
                      _buildUvChartPlaceholder(loading: true)
                    else if (_hourlyUvData.isNotEmpty)
                      HourlyUvChartWidget(hourlyData: _hourlyUvData)
                    else
                      _buildUvChartPlaceholder(loading: false),
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
                    else if (_weatherDataLoaded && _currentWeatherData != null)
                      WeatherBadgesWidget(
                        temperature:
                            ((_currentWeatherData!['temperature'] as num?) ?? 0)
                                .round(),
                        cloudCover:
                            _currentWeatherData!['cloudCover'] as String? ??
                                '—',
                        windSpeed:
                            _currentWeatherData!['windSpeed'] as String? ??
                                '—',
                        humidity:
                            _currentWeatherData!['humidity'] as String? ??
                                '—',
                      )
                    else
                      _buildWeatherUnavailable(),
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
        onPressed: _onLogSessionTapped,
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
                    _getWelcomeSubtitle(),
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
                _currentWeatherData?['condition'] as String? ??
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
        return (currentProgress['sessions_today'] as int?) ?? 0;
      case 'minutes_per_session':
        final sessionsToday = (currentProgress['sessions_today'] as int?) ?? 0;
        final minutesToday = (currentProgress['minutes_today'] as int?) ?? 0;
        return sessionsToday > 0 ? (minutesToday / sessionsToday).round() : 0;
      case 'sessions_per_week':
        return (currentProgress['sessions_this_week'] as int?) ?? 0;
      case 'total_minutes_per_week':
        return (currentProgress['minutes_this_week'] as int?) ?? 0;
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

  Widget _buildDynamicSunWindowCard() {
    final w = _sunWindow;
    if (w == null) {
      // No optimal window found today — show a "no window" placeholder
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'cloud',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 7.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Optimal Window Today',
                    style: AppTheme.lightTheme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _isLoadingWeather
                        ? 'Loading forecast…'
                        : 'UV levels aren\'t in the optimal 3–7 range today.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SunWindowCardWidget(
      startTime: w['startTime'] as String,
      endTime: w['endTime'] as String,
      recommendedMinutes: w['recommendedMinutes'] as int,
      countdownText: w['countdownText'] as String,
    );
  }

  Widget _buildUvChartPlaceholder({required bool loading}) {
    return Container(
      width: double.infinity,
      height: 30.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s UV Index',
                style: AppTheme.lightTheme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              CustomIconWidget(
                iconName: 'wb_sunny',
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: loading
                  ? CircularProgressIndicator(
                      color: AppTheme.lightTheme.primaryColor)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'cloud_off',
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 7.w,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'UV data unavailable',
                          style:
                              AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Check API key configuration',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherUnavailable() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'cloud_off',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'Weather data unavailable — check API key',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSafetyRecommendations() {
    final uv = (_currentWeatherData?['uvIndex'] as num?)?.toDouble() ?? 0.0;
    final rec = _uvRecommendations(uv);
    return SafetyRecommendationsWidget(
      spfRecommendation: rec['spf'] as String,
      safetyLevel: rec['level'] as String,
      protectiveMeasures: rec['measures'] as List<String>,
    );
  }

  Map<String, dynamic> _uvRecommendations(double uv) {
    if (uv < 1) {
      return {
        'level': 'Low',
        'spf': 'No SPF needed — great time for sun exposure',
        'measures': [
          'Enjoy the sun freely',
          'Stay hydrated',
          'Good window for vitamin D synthesis',
        ],
      };
    } else if (uv < 3) {
      return {
        'level': 'Low',
        'spf': 'SPF 15 optional for extended time outdoors',
        'measures': [
          'Minimal protection needed',
          'Stay hydrated',
          'Ideal for longer outdoor sessions',
        ],
      };
    } else if (uv < 6) {
      return {
        'level': 'Moderate',
        'spf': 'SPF 15–30 recommended',
        'measures': [
          'Apply SPF 15–30 sunscreen',
          'Wear a wide-brimmed hat',
          'Stay hydrated',
          'Seek shade if outdoors for extended periods',
        ],
      };
    } else if (uv < 8) {
      return {
        'level': 'High',
        'spf': 'SPF 30+ required',
        'measures': [
          'Apply SPF 30+ sunscreen and reapply every 2 hours',
          'Wear protective clothing and hat',
          'Use UV-blocking sunglasses',
          'Limit exposure between 10 AM – 4 PM',
          'Stay hydrated',
        ],
      };
    } else if (uv < 11) {
      return {
        'level': 'Very High',
        'spf': 'SPF 50+ required — minimise exposure',
        'measures': [
          'Apply SPF 50+ sunscreen generously',
          'Cover up: long sleeves, hat, and sunglasses',
          'Avoid sun between 10 AM – 4 PM',
          'Seek shade whenever possible',
          'Stay well hydrated',
        ],
      };
    } else {
      return {
        'level': 'Extreme',
        'spf': 'SPF 50+ — avoid direct sun exposure',
        'measures': [
          'Avoid going outside during peak hours',
          'Apply SPF 50+ if outdoors is unavoidable',
          'Wear full protective clothing',
          'Stay in the shade at all times',
          'Keep children and sensitive individuals indoors',
        ],
      };
    }
  }

  void _onLogSessionTapped() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Navigator.pushNamed(context, AppRoutes.logSession);
    } else {
      _showSignUpPrompt();
    }
  }

  void _showSignUpPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 3.h),
            CustomIconWidget(
              iconName: 'wb_sunny',
              color: AppTheme.lightTheme.primaryColor,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Save Your Sessions',
              style: AppTheme.lightTheme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Create a free account to log sessions, track your progress, and view insights over time.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.welcomeScreen);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create Free Account',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.welcomeScreen);
              },
              child: Text(
                'Already have an account? Sign in',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLogSessionTapped() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Navigator.pushNamed(context, AppRoutes.logSession);
    } else {
      _showSignUpPrompt();
    }
  }

  void _showSignUpPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 3.h),
            CustomIconWidget(
              iconName: 'wb_sunny',
              color: AppTheme.lightTheme.primaryColor,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Save Your Sessions',
              style: AppTheme.lightTheme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Create a free account to log sessions, track your progress, and view insights over time.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.welcomeScreen);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create Free Account',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.welcomeScreen);
              },
              child: Text(
                'Already have an account? Sign in',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 1:
            _onLogSessionTapped();
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

  /// Finds the first upcoming block of hours where UV is 3–7 (optimal for
  /// vitamin D synthesis without high burn risk).
  Map<String, dynamic>? _computeSunWindow(
      List<Map<String, dynamic>> hourly) {
    if (hourly.isEmpty) return null;

    final now = DateTime.now();
    Map<String, dynamic>? windowStart;
    Map<String, dynamic>? windowEnd;

    for (final h in hourly) {
      final dt = h['dt'] as DateTime;
      // Skip hours more than 1h in the past
      if (dt.isBefore(now.subtract(const Duration(hours: 1)))) continue;

      final uv = (h['uvIndex'] as num).toDouble();
      if (uv >= 3.0 && uv <= 7.0) {
        windowStart ??= h;
        windowEnd = h;
      } else if (windowStart != null) {
        break; // first contiguous window found
      }
    }

    if (windowStart == null) return null;

    final startDt = windowStart['dt'] as DateTime;
    final uvAvg =
        ((windowStart['uvIndex'] as num).toDouble() +
                ((windowEnd ?? windowStart)['uvIndex'] as num).toDouble()) /
            2;
    final recommendedMins = uvAvg <= 4.0 ? 30 : uvAvg <= 6.0 ? 20 : 15;
    final countdown = startDt.isAfter(now)
        ? _formatCountdown(startDt.difference(now))
        : 'Now';

    return {
      'startTime': windowStart['time'] as String,
      'endTime': (windowEnd ?? windowStart)['time'] as String,
      'recommendedMinutes': recommendedMins,
      'countdownText': countdown,
    };
  }

  String _formatCountdown(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getWelcomeSubtitle() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final name = (user.userMetadata?['full_name'] as String?)
          ?.split(' ')
          .first;
      if (name != null && name.isNotEmpty) return 'Welcome back, $name!';
    }
    return 'Ready for some sunshine?';
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      _updateLocationAndWeather(),
      _loadSessionProgress(),
    ]);
    setState(() => _isRefreshing = false);
  }
}
