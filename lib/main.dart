import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/login/presentation/pages/login_page.dart';
import 'features/register/presentation/pages/register_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() {
  runApp(const AlbumTrackerApp());
}

class AlbumTrackerApp extends StatelessWidget {
  const AlbumTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Album Tracker',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => SplashPage(
          onComplete: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => LoginPage(
                  onLoginSuccess: (ctx) => _goToHome(ctx),
                  onCreateAccount: (ctx) => _goToRegister(ctx),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static void _goToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  static void _goToRegister(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RegisterPage(
          onLogIn: () => Navigator.of(context).pop(),
          onRegisterSuccess: () => _goToHome(context),
        ),
      ),
    );
  }
}
