import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';

/// Cabecera de Home: título, subtítulo y icono de perfil.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.onProfileTap,
  });

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'appName'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'title'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inputBorder, width: 1),
              ),
              child: Icon(
                Icons.person_outline,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
