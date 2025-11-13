import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e, st) {
    debugPrint('Failed to initialize Supabase: $e');
    debugPrint('$st');
  }

  bool _hasShownError = false;

  // Global Flutter error handler (logs more detail)
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('${details.stack}');
  };

  // Platform (zone) error handler for async errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Platform error: $error');
    debugPrint('$stack');
    return true; // prevent app from hard-crashing
  };

  // 🚨 CRITICAL: Custom error handling widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      Future.delayed(const Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Wrap runApp in a guarded zone so uncaught async errors are logged, not fatal
  runZonedGuarded(
    () {
      runApp(MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
      debugPrint('$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'sunbeam',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: text scaling + web width constraint
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();

          final mediaQuery = MediaQuery.of(context);

          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430, // mobile-width feel on desktop
                ),
                child: child,
              ),
            ),
          );
        },
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}
