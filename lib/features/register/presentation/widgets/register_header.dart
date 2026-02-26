import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';

/// Cabecera del registro: logo en rejilla, nombre de la app, título y descripción.
class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LogoGrid(),
            const SizedBox(width: 12),
            Text(
              'registerAppBrand'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'registerTitle'.tr(),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'registerSubtitle'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Logo: cuadrado azul con rejilla de cuadrados blancos (2x4).
class _LogoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _whiteTile(),
              _whiteTile(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _whiteTile(),
              _whiteTile(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _whiteTile(),
              _whiteTile(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _whiteTile(),
              _whiteTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _whiteTile() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
