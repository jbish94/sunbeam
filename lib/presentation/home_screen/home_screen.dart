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
  String _currentLocation = 'Loading location...';

  // Services
  final LocationService _locationService = LocationService.instance;
  final WeatherService _weatherService = WeatherService.instance;

  // Mock user goal data - this would come from shared preferences or database in real app
  Map<String, dynamic> userGoals = {
    'primary_goal_type': 'sessions_per_day',
    'enable_secondary_goal': true,
    'secondary_goal_type': 'minutes_per_session',
    'sessions_per_day': 2,
    'minutes_per_session': 15,
    'sessions_per_week': 14,
    'total_minutes_per_week': 210,
  };

  // Mock current progress data - this would be calculated from session logs
  Map<String, dynamic> currentProgress = {
    'sessions_today': 1,
    'minutes_today': 15,
    'sessions_this_week': 8,
    'minutes_this_week': 120,
  };

  // Mock data for the home screen
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

  // Real weather data - will be populated from API
  Map<String, dynamic> _currentWeatherData = {
    'temperature': 78.0,
    'cloudCover': '20%',
    'windSpeed': '8 mph',
    'humidity': '65%',
    'uvIndex': 7.0,
    'visibility': 'Good',
    'precipitation': '0%',
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
          """The UV Index is a crucial tool for understanding when it's safe to be in the sun. Developed by the World Health Organization, it measures the strength of ultraviolet radiation from the sun on a scale of 1 to 11+. Understanding the scale: • 1-2 (Low): Minimal risk, safe for most people • 3-5 (Moderate): Some risk, wear sunscreen • 6-7 (High): High risk, seek shade during midday • 8-10 (Very High): Very high risk, avoid sun exposure • 11+ (Extreme): Extreme risk, stay indoors if possible The UV Index varies throughout the day, typically peaking between 10 AM and 4 PM. It's also affected by factors like altitude, latitude, cloud cover, and reflection from surfaces like water, sand, and snow. For optimal vitamin D synthesis while minimizing skin damage, aim for sun exposure when the UV Index is between 3-6, typically in the early morning or late afternoon hours."""
    },
    {
      "id": 2,
      "title": "Vitamin D and Sun Exposure: Finding the Perfect Balance",
      "category": "Health Benefits",
      "summary":
          "Discover how to optimize vitamin D production through safe sun exposure practices.",
      "readTime": 4,
      "content":
          """Vitamin D is essential for bone health, immune function, and overall well-being. While supplements are available, natural sun exposure remains one of the most effective ways to maintain adequate vitamin D levels. Key factors affecting vitamin D production: • Skin type: Lighter skin produces vitamin D faster but burns more easily • Time of day: Peak production occurs when UV-B rays are strongest • Season and latitude: Production varies significantly by location and time of year • Age: Older adults produce less vitamin D from sun exposure For most people, 10-30 minutes of midday sun exposure several times per week is sufficient. However, this varies greatly based on skin type, location, and season. People with darker skin may need longer exposure times, while those with very fair skin may need less. Remember: You don't need to burn to produce vitamin D. In fact, once your skin begins to turn pink, vitamin D production stops, and you're only increasing your risk of skin damage."""
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadGoalSettings();
    _initializeLocationAndWeather();
  }

  /// Initialize location and weather services
  Future<void> _initializeLocationAndWeather() async {
    await _updateLocationAndWeather();
  }

  /// Update location and weather data
  Future<void> _updateLocationAndWeather() async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        // Get address for location
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentLocation = address ?? 'Unknown location';
        });

        // Get weather data
        final weatherData = await _weatherService.getCompleteWeatherData(
          position.latitude,
          position.longitude,
        );

        if (weatherData != null) {
          setState(() {
            _currentWeatherData = {
              'temperature': weatherData['temperature']?.round() ?? 78,
              'cloudCover': '${weatherData['cloud_cover'] ?? 20}%',
              'windSpeed':
                  '${weatherData['wind_speed']?.toStringAsFixed(1) ?? '8'} mph',
              'humidity': '${weatherData['humidity'] ?? 65}%',
              'uvIndex': weatherData['uv_index']?.toDouble() ?? 7.0,
              'visibility':
                  _getVisibilityDescription(weatherData['visibility'] ?? 10.0),
              'precipitation': '0%', // Not available in current weather
              'condition': weatherData['weather_condition'] ?? 'Partly Sunny',
              'description': weatherData['description'] ?? 'Partly sunny',
            };
          });

          // Update hourly data with real temperature if available
          if (weatherData['temperature'] != null) {
            _updateHourlyDataWithRealTemp(
                weatherData['temperature'].toDouble());
          }
        }
      }
    } catch (e) {
      print('Error updating location and weather: $e');
      // Keep existing mock data on error
    } finally {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  /// Update hourly UV data with real temperature
  void _updateHourlyDataWithRealTemp(double currentTemp) {
    final currentHour = DateTime.now().hour;

    // Update the hourly data to reflect more realistic temperatures based on current weather
    for (int i = 0; i < hourlyUvData.length; i++) {
      final hourData = hourlyUvData[i];
      final hour = _parseHour(hourData['time']);

      // Adjust temperature based on time of day relative to current hour
      double tempAdjustment = 0;
      if (hour < currentHour) {
        tempAdjustment = -2.0 * (currentHour - hour); // Cooler in past hours
      } else if (hour > currentHour) {
        tempAdjustment =
            1.0 * (hour - currentHour); // Slightly warmer in future hours
      }

      hourlyUvData[i]['temp'] = (currentTemp + tempAdjustment).round();
    }
  }

  /// Parse hour from time string (e.g., "6AM" -> 6)
  int _parseHour(String timeString) {
    final isAM = timeString.contains('AM');
    final hourStr = timeString.replaceAll(RegExp(r'[AP]M'), '');
    int hour = int.parse(hourStr);

    if (!isAM && hour != 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }

    return hour;
  }

  /// Get visibility description from visibility in km
  String _getVisibilityDescription(double visibilityKm) {
    if (visibilityKm >= 10) return 'Excellent';
    if (visibilityKm >= 5) return 'Good';
    if (visibilityKm >= 2) return 'Fair';
    if (visibilityKm >= 1) return 'Poor';
    return 'Very Poor';
  }

  Future<void> _loadGoalSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userGoals = {
        'primary_goal_type':
            prefs.getString('primary_goal_type') ?? 'sessions_per_day',
        'enable_secondary_goal': prefs.getBool('enable_secondary_goal') ?? true,
        'secondary_goal_type':
            prefs.getString('secondary_goal_type') ?? 'minutes_per_session',
        'sessions_per_day': prefs.getInt('sessions_per_day') ?? 2,
        'minutes_per_session': prefs.getInt('minutes_per_session') ?? 15,
        'sessions_per_week': prefs.getInt('sessions_per_week') ?? 14,
        'total_minutes_per_week': prefs.getInt('total_minutes_per_week') ?? 210,
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.lightTheme.primaryColor,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 2.h),

                // Goal Progress Cards - NEW SECTION
                _buildGoalProgressSection(),
                SizedBox(height: 2.h),

                // Dynamic Sun Window Card
                _buildDynamicSunWindowCard(),
                SizedBox(height: 1.h),
                HourlyUvChartWidget(hourlyData: hourlyUvData),
                SizedBox(height: 1.h),

                // Weather badges with loading state
                if (_isLoadingWeather)
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    height: 10.h,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  )
                else
                  WeatherBadgesWidget(
                    temperature: _currentWeatherData['temperature'],
                    cloudCover: _currentWeatherData['cloudCover'],
                    windSpeed: _currentWeatherData['windSpeed'],
                    humidity: _currentWeatherData['humidity'],
                  ),
                SizedBox(height: 1.h),

                // Dynamic Safety Recommendations
                _buildDynamicSafetyRecommendations(),
                SizedBox(height: 1.h),
                EducationPillWidget(
                  article: educationArticles[0],
                  onDismiss: () {
                    // Handle article dismissal
                  },
                ),
                SizedBox(height: 2.h),
                SizedBox(height: 10.h), // Bottom padding for FAB
              ],
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
        icon: CustomIconWidget(
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
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Ready for some sunshine?',
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notificationsScreen);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
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
              CustomIconWidget(
                iconName: 'location_on',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  _currentLocation,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              CustomIconWidget(
                iconName: 'wb_sunny',
                color: Colors.orange,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                _currentWeatherData['condition'] ?? 'Partly Sunny',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
    final enableSecondaryGoal = userGoals['enable_secondary_goal'] as bool;
    final secondaryGoalType = userGoals['secondary_goal_type'] as String?;

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
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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

        // Primary Goal Card
        _buildGoalCard(primaryGoalType, isPrimary: true),

        // Secondary Goal Card (if enabled)
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
          'icon': 'wb_sunny',
        };
      case 'minutes_per_session':
        return {
          'title': 'Session Duration',
          'unit': 'minutes',
          'timeframe': 'Per Session',
          'icon': 'timer',
        };
      case 'sessions_per_week':
        return {
          'title': 'Weekly Sessions',
          'unit': 'sessions',
          'timeframe': 'This Week',
          'icon': 'date_range',
        };
      case 'total_minutes_per_week':
        return {
          'title': 'Weekly Minutes',
          'unit': 'minutes',
          'timeframe': 'This Week',
          'icon': 'schedule',
        };
      default:
        return {
          'title': 'Daily Sessions',
          'unit': 'sessions',
          'timeframe': 'Today',
          'icon': 'wb_sunny',
        };
    }
  }

  int _getCurrentProgress(String goalType) {
    switch (goalType) {
      case 'sessions_per_day':
        return currentProgress['sessions_today'] as int;
      case 'minutes_per_session':
        // For session duration, show average minutes per session
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
        'onGoalsChanged': (Map<String, dynamic> newGoals) {
          _saveGoalSettings(newGoals);
        },
      },
    );
  }

  Widget _buildDynamicSunWindowCard() {
    final sunWindowData = _calculateNextOptimalSunWindow();

    return SunWindowCardWidget(
      startTime: sunWindowData['startTime'],
      endTime: sunWindowData['endTime'],
      recommendedMinutes: sunWindowData['recommendedMinutes'],
      countdownText: sunWindowData['countdownText'],
    );
  }

  Widget _buildDynamicSafetyRecommendations() {
    final safetyData = _calculateDynamicSafetyRecommendations();

    return SafetyRecommendationsWidget(
      spfRecommendation: safetyData['spfRecommendation'],
      safetyLevel: safetyData['safetyLevel'],
      protectiveMeasures: safetyData['protectiveMeasures'],
    );
  }

  Map<String, dynamic> _calculateNextOptimalSunWindow() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Define optimal sun windows throughout the day
    final List<Map<String, dynamic>> dailyWindows = [
      {'start': 7, 'startMin': 0, 'end': 9, 'endMin': 30, 'duration': 15},
      {'start': 9, 'startMin': 30, 'end': 11, 'endMin': 0, 'duration': 20},
      {'start': 16, 'startMin': 0, 'end': 17, 'endMin': 30, 'duration': 15},
      {'start': 17, 'startMin': 30, 'end': 19, 'endMin': 0, 'duration': 10},
    ];

    // Find next available window
    DateTime? nextWindowStart;
    Map<String, dynamic>? nextWindow;

    for (final window in dailyWindows) {
      final windowStart = DateTime(
          now.year, now.month, now.day, window['start'], window['startMin']);
      final windowEnd = DateTime(
          now.year, now.month, now.day, window['end'], window['endMin']);

      // If we're before this window starts, use it
      if (now.isBefore(windowStart)) {
        nextWindowStart = windowStart;
        nextWindow = window;
        break;
      }
      // If we're within this window, show next window
      else if (now.isAfter(windowStart) && now.isBefore(windowEnd)) {
        // Find next window after current one
        final currentIndex = dailyWindows.indexOf(window);
        if (currentIndex < dailyWindows.length - 1) {
          final nextWindowData = dailyWindows[currentIndex + 1];
          nextWindowStart = DateTime(now.year, now.month, now.day,
              nextWindowData['start'], nextWindowData['startMin']);
          nextWindow = nextWindowData;
        } else {
          // No more windows today, use first window of tomorrow
          nextWindowStart = DateTime(now.year, now.month, now.day + 1,
              dailyWindows[0]['start'], dailyWindows[0]['startMin']);
          nextWindow = dailyWindows[0];
        }
        break;
      }
    }

    // If no window found (all windows for today have passed), use first window of tomorrow
    if (nextWindowStart == null) {
      nextWindow = dailyWindows[0];
      nextWindowStart = DateTime(now.year, now.month, now.day + 1,
          nextWindow['start'], nextWindow['startMin']);
    }

    // Calculate countdown
    final difference = nextWindowStart.difference(now);
    String countdownText;

    if (difference.inDays > 0) {
      countdownText = 'Tomorrow';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      countdownText = minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      final minutes = difference.inMinutes;
      countdownText = '${minutes}m';
    }

    // Format start and end times
    final startHour = nextWindow!['start'] as int;
    final startMin = nextWindow['startMin'] as int;
    final endHour = nextWindow['end'] as int;
    final endMin = nextWindow['endMin'] as int;

    final startTime = _formatTime(startHour, startMin);
    final endTime = _formatTime(endHour, endMin);

    return {
      'startTime': startTime,
      'endTime': endTime,
      'recommendedMinutes': nextWindow['duration'],
      'countdownText': countdownText,
    };
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute =
        minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    return '$displayHour$displayMinute $period';
  }

  Map<String, dynamic> _calculateDynamicSafetyRecommendations() {
    final uvIndex = (_currentWeatherData['uvIndex'] as num?)?.toDouble() ?? 7.0;
    final cloudCover = int.tryParse(
            _currentWeatherData['cloudCover'].toString().replaceAll('%', '')) ??
        20;
    final temperature = _currentWeatherData['temperature'] as int? ?? 78;
    final humidity = int.tryParse(
            _currentWeatherData['humidity'].toString().replaceAll('%', '')) ??
        65;

    String safetyLevel;
    String spfRecommendation;
    List<String> protectiveMeasures;

    // Determine safety level based on UV index and weather conditions
    if (uvIndex <= 2) {
      safetyLevel = 'Low';
      spfRecommendation = 'SPF 15+ recommended for extended exposure';
      protectiveMeasures = [
        'Minimal sun protection required for most people',
        'Wear sunglasses on bright days',
        'Consider light sun protection for sensitive skin',
        'Good time for vitamin D synthesis',
      ];
    } else if (uvIndex <= 5) {
      safetyLevel = 'Moderate';
      spfRecommendation =
          cloudCover > 50 ? 'SPF 20+ recommended' : 'SPF 30+ recommended';
      protectiveMeasures = [
        'Wear broad-spectrum sunscreen with SPF 30 or higher',
        'Seek shade during peak UV hours (10 AM - 4 PM)',
        'Wear protective clothing and wide-brimmed hat',
        'Use UV-blocking sunglasses',
        if (humidity > 70) 'Stay extra hydrated due to high humidity',
        if (temperature > 85) 'Take frequent breaks to avoid overheating',
      ];
    } else if (uvIndex <= 7) {
      safetyLevel = 'High';
      spfRecommendation = 'SPF 30+ essential, reapply every 2 hours';
      protectiveMeasures = [
        'Apply broad-spectrum sunscreen SPF 30+ generously and frequently',
        'Seek shade, especially during midday hours',
        'Wear long-sleeved shirts and pants when possible',
        'Use wide-brimmed hat and UV-blocking sunglasses',
        'Limit direct sun exposure between 10 AM - 4 PM',
        if (cloudCover < 30) 'Extra caution needed with minimal cloud cover',
        'Stay well hydrated and take frequent breaks',
      ];
    } else if (uvIndex <= 10) {
      safetyLevel = 'Very High';
      spfRecommendation = 'SPF 50+ essential, reapply every hour';
      protectiveMeasures = [
        'Apply SPF 50+ sunscreen generously every hour',
        'Avoid sun exposure during peak hours (10 AM - 4 PM)',
        'Wear long-sleeved UV-protective clothing',
        'Use wide-brimmed hat and wraparound sunglasses',
        'Seek shade whenever possible',
        'Consider indoor activities during midday',
        'Stay extensively hydrated',
        if (temperature > 90) 'Risk of heat exhaustion - monitor for symptoms',
      ];
    } else {
      safetyLevel = 'Extreme';
      spfRecommendation = 'SPF 50+ essential, avoid sun exposure';
      protectiveMeasures = [
        'Avoid outdoor activities during daylight hours',
        'If outdoors, wear full UV-protective clothing',
        'Apply SPF 50+ sunscreen every 30-60 minutes',
        'Stay in shade and indoors when possible',
        'Wear wide-brimmed hat and wraparound sunglasses',
        'Consider UV-protective umbrellas or canopies',
        'Monitor for signs of heat-related illness',
        'Postpone non-essential outdoor activities',
      ];
    }

    // Adjust recommendations based on weather conditions
    if (cloudCover > 70) {
      protectiveMeasures
          .add('Cloud cover reduces UV but doesn\'t eliminate risk');
    }

    if (temperature > 95) {
      protectiveMeasures.add('Extreme heat warning - risk of heat stroke');
    }

    return {
      'safetyLevel': safetyLevel,
      'spfRecommendation': spfRecommendation,
      'protectiveMeasures': protectiveMeasures,
    };
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        switch (index) {
          case 0:
            // Already on home
            break;
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
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: _selectedIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'add_circle_outline',
            color: _selectedIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Log',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'insights',
            color: _selectedIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _selectedIndex == 3
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Update location and weather from real APIs
    await _updateLocationAndWeather();

    setState(() {
      _isRefreshing = false;
    });
  }
}