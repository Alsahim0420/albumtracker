import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/injection.dart';
import 'core/storage/hive_storage.dart';
import 'features/home/presentation/bloc/album_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';

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

class AlbumTrackerApp extends StatefulWidget {
  const AlbumTrackerApp({super.key,});

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

class AlbumTrackerAppState extends State<AlbumTrackerApp> {
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() {
    final team =
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
        title: 'Album Tracker',
        theme: _theme,
        debugShowCheckedModeBanner: false,
        home: HomePage(
          onThemeChanged: updateTheme,
        ),
      ),
    );
  }
}

/// Controla el flujo de entrada: splash → personalización (solo primera vez) o Home.

