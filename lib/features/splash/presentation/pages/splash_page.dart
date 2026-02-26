import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/splash_app_icon.dart';
import '../widgets/splash_footer.dart';

/// Pantalla de bienvenida (splash). Muestra logo, título, indicador de carga y pie.
/// Tras [AppConstants.splashDurationMs] navega a la pantalla principal.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.onComplete,
  });

  /// Llamado al finalizar el tiempo de splash (para navegación).
  final VoidCallback? onComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    Future.delayed(
      const Duration(milliseconds: AppConstants.splashDurationMs),
      () => widget.onComplete?.call(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const SplashAppIcon(),
            const SizedBox(height: 24),
            Text(
              'appName'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.progressTrack,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const Spacer(flex: 2),
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: SplashFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
