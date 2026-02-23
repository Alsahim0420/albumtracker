import 'package:flutter/material.dart';

import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/personalization/presentation/pages/personalization_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
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
      home: const _AppEntry(),
    );
  }
}

/// Controla el flujo de entrada: splash → personalización (solo primera vez) o Home.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  Widget? _postSplashScreen;

  void _onSplashComplete() {
    if (hasCompletedOnboarding) {
      setState(() => _postSplashScreen = const HomePage());
    } else {
      setState(() => _postSplashScreen = PersonalizationPage(
            onComplete: () {
              setState(() => _postSplashScreen = const HomePage());
            },
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_postSplashScreen != null) {
      return _postSplashScreen!;
    }
    return SplashPage(onComplete: _onSplashComplete);
  }
}
