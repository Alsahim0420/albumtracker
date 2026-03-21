import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';


enum HomeTab { homeTabGroups, homeTabTeams, homeTabSpecials, homeTabMarketplace }

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
            label: 'homeTabGroups'.tr(),
            isSelected: selected == HomeTab.homeTabGroups,
            onTap: () => onChanged?.call(HomeTab.homeTabGroups),
          ),
          const SizedBox(width: 20),
          _TabLabel(
            label: 'homeTabSpecials'.tr(),
            isSelected: selected == HomeTab.homeTabSpecials,
            onTap: () => onChanged?.call(HomeTab.homeTabSpecials),
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
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: isSelected ? 24 : 0,
            decoration: BoxDecoration(
              color: colors.onSurface,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
