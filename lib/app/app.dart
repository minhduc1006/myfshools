import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/api_client.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';

class FptStudentNotebookApp extends StatelessWidget {
  const FptStudentNotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ liên lạc điện tử',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  final ApiClient _apiClient = ApiClient();
  String screen = 'splash';
  String? _token;
  String? _userName;

  void _go(String next) => setState(() => screen = next);

  @override
  Widget build(BuildContext context) {
    switch (screen) {
      case 'splash':
        return SplashScreen(onDone: () => _go('onboarding'));
      case 'onboarding':
        return OnboardingScreen(
          onSkip: () => _go('login'),
          onDone: () => _go('login'),
        );
      case 'login':
        return LoginScreen(
          apiClient: _apiClient,
          onLoggedIn: (token, userName) {
            setState(() {
              _token = token;
              _userName = userName;
              screen = 'main';
            });
          },
        );
      default:
        if (_token == null) {
          return LoginScreen(
            apiClient: _apiClient,
            onLoggedIn: (token, userName) {
              setState(() {
                _token = token;
                _userName = userName;
                screen = 'main';
              });
            },
          );
        }
        return MainShell(
          apiClient: _apiClient,
          token: _token!,
          userName: _userName ?? '',
          onLogout: () {
            setState(() {
              _token = null;
              _userName = null;
              screen = 'login';
            });
          },
        );
    }
  }
}
