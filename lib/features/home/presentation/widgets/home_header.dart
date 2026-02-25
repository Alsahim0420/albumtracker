import 'package:flutter/material.dart';

import 'package:albumtracker/core/constants/app_constants.dart';

/// Cabecera de Home: título, subtítulo y icono de perfil.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.onProfileTap,
  });

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.homeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant, width: 1),
              ),
              child: Icon(
                Icons.person_outline,
                color: colors.onSurface,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
