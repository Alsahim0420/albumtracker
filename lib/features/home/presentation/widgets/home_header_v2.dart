import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';

/// Cabecera Home rediseñada: título, subtítulo y búsqueda.
class HomeHeaderV2 extends StatelessWidget {
  const HomeHeaderV2({
    super.key,
    this.onSearch,
  });

  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'title'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'homeAlbumCollection'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search, color: AppColors.textPrimary, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}
