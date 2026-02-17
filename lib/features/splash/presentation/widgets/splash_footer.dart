import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Pie de página del splash: edición y versión.
class SplashFooter extends StatelessWidget {
  const SplashFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              AppConstants.edition,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppConstants.versionTagline,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
