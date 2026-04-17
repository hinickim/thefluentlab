import 'package:flutter/material.dart';

import '../presentation/practice_screen/practice_screen.dart';
import '../presentation/progress_screen/progress_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/session_history/session_history_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
  static const String onboardingScreen = '/onboarding';
  static const String practiceScreen = '/practice-screen';
  static const String progressScreen = '/progress-screen';
  static const String settingsScreen = '/settings';
  static const String sessionHistoryScreen = '/session-history';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    loginScreen: (context) => const LoginScreen(),
    registerScreen: (context) => const RegisterScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    practiceScreen: (context) => const PracticeScreen(),
    progressScreen: (context) => const ProgressScreen(),
    settingsScreen: (context) => const SettingsScreen(),
    sessionHistoryScreen: (context) => const SessionHistoryScreen(),
  };
}
