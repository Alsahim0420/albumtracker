import 'package:flutter/material.dart';

import 'package:albumtracker/core/constants/app_constants.dart';
import 'package:albumtracker/core/theme/app_colors.dart';

enum HomeTab { groups, teams, specials, marketplace }

/// Tabs horizontales: Groups, Teams, Specials, Marketplace.
class HomeTabs extends StatelessWidget {
  const HomeTabs({
    super.key,
    required this.selected,
    this.onChanged,
  });

  final HomeTab selected;
  final ValueChanged<HomeTab>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _TabLabel(
            label: AppConstants.homeTabGroups,
            isSelected: selected == HomeTab.groups,
            onTap: () => onChanged?.call(HomeTab.groups),
          ),
          const SizedBox(width: 20),
          _TabLabel(
            label: AppConstants.homeTabSpecials,
            isSelected: selected == HomeTab.specials,
            onTap: () => onChanged?.call(HomeTab.specials),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: isSelected ? 24 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
