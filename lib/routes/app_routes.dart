import 'package:flutter/material.dart';
import '../presentation/log_session_screen/log_session_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/insights_screen/insights_screen.dart';
import '../presentation/profile_screen/goal_edit_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/welcome_screen/welcome_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String welcomeScreen = '/welcome-screen';
  static const String logSession = '/log-session-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String profile = '/profile-screen';
  static const String home = '/home-screen';
  static const String insights = '/insights-screen';
  static const String goalEditScreen = '/goal-edit-screen';
  static const String notificationsScreen = '/notifications-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const WelcomeScreen(),
    welcomeScreen: (context) => const WelcomeScreen(),
    logSession: (context) => const LogSessionScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    profile: (context) => const ProfileScreen(),
    home: (context) => const HomeScreen(),
    insights: (context) => const InsightsScreen(),
    goalEditScreen: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return GoalEditScreen(
        currentGoals: args?['currentGoals'] ?? {},
        onGoalsChanged: args?['onGoalsChanged'] ?? (goals) {},
      );
    },
    notificationsScreen: (context) => const NotificationsScreen(),
    // TODO: Add your other routes here
  };
}
