import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/theme/team_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/injection.dart';
import 'core/storage/hive_storage.dart';
import 'features/home/presentation/bloc/album_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/personalization/presentation/pages/personalization_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await init();
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

class AlbumTrackerApp extends StatefulWidget {
  const AlbumTrackerApp({super.key});

  @override
  State<AlbumTrackerApp> createState() => AlbumTrackerAppState();
}

class AlbumTrackerAppState extends State<AlbumTrackerApp> {
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() {
    WorldCup2026Seed.getTeamById(storedFavoriteTeam ?? '');
    _theme = TeamTheme.fromTeamId(storedFavoriteTeam);
  }

  void updateTheme(String? teamId) {
    setState(() {
      _theme = TeamTheme.fromTeamId(teamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AlbumBloc>(
      create: (_) => sl<AlbumBloc>(),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: _theme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        home: _AppEntry(onThemeChanged: updateTheme),
      ),
    );
  }
}

/// Controla el flujo de entrada: splash → personalización (solo primera vez) o Home.
class _AppEntry extends StatefulWidget {
  const _AppEntry({required this.onThemeChanged});

  final void Function(String? teamId) onThemeChanged;

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _splashDone = false;

  void _onSplashComplete() {
    setState(() => _splashDone = true);
  }

  void _onPersonalizationComplete() {
    widget.onThemeChanged(storedFavoriteTeam);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashPage(onComplete: _onSplashComplete);
    }
    if (!hasCompletedOnboarding) {
      return PersonalizationPage(
        onComplete: _onPersonalizationComplete,
        onThemeChanged: widget.onThemeChanged,
      );
    }
    return HomePage(onThemeChanged: widget.onThemeChanged);
  }
}

