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
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 5 seconds to allow error widget on new screens
      Future.delayed(const Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Your actual app
    final Widget baseApp = MaterialApp(
      title: 'sunbeam',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      // 🚨 END CRITICAL SECTION
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.initial,
    );

    // Outer layout decides: full app vs. phone frame
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sizer must be inside the constraints it should use
        Widget sizedApp = Sizer(
          builder: (context, orientation, screenType) {
            return baseApp;
          },
        );

        // On narrow screens (real phones), just show the app normally
        if (constraints.maxWidth <= 600) {
          return sizedApp;
        }

        // On wider screens (desktop/tablet), center a phone-sized app
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,   // virtual phone width
                maxHeight: 900,  // virtual phone height
              ),
              child: sizedApp,   // Sizer now sees 430x900, not the full desktop
            ),
          ),
        );
      },
    );
  }
}
