import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/bloc/album_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/personalization/presentation/pages/personalization_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await EasyLocalization.ensureInitialized();
  runApp(EasyLocalization(
    supportedLocales: const [
      Locale('en'),
      Locale('es'),
    ],
    path: 'assets/lang',
    fallbackLocale: const Locale('en'),
    child: const AlbumTrackerApp(),
  ));
}

class AlbumTrackerApp extends StatelessWidget {
  const AlbumTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AlbumBloc>(
      create: (_) => AlbumBloc(),
      child: MaterialApp(
        title: 'appName'.tr(),
        theme: AppTheme.dark,
        localizationsDelegates: context.localizationDelegates,
        debugShowCheckedModeBanner: false,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const _AppEntry(),
      ),
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
